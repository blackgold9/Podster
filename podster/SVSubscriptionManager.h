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
@property (strong) NSString *currentURL;
-(void)refreshAllSubscriptions;
+ (id)sharedInstance;

// When registering with the server,  recive a dictionary of feed_urls and notification statuses
// The plan here is to update the notification status enforced from the server
// For the cases where they fall OUT of premium status
// and to register new feeds the server missed (somehow out of sync)
- (void)processServerState:(NSDictionary *)serverState;

- (void)cancel;
@end
