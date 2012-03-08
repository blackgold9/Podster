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
+ (id)sharedInstance;

// When registering with the server,  we recieve an array of dictionaries back
// The format is { feed_url_hash : notifications_enabled_bool }
// The plan here is to update the notification status enforced from the server
// For the cases where they fall OUT of premium status
// and to register new feeds the server missed (somehow out of sync)
- (void)processServerState:(NSArray *)subscriptions;
@end
