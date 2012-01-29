//
//  SVVideoPlaybackView.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVVideoPlaybackView.h"
#import <AVFoundation/AVFoundation.h>
@implementation SVVideoPlaybackView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}
- (AVPlayer*)player {
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer *)player {
    [(AVPlayerLayer *)[self layer] setPlayer:player];
}
@end
