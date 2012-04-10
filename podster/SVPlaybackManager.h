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
    kPlaybackStatePlaying,
    kPlaybackStateStopped
} PlaybackState;
@interface SVPlaybackManager : UIResponder<AVAudioSessionDelegate>
@property (strong) SVPodcast *currentPodcast;
@property (strong) SVPodcastEntry *currentEpisode;
@property (assign, readonly) PlaybackState playbackState;
+ (SVPlaybackManager *)sharedInstance;

- (AVPlayer *)player;
- (void)play;
- (void)pause;
- (void)skipForward;
- (void)skipBack;
- (BOOL)startedPlayback;
- (void)playEpisode:(SVPodcastEntry *)episode ofPodcast:(SVPodcast *)podcast;
- (void)setPlaybackRate:(CGFloat)rate;
@end
