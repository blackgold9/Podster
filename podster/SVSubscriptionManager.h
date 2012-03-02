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
@end
