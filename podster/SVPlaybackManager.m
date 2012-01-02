//
//  SVPlaybackManager.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVPlaybackManager.h"
#import <AVFoundation/AVFoundation.h>
#import "SVPodcast.h"
#import "SVPodcastEpisode.h"
@implementation SVPlaybackManager {
    AVPlayer *_player;
}
@synthesize currentPodcast;
@synthesize currentEpisode;
- (id)init {
    self = [super init];
    if (self) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback 
                                               error:nil];
    }

    return self;
}
+ (SVPlaybackManager *)sharedInstance {
    static SVPlaybackManager *_instance = nil;

    @synchronized (self) {
        if (_instance == nil) {
            _instance = [[self alloc] init];
        }
    }

    return _instance;
}

- (AVPlayer *)player {
    return _player;
}

- (BOOL)startedPlayback {
    return _player != nil;
}

- (void)playEpisode:(SVPodcastEpisode *)episode 
          ofPodcast:(SVPodcast *)podcast{
    NSParameterAssert(episode);
    NSParameterAssert(podcast);
    NSAssert(episode.mediaURL != nil, @"The podcast must have a mediaURL");
    if (!_player) {
        _player = [AVPlayer playerWithURL:[NSURL URLWithString:episode.mediaURL]]; 
    }
    [_player 
}
@end
