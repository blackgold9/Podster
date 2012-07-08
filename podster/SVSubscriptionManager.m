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
#import "PodcastUpdateOperation.h"
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

- (id)init {
    self = [super init];
    if (self) {
        syncQueue = [[NSOperationQueue alloc] init];
        syncQueue.maxConcurrentOperationCount = 8;
        syncQueue.name = @"net.vanterpool.podster.podcastUpdate";
    }

    return self;
}

- (NSArray *)subscribedPodcastsInContext:(NSManagedObjectContext *)context
{
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

-(void)refreshAllSubscriptions
{
    shouldCancel = NO;
    if (self.isBusy) {
        DDLogWarn(@"Subscription Manager busy. Refresh cancelled");
        return;

    }
    self.isBusy = YES;

    NSManagedObjectContext *context = [PodsterManagedDocument defaultContext];
    __block NSMutableArray *subscribedPodsterIds = [NSMutableArray array];

    // Get the subscribed podcast podster ids
    [context performBlockAndWait:^void() {
        NSArray *subscribed = [self subscribedPodcastsInContext:context];
        for (SVPodcast *podcast in subscribed) {
            [subscribedPodsterIds addObject:podcast.podstoreId];
        }
    }];

    // Actually do the update
    [self refreshPodcastsWithIds:subscribedPodsterIds
                        complete:^void() {
                            // Save context
                            [context performBlockAndWait:^void() {
                                NSError *error;
                                [context save:&error];
                                if (error) {
                                    DDLogError(@"An error occured saving after refreshing podcasts. Error:%@", error);
                                    [FlurryAnalytics logError:@"SubscriptionRefreshError" message:[error localizedDescription] error:error];
                                    NSAssert(NO, @"This should not fail");
                                }
                            }];

                            [[SVDownloadManager sharedInstance] downloadPendingEntries];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.isBusy = NO;
                                DDLogInfo(@"Refreshing Subscriptions is complete");
                            });
                        }
            onQueue:dispatch_get_main_queue()];

}

- (void)refreshPodcastsWithIds:(NSArray *)podsterIDs complete:(void (^)())complete onQueue:(dispatch_queue_t)queue
{
    dispatch_retain(queue);
    dispatch_group_t group = dispatch_group_create();
    NSArray *currentIds= [syncQueue.operations valueForKey:@"podcastId"];
    NSSet *currentOperationLookup = [NSSet setWithArray:currentIds];
    NSManagedObjectContext *context = [PodsterManagedDocument defaultContext];
    for (NSNumber *podsterId in podsterIDs) {
        if (![currentOperationLookup containsObject:podsterId]) {
            dispatch_group_enter(group);
            PodcastUpdateOperation *operation = [[PodcastUpdateOperation alloc] initWithPodcastId:podsterId
                                                                                       andContext:context];
            [operation setCompletionBlock:^void() {
                dispatch_group_leave(group);
            }];
            [syncQueue addOperation:operation];

        } else {
            DDLogWarn(@"Skipping updating podcast with id %@ since it was already in the queue", podsterId);
        }
    }

    if (queue && complete) {
        dispatch_group_notify(group, queue, ^void() {
            complete();
            dispatch_release(group);
            dispatch_release(queue);
        });
    } 

}

@end
