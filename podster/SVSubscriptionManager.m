//
//  SVSubscriptionManager.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSubscriptionManager.h"

#import "SVPodcast.h"
#import "SVPodcastEntry.h"
#import "PodsterManagedDocument.h"
#import "SVDownloadManager.h"
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
static char const kRefreshInterval = -3;

@implementation SVSubscriptionManager {
    BOOL shouldCancel;
    NSDate *startDate; // The date the sync was begun, everything older than that should be synced.
    NSOperationQueue *syncQueue;
    NSArray *subscribedPodcasts;

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

- (NSArray *)subscribedPodcasts
{
    NSManagedObjectContext *context = [PodsterManagedDocument defaultContext];
    NSFetchRequest *request = [SVPodcast MR_requestAllSortedBy:SVPodcastAttributes.title
                                                     ascending:YES
                                                 withPredicate:[NSPredicate predicateWithFormat:@"%K == YES", SVPodcastAttributes.isSubscribed]
                                                     inContext:context];
    [request setReturnsObjectsAsFaults:NO];
    [request setIncludesSubentities:NO];
    __block NSArray *array; 
    [context performBlockAndWait:^{
        NSError *error;
        array = [context executeFetchRequest:request error:&error];
        if (error) {
            DDLogError(@"Error fetching podcasts to refresh: %@", error);
        }
    }];
    return array;
}
- (void)updateFromFirstVersionIfNeccesary:(void (^)(void))complete
{
    NSManagedObjectContext *context = [PodsterManagedDocument defaultContext];
    // Now that we're registered, check for needing an update (from 1.0 to 1.1+
    NSArray *oldPodcasts = [SVPodcast MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"podstoreId == nil "]
                                                    inContext:context];

    if (oldPodcasts.count > 0) {
        dispatch_group_t group = dispatch_group_create();
        LOG_GENERAL(2, @"Updating from v1");
        // We had old (pre changeover) version podcasts in here. Subscribe to the new server with them,and update the items with feed_ids
        for (SVPodcast *podcast in oldPodcasts) {
            dispatch_group_enter(group);
            [podcast updateFromV1:^(BOOL success){
                LOG_GENERAL(2, @"Updating from v1 complete");
                if (!success) {
                    DDLogError(@"Failed to update podcast. Deleting it");
                    [podcast.managedObjectContext performBlock:^{
                        [podcast MR_deleteInContext:podcast.managedObjectContext];
                    }];
                }
                dispatch_group_leave(group);
            }];
        } 
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            dispatch_release(group);
            complete();

        });
    }  else {
        complete();
    }
}
-(void)refreshAllSubscriptions
{
    shouldCancel = NO;
    if (self.isBusy) {
        DDLogWarn(@"Subscription Manager busy. Refresh cancelled");
        return;
        
    }
    self.isBusy = YES;
  
    // First update from the first version if necessary, then go do the actual refresh       
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSMutableArray *array = [[self subscribedPodcasts] mutableCopy];
            dispatch_group_t group = dispatch_group_create();
            DDLogInfo(@"Refreshing subscriptions");          
            for(SVPodcast *podcast in array) {          
                DDLogVerbose(@"Starting update for podcast");
                dispatch_group_enter(group);
                [podcast getNewEpisodes:^(BOOL success) {                    
                    DDLogVerbose(@"Ended update for podcast");
                    dispatch_group_leave(group); 
                }];
            }
                     
            // Wait til we're done getting new epsiodes or until the timeout is hit
            dispatch_group_notify(group, dispatch_get_main_queue(), ^{               
                [[SVDownloadManager sharedInstance] downloadPendingEntries];
                self.isBusy = NO;  
                DDLogInfo(@"Refreshing Subscriptions is complete");
            });                                                        
        });

   
}

- (void)processServerState:(NSArray *)serverState
{
    
}
@end
