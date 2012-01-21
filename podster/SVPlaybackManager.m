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
#import "SVAppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>
@implementation SVPlaybackManager {
    AVPlayer *_player;
    dispatch_queue_t monitorQueue;
    id monitorId;
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

- (void)startPositionMonitoring
{
    __block __typeof(self) blockSelf = self;
    monitorId = [_player addPeriodicTimeObserverForInterval:CMTimeMake(5, 1) queue:monitorQueue usingBlock:^(CMTime time) {
        [[NSManagedObjectContext defaultContext] performBlock:^{
            blockSelf.currentEpisode.positionInSecondsValue = time.value / time.timescale; 
            [[NSManagedObjectContext defaultContext] save];
        }];
    }];
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
        
        monitorQueue = dispatch_queue_create("com.vantertech.podster.playbackmonitor", DISPATCH_QUEUE_SERIAL);
        [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
        [_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];

        [(SVAppDelegate *)[[UIApplication sharedApplication] delegate] startListening];
     
        [self startPositionMonitoring];
    }
    
    
    
    LOG_GENERAL(4, @"Triggering playback");
    [_player replaceCurrentItemWithPlayerItem:[[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:episode.mediaURL]]];
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:episode.title,MPMediaItemPropertyTitle, podcast.title, MPMediaItemPropertyAlbumTitle , nil];
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:params];
    // Check if there was a previous position
    if (episode.positionInSecondsValue > 0) {
        LOG_GENERAL(2, @"Resuming at %d seconds", episode.positionInSecondsValue);
        [_player seekToTime:CMTimeMake(episode.positionInSecondsValue, 1)];
    }
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
            } else if ([keyPath isEqualToString:@"rate"]) {
                if (_player.rate == 0) {
                    [_player removeTimeObserver:monitorId];
                    LOG_GENERAL(3, @"suspending monitoring playback position");
                } else {
                    [self startPositionMonitoring];
                    LOG_GENERAL(3, @"Starting monitoring playback position");
                }
            }
        }
    }
}
@end
