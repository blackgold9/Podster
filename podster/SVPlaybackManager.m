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
#import "SVPodcastEntry.h"
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

- (void)playEpisode:(SVPodcastEntry *)episode
          ofPodcast:(SVPodcast *)podcast{
    
    LOG_GENERAL(4, @"Assigning new current podcast/episode");
    self.currentEpisode = [episode inContext:[NSManagedObjectContext defaultContext]];;
    self.currentPodcast = [podcast inContext:[NSManagedObjectContext defaultContext]];;
    NSParameterAssert(episode);
    NSParameterAssert(podcast);
    NSAssert(episode.mediaURL != nil, @"The podcast must have a mediaURL");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
    });
    LOG_GENERAL(4, @"Setting up audio session");
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    if (!_player) {
        _player = [AVPlayer playerWithURL:[NSURL URLWithString:episode.mediaURL]];
        [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
    }
    LOG_GENERAL(4, @"Triggering playback");
    [_player replaceCurrentItemWithPlayerItem:[[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:episode.mediaURL]]];
    
   
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((__bridge id)context == self) {
        if (object == _player) {
            if ([keyPath isEqualToString:@"status"]) {

                if (_player.status == AVPlayerStatusReadyToPlay) {
                    [_player play];
                    LOG_NETWORK(2,@"Started Playback");
                } else {
                    LOG_NETWORK(1,@"Error downloing");
                }
            }
        }
    }
}
@end
