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

static char const kRefreshInterval = -3;

@implementation SVSubscriptionManager {
    NSArray *subscriptions;
    BOOL shouldCancel;
    NSDate *startDate; // The date the sync was begun, everything older than that should be synced.
}
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
    if(!self.isBusy) {
        return;
    }
    
    shouldCancel = YES;
}
- (void)updateLastUpdatedForPodcast:(SVPodcast *)podcast 
                          inContext:(NSManagedObjectContext *)context
{

    [context performBlock:^{
        

     SVPodcastEntry *lastUnplayedEntry = [SVPodcastEntry findFirstWithPredicate:[NSPredicate predicateWithFormat:@"podcast == %@ AND played == NO", podcast]
                                   sortedBy:SVPodcastEntryAttributes.datePublished ascending:NO inContext:context];
        podcast.lastUpdated = lastUnplayedEntry.datePublished;
    }];
}
-(void)refreshNextSubscription
{

    NSCalendar *gregorian = [[NSCalendar alloc]
                             initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];

    [offsetComponents setMinute:kRefreshInterval];

    NSDate *syncWindow = [gregorian dateByAddingComponents:offsetComponents
                                                    toDate:[NSDate date]
                                                   options:0];

    __block SVPodcast *nextPodcast = nil;
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];

    // Get the root(Background )context to work against
    context.parentContext = [[NSManagedObjectContext defaultContext] parentContext];
    LOG_GENERAL(2, @"About to look for a subscription to refresh");
    [context performBlock:^{
            subscriptions =  [SVSubscription findAllInContext:context];
        NSPredicate *olderThanSyncStart = [NSPredicate predicateWithFormat:@"%K <= %@ OR %K == nil", SVPodcastAttributes.lastSynced, startDate,SVPodcastAttributes.lastSynced];
        NSPredicate *subscribed = [NSPredicate predicateWithFormat:@"%K in %@", SVPodcastRelationships.subscription, subscriptions];
        NSPredicate *stale = [NSPredicate predicateWithFormat:@"%K < %@ OR %K == nil",SVPodcastAttributes.lastSynced, syncWindow, SVPodcastAttributes.lastSynced];
        
        NSPredicate *itemToRefresh = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:subscribed, olderThanSyncStart,stale, nil]];
        
        nextPodcast = [SVPodcast findFirstWithPredicate:itemToRefresh sortedBy:SVPodcastAttributes.lastSynced ascending:NO inContext:context];
        
        LOG_NETWORK(2, @"Finding subscription that needs refreshing");
        if (nextPodcast && !shouldCancel) {
            if (!self.isBusy) {
                self.isBusy = YES;
            }
            [FlurryAnalytics logEvent:@"UpdatingSubscriptions" timed:YES];
            nextPodcast.lastSynced = [NSDate date];
            [context save];
            LOG_NETWORK(2, @"Found One!: Updating feed: %@", nextPodcast.title);
            [[SVPodcatcherClient sharedInstance] downloadAndPopulatePodcastWithFeedURL:nextPodcast.feedURL
                                                                     withLowerPriority:YES
                                                                             inContext:context onCompletion:^{
                                                                                 [self updateLastUpdatedForPodcast:nextPodcast
                                                                                                         inContext:context];
                                                                                 [self refreshNextSubscription];

                                                                                                                                                                  
                                                                             } onError:^(NSError *error) {
                                                                                 [self refreshNextSubscription];
                                                                                 
                                                                             }];
        } else {
            [FlurryAnalytics endTimedEvent:@"UpdatingSubscriptions" 
                            withParameters:nil];
            if (self.isBusy) {
                self.isBusy = NO;            
            }
            [context performBlock:^{
                [context save];
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
@end
