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
@implementation SVSubscriptionManager {
    NSArray *subscriptions;
    BOOL isBusy;
}
-(void)refreshAllSubscriptions
{
    subscriptions = [SVSubscription findAll];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    for(SVSubscription *sub in subscriptions) {
       [[SVPodcatcherClient sharedInstance] downloadAndPopulatePodcastWithFeedURL:sub.podcast.feedURL 
                                                                withLowerPriority:YES 
                                                                        inContext:[NSManagedObjectContext defaultContext]
                                                                     onCompletion:^{
                                                                         dispatch_semaphore_signal(semaphore);
                                                                     } 
                                                                          onError:^(NSError *error) {
                                                                              dispatch_semaphore_signal(semaphore);
                                                                          }];
        
        double delayInSeconds = 120.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_semaphore_wait(semaphore, popTime);
    }
}
@end
