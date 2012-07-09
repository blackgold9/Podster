//
// Created by j-stevan@interactive.msnbc.com on 7/5/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "PodcastUpdateOperation.h"
#import "SVPodcastEntry.h"
#import "SVPodcast.h"
#import "_SVPodcastEntry.h"

static int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation PodcastUpdateOperation {
    NSManagedObjectContext *parentContext;
    BOOL success;
}
@synthesize podcastId = _podcastId;
@synthesize onUpdateComplete = _onUpdateComplete;


- (id)initWithPodcastId:(NSNumber *)podcastId andContext:(NSManagedObjectContext *)theContext {
    if (!podcastId) {
        [NSException raise:NSInvalidArgumentException format:@"The argument \"podcastId\" can not be nil"];
    }

    if (!theContext) {
        [NSException raise:NSInvalidArgumentException format:@"The argument \"theContext\" can not be nil"];
    }

    self = [super init];
    if (self) {
        self.podcastId = podcastId;
        parentContext = theContext;
        success = NO;
    }

    return  self;
}

- (BOOL)completedSuccessfully {
    return success;
}

- (void)main {
    DDLogVerbose(@"Starting sync for Podcast with Id: %@", self.podcastId);
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = parentContext;

    __block NSDate *lastEntryDate = [NSDate distantPast];
    __block BOOL podcastExists;
    __block NSString *title;
    [childContext performBlockAndWait:^void() {
        [childContext processPendingChanges];
        SVPodcast *podcast = [SVPodcast MR_findFirstByAttribute:@"podstoreId" withValue:self.podcastId inContext:childContext];
        if (podcast) {
            podcastExists = YES;

            SVPodcastEntry *lastEntry = [[podcast.items sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:SVPodcastEntryAttributes.datePublished ascending:YES]]] lastObject];
            lastEntryDate = lastEntry.datePublished;
            title = lastEntry.title;
        } else {
            podcastExists = NO;
        }
    }];

    if (podcastExists) {
        DDLogVerbose(@"Podcast with id %@ was found in the database", self.podcastId);
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        DDLogVerbose(@"Fetchinng new episodes for %@ after %@", title, lastEntryDate);
        __weak PodcastUpdateOperation *weakSelf = self;
        [[SVPodcatcherClient sharedInstance] getNewItemsForFeedWithId:self.podcastId
                                                     withLastSyncDate:lastEntryDate
                                                             complete:^void(id response) {
                                                                 weakSelf->success = YES;
                                                                 [self processResponse:response inContext:childContext signallingSemaphore:semaphore];
                                                             }
                                                              onError:^void(NSError *error) {
                                                                  DDLogError(@"There was an error communicating with the server attempting to sync podcast with Id: %@", self.podcastId);
                                                                  [FlurryAnalytics logError:@"PodcastUpdateFailed" message:[error localizedDescription] error:error];
                                                                  dispatch_semaphore_signal(semaphore);
                                                              }];

        long result = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
        if (result > 0) {
            DDLogWarn(@"A timeout occured while trying to update podcast");
        }
    } else {
        DDLogWarn(@"Podcast with id: %@ did not exist", self.podcastId);
    }

    NSError *saveError;
    DDLogVerbose(@"Saving Child Context");
    [childContext save:&saveError];
    NSAssert(saveError == nil, @"There should be no error when saving", saveError);
    DDLogVerbose(@"Podcast update operation complete for id: %@", self.podcastId);
    if (self.onUpdateComplete) {
        self.onUpdateComplete(self);
    }
}

- (void)processResponse:(id)response inContext:(NSManagedObjectContext *)context signallingSemaphore:(dispatch_semaphore_t)semaphore {
    [context performBlock:^void() {
        SVPodcast *localPodcast = [SVPodcast MR_findFirstByAttribute:@"podstoreId" withValue:self.podcastId inContext:context];
        localPodcast.lastSynced = [NSDate date];
        NSArray *episodes = response;
        if (episodes) {
            DDLogInfo( @"Added %d episodes to %@", episodes.count, localPodcast.title);
        }

        BOOL isFirst = YES;
        NSDate *lastDate = nil;
        for (NSDictionary *episode in episodes) {

            // Completely new item, create it,add it, be happy
            SVPodcastEntry *localEntry = [SVPodcastEntry MR_createInContext:context];

            [localEntry populateWithDictionary:episode];
            if (isFirst) {
                DDLogVerbose(@"Latest received item date %@", localEntry.datePublished);
                isFirst = NO;
            }

            lastDate = localEntry.datePublished;
            [localPodcast addItemsObject:localEntry];
        }

        DDLogVerbose(@"Oldest recieved item date %@", lastDate);

        [self updateNewEpisodeCountForPodcast:localPodcast];

        NSError *error;
        [context save:&error];

        NSAssert(error == nil, @"There should be no error. Got %@", error);

        if (error) {
            DDLogError(@"There was a problem updating this podcast %@ - %@", localPodcast, error);
            [FlurryAnalytics logError:@"SavingPodcastFailed" message:[error localizedDescription] error:error];
        } else {
            DDLogVerbose(@"Updating podcast with id %@ succeeded", self.podcastId);
        }

        dispatch_semaphore_signal(semaphore);
    }];
}


- (void)updateNewEpisodeCountForPodcast:(SVPodcast *)podcast
{

    @try {
        NSUInteger newCount = 0;
        NSAssert(podcast.isSubscribed, @"IsSubscribed should have a value");
        NSNumber *subscribedNumber= [podcast isSubscribed];
        BOOL subscribed = [subscribedNumber boolValue];

        if (subscribed) {
            if (podcast.subscribedDate == nil) {
                podcast.subscribedDate = [NSDate date];
            }
            newCount = [SVPodcastEntry MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"%K == %@ && %K > %@ && %K == false && %K == 0", SVPodcastEntryRelationships.podcast, podcast, SVPodcastEntryAttributes.datePublished, podcast.subscribedDate, SVPodcastEntryAttributes.played, SVPodcastEntryAttributes.positionInSeconds] inContext:podcast.managedObjectContext];
        }
        if (podcast.unlistenedSinceSubscribedCountValue != newCount) {
            podcast.unlistenedSinceSubscribedCountValue = newCount;
        }
    }
    @catch (NSException *exception) {
        DDLogError(@"EXCEPTION: %@", exception);
    }
    @finally {

    }

}

@end