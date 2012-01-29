//
//  SVVideoPlaybackView.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface SVVideoPlaybackView : UIView
@property (nonatomic, retain) AVPlayer *player;
@end