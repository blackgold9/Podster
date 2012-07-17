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
@synthesize podcast = _podcast;
@synthesize onUpdateComplete = _onUpdateComplete;


- (id)initWithPodcast:(SVPodcast *)podcast andContext:(NSManagedObjectContext *)theContext {
    if (!podcast) {
        [NSException raise:NSInvalidArgumentException format:@"The argument \"podcastId\" can not be nil"];
    }
    
    if (!theContext) {
        [NSException raise:NSInvalidArgumentException format:@"The argument \"theContext\" can not be nil"];
    }
    
    NSAssert(podcast.managedObjectContext == theContext, @"The contexts should be the same");
    self = [super init];
    if (self) {
        self.podcast = podcast;
        parentContext = theContext;
        success = NO;
    }
    
    return  self;
}

- (BOOL)completedSuccessfully {
    return success;
}

- (void)cancel {
    [super cancel];
    
}

- (void)main {
    NSManagedObjectContext *childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    childContext.parentContext = parentContext;
    
    
    __block NSDate *lastEntryDate = [NSDate distantPast];
    __block BOOL podcastExists;
    __block NSString *title;
    __block NSNumber *podcastId;
    [childContext performBlockAndWait:^void() {
        NSFetchRequest *request = [SVPodcast MR_requestFirstWithPredicate:[NSPredicate predicateWithFormat:@"self == %@", self.podcast]];
        request.relationshipKeyPathsForPrefetching = [NSArray arrayWithObject:SVPodcastRelationships.items];
        SVPodcast *podcast = [[childContext executeFetchRequest:request error:nil] lastObject];
        
        podcastId = podcast.podstoreId;
        DDLogVerbose(@"Starting sync for Podcast with Id: %@", podcast.podstoreId);
        if (podcast) {
            podcastExists = YES;
            title = podcast.title;
            SVPodcastEntry *lastEntry = [[podcast.items sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:SVPodcastEntryAttributes.datePublished ascending:YES]]] lastObject];
            lastEntryDate = lastEntry.datePublished;           
        } else {
            podcastExists = NO;
        }
    }];
    
    
    if (podcastExists) {
        DDLogVerbose(@"Podcast was found in the database");
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        dispatch_retain(semaphore);
        DDLogVerbose(@"Fetchinng new episodes for %@ after %@", title, lastEntryDate);
        __weak PodcastUpdateOperation *weakSelf = self;
        [[SVPodcatcherClient sharedInstance] getNewItemsForFeedWithId:podcastId
                                                     withLastSyncDate:lastEntryDate
                                                             complete:^void(id response) {
                                                                 __strong PodcastUpdateOperation *operation = weakSelf;
                                                                 if (operation.isCancelled) {
                                                                     return;
                                                                 }
                                                                 
                                                                 if (operation) {
                                                                     operation->success = YES;
                                                                 }
                                                                 [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
                                                                     [self processResponse:response
                                                                                 inContext:childContext
                                                                       signallingSemaphore:semaphore];
                                                                     
                                                                 }];
                                                             }
                                                              onError:^void(NSError *error) {
                                                                  DDLogError(@"There was an error communicating with the server attempting to sync podcast with Id: %@", podcastId);
                                                                  [FlurryAnalytics logError:@"PodcastUpdateFailed" message:[error localizedDescription] error:error];
                                                                  dispatch_semaphore_signal(semaphore);
                                                              }];
        
        long result = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC));
        dispatch_release(semaphore);
        if (result > 0) {
            DDLogWarn(@"A timeout occured while trying to update podcast");
        }
    } else {
        DDLogWarn(@"Podcast with id: %@ did not exist", podcastId);
    }
    
    [childContext performBlock:^{
        
        
        NSError *saveError;
        DDLogVerbose(@"Saving Child Context");
        [childContext save:&saveError];
        NSAssert(saveError == nil, @"There should be no error when saving: %@", saveError);
        DDLogVerbose(@"Podcast update operation complete for id: %@", podcastId);
        if (self.onUpdateComplete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                
                self.onUpdateComplete(self);
            });
        }
    }];
}

- (void)processResponse:(id)response
              inContext:(NSManagedObjectContext *)context
    signallingSemaphore:(dispatch_semaphore_t)semaphore {
    DDLogVerbose(@"Procesing response");


    [context performBlock:^void() {
        @try {

            NSAssert([NSThread currentThread] != [NSThread mainThread], @"should not be on the main thread here");
            SVPodcast *localPodcast = [self.podcast MR_inContext:context];
            NSAssert(localPodcast!= nil, @"Should not be nil");
            localPodcast.lastSynced = [NSDate date];
            NSArray *episodes = response;
            if (episodes) {
                DDLogInfo( @"Added %d episodes to %@", episodes.count, localPodcast.title);
            }
            
            BOOL isFirst = YES;
            NSDate *lastDate = nil;
            NSInteger current = 0;
            NSError *error;
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
                current ++;
            }
            
              
            NSAssert(error == nil, @"There should be no error. Got %@", error);
            
            if (error) {
                DDLogError(@"There was a problem updating this podcast %@ - %@", localPodcast, error);
                [FlurryAnalytics logError:@"SavingPodcastFailed" message:[error localizedDescription] error:error];
            } else {
                DDLogVerbose(@"Updating podcast succeeded");
            }
            

            DDLogVerbose(@"Oldest recieved item date %@", lastDate);
            
            [self updateNewEpisodeCountForPodcast:localPodcast];
            
                   }
        @catch (NSException *exception) {
            DDLogError(@"Exception occured during podcast udpate operation: %@", exception);
        }
        @finally {
            dispatch_semaphore_signal(semaphore);
            dispatch_release(semaphore);
        }
        
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