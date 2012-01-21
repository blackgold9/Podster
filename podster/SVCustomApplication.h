//
//  SVCustomApplication.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVCustomApplication : UIApplication
- (void)startListeningForRemoteEvents;
- (void)stopListeningForRemoteEvents;
@end
