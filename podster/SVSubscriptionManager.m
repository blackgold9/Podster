//
//  SVSubscriptionManager.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSubscriptionManager.h"
#import "SVSubscription.h"
#import "SVPodcast.h"
#import "SVPodcastEntry.h"
#import "PodsterManagedDocument.h"
static char const kRefreshInterval = -3;

@implementation SVSubscriptionManager {
    BOOL shouldCancel;
    NSDate *startDate; // The date the sync was begun, everything older than that should be synced.
    NSOperationQueue *syncQueue;

}
@synthesize currentURL = _currentURL;
@synthesize isBusy = _isBusy;
+ (id)sharedInstance
{
    static id sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];

    });
    
    return sharedInstance;
}
-(void)cancel
{
    LOG_GENERAL(2, @"Requesting cancellation");
    if(!self.isBusy) {
        return;
    }
    
    shouldCancel = YES;
}

-(void)refreshNextSubscription
{
    if (shouldCancel) {
        LOG_GENERAL(2, @"Cancelling subscription update");
        return;
    }
    __weak SVSubscriptionManager *weakSelf = self;
         
        
        NSCalendar *gregorian = [[NSCalendar alloc]
                                 initWithCalendarIdentifier:NSGregorianCalendar];
        NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
        
        [offsetComponents setMinute:kRefreshInterval];
        
        NSDate *syncWindow = [gregorian dateByAddingComponents:offsetComponents
                                                        toDate:[NSDate date]
                                                       options:0];
        
        __block SVPodcast *nextPodcast = nil;
        //NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        NSManagedObjectContext *context = [PodsterManagedDocument defaultContext];
        // Get the root context to work against

        NSPredicate *subscribedPredicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES"];
        LOG_GENERAL(2, @"About to look for a subscription to refresh");
        [context performBlock:^{
            NSPredicate *olderThanSyncStart = [NSPredicate predicateWithFormat:@"%K <= %@ OR %K == nil", SVPodcastAttributes.lastSynced, startDate,SVPodcastAttributes.lastSynced];       
            NSPredicate *stale = [NSPredicate predicateWithFormat:@"%K < %@ OR %K == nil",SVPodcastAttributes.lastSynced, syncWindow, SVPodcastAttributes.lastSynced];
            
            NSPredicate *itemToRefresh = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:subscribedPredicate, olderThanSyncStart,stale, nil]];
            
            nextPodcast = [SVPodcast MR_findFirstWithPredicate:itemToRefresh sortedBy:SVPodcastAttributes.lastSynced ascending:NO inContext:context];
            
            LOG_NETWORK(2, @"Finding subscription that needs refreshing");
            if (nextPodcast && !shouldCancel) {
                if (!self.isBusy) {
                    self.isBusy = YES;
                }
                weakSelf.currentURL = nextPodcast.feedURL;
                nextPodcast.lastSynced = [NSDate date];
                [context save:nil];
                LOG_NETWORK(2, @"Found One: Updating feed: %@ - %@", nextPodcast.title, nextPodcast.objectID);
                [[SVPodcatcherClient sharedInstance] downloadAndPopulatePodcast:nextPodcast
                                                                         withLowerPriority:YES
                                                                                 inContext:context 
                                                                              onCompletion:^{
                                                                                  [context performBlock:^{                                                                                      
                                                                                      [nextPodcast updateNextItemDateAndDownloadIfNeccesary:YES];
                                                                                      [context save:nil ];

                                                                                  }];
                                                                                  weakSelf.currentURL = nil;

                                                                                  if(weakSelf->shouldCancel) {
                                                                                      LOG_PARSING(2, @"Cancelling");
                                                                                  } else {
                                                                                      [weakSelf refreshNextSubscription];
                                                                                  }                                                                                  
                                                                              } onError:^(NSError *error) {
                                                                                     if(!weakSelf->shouldCancel) {                                                                                       
                                                                                         [self refreshNextSubscription];
                                                                                     }
                                                                                     weakSelf.currentURL = nil;
                                                                                 }];
            } else {
                if (self.isBusy) {
                    self.isBusy = NO;            
                }
                [context performBlock:^{
                    [context save:nil];
                }];
                LOG_NETWORK(2, @"Updating subscriptions complete");
            }
            
        }];
}
-(void)refreshAllSubscriptions
{
    shouldCancel = NO;
    if (self.isBusy) {
        LOG_NETWORK(3, @"Subscription Manager busy. Refresh cancelled");
        return;
        
    }
    LOG_NETWORK(2, @"Refreshing subscriptions");
    startDate = [NSDate date];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [self refreshNextSubscription];        
    });

}

- (void)processServerState:(NSDictionary *)serverState
{
    [[PodsterManagedDocument sharedInstance] performWhenReady:^{
        
        
        [[PodsterManagedDocument defaultContext] performBlock:^{
            LOG_GENERAL(2, @"Server State: %@", serverState);
            NSPredicate *subscribedPredicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES"];
            NSPredicate *matchesServerPredicate = [NSPredicate predicateWithFormat:@"feedURL IN %@", [serverState allKeys]];
//            NSArray *podcasts = [SVPodcast MR_findAllWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:subscribedPredicate,matchesServerPredicate, nil]] inContext:[PodsterManagedDocument defaultContext]];
//            
            NSPredicate *missingFromServer = [NSPredicate predicateWithFormat:@"NOT (feedURL in %@)", [serverState allKeys]];
            NSArray *needsReconciling = [SVPodcast MR_findAllWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:missingFromServer, subscribedPredicate, nil]] inContext:[PodsterManagedDocument defaultContext]];
            for(SVPodcast *podcast in needsReconciling) {
                [[SVPodcatcherClient sharedInstance] notifyOfSubscriptionToFeed:podcast.feedURL                                                                                                                           onCompletion:^{
                    [[PodsterManagedDocument defaultContext] performBlock:^{
                        podcast.isSubscribedValue = YES;
                    }];
                    
                }
                                                                        onError:nil];
            }
            
            // Now, delete items on the server that we're no-longer subscribed to
            for(NSString *url in [serverState allKeys]) {
                if ([SVPodcast MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"feedURL == %@ && isSubscribed == YES", url] inContext:[PodsterManagedDocument defaultContext]] == 0) {
                    // We arent subscribed to this anymore, tell the server
                    [[SVPodcatcherClient sharedInstance] notifyOfUnsubscriptionFromFeed:url
                                                                           onCompletion:^{
                                                                               LOG_GENERAL(2, @"Removing podcast subscription from server that we unsusbscribed from locally");
                                                                               
                                                                           }
                                                                                onError:nil];
                }
            }     
        }];
    }];
    
}
@end
