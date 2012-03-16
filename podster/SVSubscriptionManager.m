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
        podcast.nextItemDate = lastUnplayedEntry.datePublished;
    }];
}
-(void)refreshNextSubscription
{

    [[PodsterManagedDocument sharedInstance] performWhenReady: ^{
        
        
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
        context.parentContext = [NSManagedObjectContext defaultContext];
        NSPredicate *subscribedPredicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES"];
        LOG_GENERAL(2, @"About to look for a subscription to refresh");
        [context performBlock:^{
            NSPredicate *olderThanSyncStart = [NSPredicate predicateWithFormat:@"%K <= %@ OR %K == nil", SVPodcastAttributes.lastSynced, startDate,SVPodcastAttributes.lastSynced];       
            NSPredicate *stale = [NSPredicate predicateWithFormat:@"%K < %@ OR %K == nil",SVPodcastAttributes.lastSynced, syncWindow, SVPodcastAttributes.lastSynced];
            
            NSPredicate *itemToRefresh = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:subscribedPredicate, olderThanSyncStart,stale, nil]];
            
            nextPodcast = [SVPodcast findFirstWithPredicate:itemToRefresh sortedBy:SVPodcastAttributes.lastSynced ascending:NO inContext:context];
            
            LOG_NETWORK(2, @"Finding subscription that needs refreshing");
            if (nextPodcast && !shouldCancel) {
                if (!self.isBusy) {
                    self.isBusy = YES;
                }
                [FlurryAnalytics logEvent:@"UpdatingSubscriptions" timed:YES];
                nextPodcast.lastSynced = [NSDate date];
                [context save:nil];
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
                    [context save:nil];
                }];
                LOG_NETWORK(2, @"Updating subscriptions complete");
            }
            
        }];
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

- (void)processServerState:(NSDictionary *)serverState isPremium:(BOOL)isPremium
{
    [[NSManagedObjectContext defaultContext] performBlock:^{
        LOG_GENERAL(2, @"Server State: %@", serverState);
        NSPredicate *subscribedPredicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES"];
        NSPredicate *matchesServerPredicate = [NSPredicate predicateWithFormat:@"feedURL IN %@", [serverState allKeys]];
        NSArray *podcasts = [SVPodcast findAllWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:subscribedPredicate,matchesServerPredicate, nil]]];
        
        if(!isPremium) {
            // Only do this if we're not premium anymore. It's the only time this can get out of sync
            for(SVPodcast *podcast in podcasts) {
              
                BOOL serverNotify = [[serverState objectForKey:podcast.feedURL] boolValue];
                
                LOG_GENERAL(1, @"Setting podcast notify value to match server value");
                // Only do this if the user hasn't made a change. 
                // When they have, we'll attempt to make their change later
                if (podcast.shouldNotifyValue != serverNotify) {
                    podcast.shouldNotifyValue = serverNotify;
                }
            }
        } 
        NSPredicate *missingFromServer = [NSPredicate predicateWithFormat:@"NOT (feedURL in %@)", [serverState allKeys]];
        NSArray *needsReconciling = [SVPodcast findAllWithPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:missingFromServer, subscribedPredicate, nil]]];
        for(SVPodcast *podcast in needsReconciling) {
            [[SVPodcatcherClient sharedInstance] notifyOfSubscriptionToFeed:podcast.feedURL                                                                                                                           onCompletion:^{
                [[NSManagedObjectContext defaultContext] performBlock:^{
                    podcast.isSubscribedValue = YES;
                }];
                
            }
                                                                    onError:nil];
        }
        
        // Now, delete items on the server that we're no-longer subscribed to
        for(NSString *url in [serverState allKeys]) {
            if ([SVPodcast countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"feedURL == %@ && isSubscribed == YES", url]] == 0) {
                // We arent subscribed to this anyumore, tell the server
                [[SVPodcatcherClient sharedInstance] notifyOfUnsubscriptionFromFeed:url
                                                                       onCompletion:^{
                                                                           LOG_GENERAL(2, @"Removing podcast subscription from server that we unsusbscribed from locally");
                                                                           
                                                                       }
                                                                            onError:nil];
            }
         }     
    }];
    
}
@end
