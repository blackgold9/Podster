//
//  SVSubscriptionManager.h
//  podster
//
//  Created by Vanterpool, Stephen on 2/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const kPodcastHasBeenUpdated = @"PodcastHasBeenUpdated";

@interface SVSubscriptionManager : NSObject
@property (assign) BOOL isBusy;
-(void)refreshAllSubscriptions;

- (void)refreshPodcastsWithIds:(NSArray *)podsterIDs complete:(void (^)())complete onQueue:(dispatch_queue_t)queue;

+ (id)sharedInstance;

@end
