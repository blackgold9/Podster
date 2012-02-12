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

// The percentage after which a podcast is marked as played
#define PLAYED_PERCENTAGE 0.95
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
@interface SVPlaybackManager()
@property (assign, readwrite) PlaybackState playbackState;
@end
@implementation SVPlaybackManager {
    AVPlayer *_player;
    dispatch_queue_t monitorQueue;
    id monitorId;
    // Represents whether the user has triggered playback.
    // This is used to decide whether ot not to start playback after an interruption (phone call) has completed
    BOOL playing;
}
@synthesize currentPodcast;
@synthesize currentEpisode;
@synthesize playbackState;
- (id)init {
    self = [super init];
    if (self) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback 
                                               error:nil];
        self.playbackState = kPlaybackStateStopped;
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
            NSInteger duration = blockSelf->_player.currentItem.duration.value / blockSelf->_player.currentItem.duration.timescale;
            if( blockSelf.currentEpisode.durationValue != duration) {
                blockSelf.currentEpisode.durationValue = duration;
            }
            
            blockSelf.currentEpisode.positionInSecondsValue = time.value / time.timescale;            
            CGFloat currentPosition = (CGFloat)blockSelf.currentEpisode.positionInSecondsValue;
            CGFloat totalDuration = (CGFloat)blockSelf.currentEpisode.durationValue;
            CGFloat progresPercentage = currentPosition / totalDuration;
            if (progresPercentage > PLAYED_PERCENTAGE) {
                // Mark as played when you pass the played percentage
                if (blockSelf.currentEpisode.playedValue != YES) {
                    blockSelf.currentEpisode.playedValue = YES;
                }
            }
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
   
    NSError *error;
    [[AVAudioSession sharedInstance] setActive: YES error: &error];
    NSAssert(error == nil, @"There should be no error starting the session");
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    

  
    [[AVAudioSession sharedInstance] setDelegate:self];
    if (!_player) {    
        LOG_GENERAL(4, @"Initializing player");
        _player = [AVPlayer playerWithURL:[NSURL URLWithString:episode.mediaURL]];
        LOG_GENERAL(4, @"Player Initialized");
        monitorQueue = dispatch_queue_create("com.vantertech.podster.playbackmonitor", DISPATCH_QUEUE_SERIAL);
        [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
        [_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];

        [(SVAppDelegate *)[[UIApplication sharedApplication] delegate] startListening];
     
//        [self startPositionMonitoring];
    }
    
    
    [_player replaceCurrentItemWithPlayerItem:[[AVPlayerItem alloc] initWithURL:[NSURL URLWithString:episode.mediaURL]]];
    [_player play];
 
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:episode.title, MPMediaItemPropertyTitle,
                            podcast.author, MPMediaItemPropertyArtist,
                            podcast.title, MPMediaItemPropertyAlbumTitle,
                            [NSNumber numberWithInteger:episode.positionInSecondsValue],MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:params];
    AFImageRequestOperation *imageOp = 
    [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[currentPodcast logoURL]]] 
                                                                                         success:^(UIImage *image) {
                                                                                             NSMutableDictionary *imageParams = [NSMutableDictionary dictionaryWithDictionary:params];
                                                                                             MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                                                                                             [imageParams setObject:artwork forKey:MPMediaItemPropertyArtwork];
                                                                                             [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:imageParams];

        
    }];
  
    [imageOp start];
    // Check if there was a previous position
    BOOL hasSavedPlaybackPosition = episode.positionInSecondsValue > 0;
    BOOL prettyMuchAtTheEnd = episode.positionInSecondsValue > episode.durationValue - 120;
    if (hasSavedPlaybackPosition && !prettyMuchAtTheEnd ) {
        [FlurryAnalytics logEvent:@"PlayingEpisodeResumingFromPreviousPosition"];
        LOG_PLAYBACK(2, @"Resuming at %d seconds", episode.positionInSecondsValue);
        [_player seekToTime:CMTimeMake(episode.positionInSecondsValue, 1)];
    }
}

-(void)play
{
    if (_player) {
        [_player play];

    }

}

-(void)pause
{
    if (_player) {
        [_player pause];
    }
}

#pragma mark - AVAudioSessionDelegate
- (void)endInterruptionWithFlags:(NSUInteger)flags {
   if (flags == AVAudioSessionInterruptionFlags_ShouldResume && kPlaybackStatePlaying) {
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
                    LOG_PLAYBACK(2,@"Started Playback");
                } else if (_player.status == AVPlayerItemStatusFailed) {
                    LOG_PLAYBACK(1,@"Playback failed with error: %@", _player.error);
                    [FlurryAnalytics logError:@"PlaybackFailed" message:[_player.error localizedDescription] error:_player.error];
                    //TODO: Reflect to user?
                }
            } else if ([keyPath isEqualToString:@"rate"]) {
                if (_player.rate == 0) {
                    CMTime bufferTime = CMTimeSubtract(_player.currentItem.duration, CMTimeMakeWithSeconds(10, 1)) ;
                    if (CMTIME_COMPARE_INLINE(_player.currentTime,>=,bufferTime)) {
                        LOG_PLAYBACK(1, @"Stopping playback, epsidoe complete");                        
                        self.playbackState = kPlaybackStateStopped;
                    } else {
                        LOG_PLAYBACK(3, @"Pausing playback");
                        self.playbackState = kPlaybackStatePaused;
                    }
                    
                    [_player removeTimeObserver:monitorId];
                } else {
                    LOG_PLAYBACK(2, @"Playback started");
                    [self startPositionMonitoring];
                    self.playbackState = kPlaybackStatePlaying;
                    
                }
            }
        }
    }
}
@end
