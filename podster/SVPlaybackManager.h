//
//  SVPlaybackManager.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SVPodcast.h"
#import "SVPodcastEntry.h"
typedef enum {
    kPlaybackStatePaused,
    kPlaybackStateBuffering,
    kPlaybackStatePlaying,
    kPlaybackStateStopped
} PlaybackState;
@interface SVPlaybackManager : UIResponder<AVAudioSessionDelegate>
@property (strong) SVPodcast *currentPodcast;
@property (strong) SVPodcastEntry *currentEpisode;
@property (assign, readonly) PlaybackState playbackState;
@property (assign, readonly) BOOL isStreaming;
+ (SVPlaybackManager *)sharedInstance;

- (AVPlayer *)player;
- (void)play;
- (void)pause;
- (void)skipForward;
- (void)skipBack;
- (BOOL)startedPlayback;
- (void)loadEpisode:(SVPodcastEntry *)episode
            andPlay:(BOOL)shouldPlay;
- (void)setPlaybackRate:(CGFloat)rate;
- (void)loadPlaybackStateFromCoder:(NSCoder *)coder;
- (void)savePlaybackStateToCoder:(NSCoder *)coder;
@end
