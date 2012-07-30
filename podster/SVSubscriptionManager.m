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
#import "SVDownloadManager.h"
#import "PodcastUpdateOperation.h"
static const int ddLogLevel = LOG_LEVEL_INFO;
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
        syncQueue.maxConcurrentOperationCount = 2;
        syncQueue.name = @"net.vanterpool.podster.podcastUpdate";
    }

    return self;
}

-(void)refreshAllSubscriptions
{
    shouldCancel = NO;
    if (self.isBusy) {
        DDLogWarn(@"Subscription Manager busy. Refresh cancelled");
        return;

    }
    self.isBusy = YES;

    [[NSManagedObjectContext MR_defaultContext] MR_saveNestedContexts];
    NSArray *podcasts = [SVPodcast MR_findByAttribute:SVPodcastAttributes.isSubscribed withValue:[NSNumber numberWithBool:YES]];


    // Actually do the update
    [self refreshPodcasts:podcasts
                 complete:^void() {
                     [[NSManagedObjectContext MR_defaultContext] MR_saveNestedContexts];
                     dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                         [[SVDownloadManager sharedInstance] downloadPendingEntries];
                     });

                     dispatch_async(dispatch_get_main_queue(), ^{
                         self.isBusy = NO;
                         DDLogInfo(@"Refreshing Subscriptions is complete");
                     });
                 }
                  onQueue:dispatch_get_main_queue()];
    
}

- (void)refreshPodcasts:(NSArray *)podcasts complete:(void (^)())complete onQueue:(dispatch_queue_t)queue
{
    dispatch_retain(queue);
    dispatch_group_t group = dispatch_group_create();
    NSArray *currentIds= [syncQueue.operations valueForKey:@"podcast"];
    NSSet *currentOperationLookup = [NSSet setWithArray:currentIds];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    for (SVPodcast *podcast in podcasts) {
        if (![currentOperationLookup containsObject:podcast]) {
            dispatch_group_enter(group);
            PodcastUpdateOperation *operation = [[PodcastUpdateOperation alloc] initWithPodcast:podcast
                                                                                     andContext:context];
            [operation setCompletionBlock:^void() {
                dispatch_group_leave(group);
            }];
            [syncQueue addOperation:operation];

        } else {
            DDLogWarn(@"Skipping updating podcast since it was already in the queue");
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
