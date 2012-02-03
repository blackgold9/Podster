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
#import <AudioToolbox/AudioToolbox.h>
// Prototype for following callbakc function
void audioRouteChangeListenerCallback (
                                       void                      *inUserData,
                                       AudioSessionPropertyID    inPropertyID,
                                       UInt32                    inPropertyValueSize,
                                       const void                *inPropertyValue
                                       );
// This function is supposed to be outside the file interface
void audioRouteChangeListenerCallback (
   void                      *inUserData,
   AudioSessionPropertyID    inPropertyID,
   UInt32                    inPropertyValueSize,
   const void                *inPropertyValue
) {

	// ensure that this callback was invoked for a route change
	if (inPropertyID != kAudioSessionProperty_AudioRouteChange) return;

	// if application sound is not playing, there's nothing to do, so return.
	if ([[SVPlaybackManager sharedInstance] player] == nil ||
        [[SVPlaybackManager sharedInstance] player].rate == 0 ) {

		LOG_GENERAL(2,@"Audio route change while application audio is stopped.");
		return;

	} else {

		// Determines the reason for the route change, to ensure that it is not
		//		because of a category change.
		CFDictionaryRef	routeChangeDictionary = inPropertyValue;

		CFNumberRef routeChangeReasonRef =
						CFDictionaryGetValue (
							routeChangeDictionary,
							CFSTR (kAudioSession_AudioRouteChangeKey_Reason)
						);

		SInt32 routeChangeReason;

		CFNumberGetValue (
			routeChangeReasonRef,
			kCFNumberSInt32Type,
			&routeChangeReason
		);


        BOOL connectedToA2DP = NO;
        CFDictionaryRef currentRouteDictionaryRef =
            CFDictionaryGetValue(routeChangeDictionary,
                                 kAudioSession_AudioRouteChangeKey_CurrentRouteDescription
                                 );

        CFArrayRef outputs = CFDictionaryGetValue(
                                                  currentRouteDictionaryRef, 
                                                  kAudioSession_AudioRouteKey_Outputs
                                                  );
        if (CFArrayGetCount(outputs) > 0) {
           CFDictionaryRef output =  CFArrayGetValueAtIndex(outputs, 0);
            if (output != nil) {
                CFStringRef outputType = CFDictionaryGetValue(
                                                              output,
                                                              kAudioSession_AudioRouteKey_Type
                                                              );
                if (CFStringCompare(outputType, kAudioSessionOutputRoute_BluetoothA2DP, 0) == kCFCompareEqualTo) {
                    connectedToA2DP = YES;
                }

            }
        }
		// "Old device unavailable" indicates that a headset was unplugged, or that the
		//	device was removed from a dock connector that supports audio output. This is
		//	the recommended test for when to pause audio.
		if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable || 
            (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable && connectedToA2DP)) {

			[[[SVPlaybackManager sharedInstance] player] pause];

		} else {

            LOG_GENERAL(2, @"A route change occurred that does not require pausing of application audio.");
		}
	}
}

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
   
    LOG_GENERAL(4, @"Setting up audio session");
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       // AudioSessionAddPropertyListener (
         //                                kAudioSessionProperty_AudioRouteChange,
           //                              audioRouteChangeListenerCallback,
             //                            NULL
               //                          ); 

        
            });
    NSError *error;
    [[AVAudioSession sharedInstance] setActive: YES error: &error];
    NSAssert(error == nil, @"There should be no error starting the session");
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    

  
    [[AVAudioSession sharedInstance] setDelegate:self];
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
    
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:episode.title,MPMediaItemPropertyTitle, podcast.title, MPMediaItemPropertyAlbumTitle ,[NSNumber numberWithInteger:episode.positionInSecondsValue],MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:params];
    
    // Check if there was a previous position
    if (episode.positionInSecondsValue > 0) {
        LOG_GENERAL(2, @"Resuming at %d seconds", episode.positionInSecondsValue);
        [_player seekToTime:CMTimeMake(episode.positionInSecondsValue, 1)];
    }
}

#pragma mark - AVAudioSessionDelegate
- (void)endInterruptionWithFlags:(NSUInteger)flags {
   if (flags == AVAudioSessionInterruptionFlags_ShouldResume) {
       NSAssert(_player !=nil, @"The player is expected to exist here");
       [_player play];
       [[AVAudioSession sharedInstance] setActive: YES error: nil];
   }

}

#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((__bridge id)context == self) {
        if (object == _player) {
            if ([keyPath isEqualToString:@"status"]) {

                if (_player.status == AVPlayerStatusReadyToPlay) {
                    [_player play];
                    LOG_NETWORK(2,@"Started Playback");
                } else if (_player.status == AVPlayerItemStatusFailed) {
                    LOG_NETWORK(1,@"Error downloing");
                    [FlurryAnalytics logError:@"PlaybackFailed" message:[_player.error localizedDescription] error:_player.error];
                    //TODO: Reflect to user?
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
