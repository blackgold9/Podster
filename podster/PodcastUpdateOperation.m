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
@interface PodcastUpdateOperation ()

@end

@implementation PodcastUpdateOperation {

    BOOL success;
    BOOL executing;
    BOOL _isExecuting;
    BOOL _isFinished;
}

@synthesize onUpdateComplete = _onUpdateComplete;
@synthesize podstoreId;

#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
          }
    return self;
}


#pragma mark - NSOperation

- (BOOL)isConcurrent {
    return YES;
}


- (BOOL)isExecuting {
    return _isExecuting;
}


- (BOOL)isFinished {
    return _isFinished;
}



- (void)finish {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    _isExecuting = NO;
    _isFinished = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}





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
        _isExecuting = NO;
        _isFinished = NO;

        self.podstoreId =  podcast.podstoreId;
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

- (void)start
{
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = YES;
    [self didChangeValueForKey:@"isExecuting"];
    __block NSDate *lastEntryDate = [NSDate distantPast];
    __block BOOL podcastExists;
    __block NSString *title;
    [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *childContext) {
        SVPodcast *podcast = [SVPodcast MR_findFirstByAttribute:SVPodcastAttributes.podstoreId withValue:self.podstoreId inContext:childContext];
        DDLogVerbose(@"Starting sync for Podcast with Id: %@ - %@", podcast.podstoreId, podcast.objectID);
        if (podcast) {
            podcastExists = YES;
            title = podcast.title;
            lastEntryDate = podcast.lastUpdated;
            if (lastEntryDate == nil) {
                NSFetchRequest *request = [SVPodcastEntry MR_requestAllWithPredicate:[NSPredicate predicateWithFormat:@"podcast.podstoreId == %@", podcast.podstoreId] inContext:childContext];
                [request setResultType:NSDictionaryResultType];
                NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:SVPodcastEntryAttributes.datePublished];
                NSExpression *minExpression = [NSExpression expressionForFunction:@"max:" arguments:  [NSArray arrayWithObject:keyPathExpression]];
                NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
                [expressionDescription setName:@"maxDatePublished"];
                [expressionDescription setExpression:minExpression];
                [expressionDescription setExpressionResultType:NSDateAttributeType];
                [request setPropertiesToFetch:[NSArray arrayWithObject:expressionDescription]];
                NSDictionary *results = [[childContext executeFetchRequest:request error:nil] lastObject];
                if (results != nil) {
                    lastEntryDate = [results valueForKey:@"maxDatePublished"];
                }
            }
        } else {
            podcastExists = NO;
        }
        
        if (podcastExists) {
            DDLogVerbose(@"Podcast was found in the database");
            dispatch_group_t group = dispatch_group_create();
            DDLogVerbose(@"Fetchinng new episodes for %@ after %@", title, lastEntryDate);
            __weak PodcastUpdateOperation *weakSelf = self;
            dispatch_group_enter(group);
            [[SVPodcatcherClient sharedInstance] getNewItemsForFeedWithId:self.podstoreId
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
                                                                                     inContext:localContext];
                                                                     } completion:^{
                                                                          dispatch_group_leave(group);
                                                                     }];                                                                                                                                                                                                             
                                                                 }
                                                                  onError:^void(NSError *error) {
                                                                      DDLogError(@"There was an error communicating with the server attempting to sync podcast with Id: %@", self.podstoreId);
                                                                      [Flurry logError:@"PodcastUpdateFailed" message:[error localizedDescription] error:error];
                                                                      dispatch_group_leave(group);
                                                                  }];
            dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"SVPodcastUpdated" object:self userInfo:@{@"identifier": podstoreId}];
                [self finish];
                
                if (self.onUpdateComplete) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.onUpdateComplete(self);
                    });
                } 
            });
        } else {
            DDLogWarn(@"Podcast with id: %@ did not exist, aborting", self.podstoreId);
            [self finish];
        }
        
    }];
}


- (void)processResponse:(id)response
              inContext:(NSManagedObjectContext *)context {
    DDLogVerbose(@"Procesing response");
        SVPodcast *localPodcast = [SVPodcast MR_findFirstByAttribute:SVPodcastAttributes.podstoreId withValue:self.podstoreId inContext:context];
        DDLogVerbose(@"PRocessing new episodes for podcast with core data identifier: %@", localPodcast.objectID);
        NSAssert(localPodcast!= nil, @"Should not be nil");
        localPodcast.lastSynced = [NSDate date];
        NSArray *episodes = response;
        if (episodes) {
            DDLogInfo( @"Adding %d episodes to %@ - %@", episodes.count, localPodcast.title, localPodcast.objectID);
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
                localPodcast.lastUpdated = localEntry.datePublished;
            }
            
            lastDate = localEntry.datePublished;
            [localPodcast addItemsObject:localEntry];
            current ++;
        }
        
        
        NSAssert(error == nil, @"There should be no error. Got %@", error);
        
        if (error) {
            DDLogError(@"There was a problem updating this podcast %@ - %@", localPodcast, error);
            [Flurry logError:@"SavingPodcastFailed" message:[error localizedDescription] error:error];
        } else {
            DDLogVerbose(@"Updating podcast succeeded");
        }
        
        
        DDLogVerbose(@"Oldest recieved item date %@", lastDate);
        
        [self updateNewEpisodeCountForPodcast:localPodcast];

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
