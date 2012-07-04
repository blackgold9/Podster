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
#import "BlockAlertView.h"
#import "SVPlaybackController.h"
#import "MessageGenerator.h"
#import "BannerViewController.h"
#import "_SVDownload.h"
#import "SVDownload.h"
#import "BannerViewController.h"

// The percentage after which a podcast is marked as played
#define PLAYED_PERCENTAGE 0.95
static const int ddLogLevel = LOG_LEVEL_WARN;
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

			[[SVPlaybackManager sharedInstance]  pause];

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
    AVPlayerItem *currentItem;
    dispatch_queue_t monitorQueue;
    BOOL userWantsPlayback;
    id monitorId;
    // Represents whether the user has triggered playback.
    // This is used to decide whether ot not to start playback after an interruption (phone call) has completed
    BOOL playingWhenInterrupted;
    CGFloat playbackRate;
}
@synthesize currentPodcast;
@synthesize currentEpisode;
@synthesize playbackState;
@synthesize isStreaming;
- (id)init {
    self = [super init];
    if (self) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback 
                                               error:nil];
        self.playbackState = kPlaybackStateStopped;
        playbackRate = 1.0;
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

-(void)setPlaybackRate:(CGFloat)rate
{
    playbackRate = rate;
    if (playbackState == kPlaybackStatePlaying) {
        [_player setRate:playbackRate];
    }
}

- (void)startPositionMonitoring
{
    __block __typeof(self) blockSelf = self;
    monitorId = [_player addPeriodicTimeObserverForInterval:CMTimeMake(5, 1) queue:monitorQueue usingBlock:^(CMTime time) {
        [[PodsterManagedDocument defaultContext] performBlock:^{
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
                if (blockSelf.currentEpisode.playedValue == NO) {
                    blockSelf.currentEpisode.playedValue = YES;

                }
            }
        }];
    }];
}

- (void)playEpisode:(SVPodcastEntry *)episode
          ofPodcast:(SVPodcast *)podcast{
    LOG_GENERAL(4, @"Assigning new current podcast/episode");

    NSParameterAssert(episode);
    NSParameterAssert(podcast);
    NSManagedObjectContext *context = [PodsterManagedDocument defaultContext];
    
    self.currentEpisode = [episode MR_inContext:context];
    self.currentPodcast = [podcast MR_inContext:context];;
    NSAssert(episode.mediaURL != nil, @"The podcast must have a mediaURL");
    playbackRate = 1.0; // Reset playback rate
    NSError *error;
    [[AVAudioSession sharedInstance] setActive: YES error: &error];
    NSAssert(error == nil, @"There should be no error starting the session");
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];

    BOOL isDownloaded = self.currentEpisode.downloadCompleteValue;
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:self.currentEpisode.localFilePath];

    BOOL actuallyDownloaded = isDownloaded && fileExists;
    NSURL *url = actuallyDownloaded ? [NSURL fileURLWithPath:self.currentEpisode.localFilePath]: [NSURL URLWithString:currentEpisode.mediaURL];
    isStreaming = !actuallyDownloaded;

    if(isDownloaded && !fileExists) {
        NSAssert(fileExists, @"The file should exist at this point");

        // If we're in this error state. Clean up.
        [self.currentEpisode.managedObjectContext performBlock:^void() {
            self.currentEpisode.downloadCompleteValue = NO;
        }];
        [FlurryAnalytics logEvent:@"MissingLocalFile"];
        DDLogError(@"!!!!Expected to find a file for episode with id %d, did not.", self.currentEpisode.podstoreIdValue);
    }

    DDLogInfo(@"Playing %@ - %@ at URL: %@", self.currentEpisode.podcast.title, self.currentEpisode.title, url);
    DDLogInfo(@"Playing %@ version", actuallyDownloaded ? @"local" : @"streaming");

    [[AVAudioSession sharedInstance] setDelegate:self];
    if (!_player) {    
        LOG_GENERAL(4, @"Initializing player");
        _player = [AVPlayer playerWithURL:url];
        LOG_GENERAL(4, @"Player Initialized");
        if (monitorQueue) {
            dispatch_release(monitorQueue);
        }
        monitorQueue = dispatch_queue_create("com.vantertech.podster.playbackmonitor", DISPATCH_QUEUE_SERIAL);
        [_player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
        [_player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];

        [(SVAppDelegate *)[[UIApplication sharedApplication] delegate] startListening];
    }
    
    LOG_PLAYBACK(2, @"Loading media at URL:%@", url);
    if (currentItem) {
        [currentItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:currentItem];
    }//


    currentItem = [[AVPlayerItem alloc] initWithURL:url];
    [currentItem addObserver:self 
                  forKeyPath:@"status" 
                     options:NSKeyValueObservingOptionNew 
                     context:(__bridge void*)self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemReachedEnd) 
                                                 name:AVPlayerItemDidPlayToEndTimeNotification object:currentItem];
    [_player replaceCurrentItemWithPlayerItem:currentItem];
    [self play];
 
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:episode.title, MPMediaItemPropertyTitle,
                            podcast.author, MPMediaItemPropertyArtist,
                            podcast.title, MPMediaItemPropertyAlbumTitle,
                            [NSNumber numberWithInteger:episode.positionInSecondsValue],MPNowPlayingInfoPropertyElapsedPlaybackTime, nil];
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:params];

    if (currentPodcast.fullIsizeImageData == nil) {
        AFImageRequestOperation *imageOp =
                [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[currentPodcast logoURL]]]
                        success:^(UIImage *image) {
                            NSMutableDictionary *imageParams = [NSMutableDictionary dictionaryWithDictionary:params];
                            MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                            [imageParams setObject:artwork forKey:MPMediaItemPropertyArtwork];
                            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:imageParams];


                        }];

        [imageOp start];
    } else {
        UIImage *image = [[UIImage alloc] initWithData:currentPodcast.fullIsizeImageData];
        NSMutableDictionary *imageParams = [NSMutableDictionary dictionaryWithDictionary:params];
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
        [imageParams setObject:artwork forKey:MPMediaItemPropertyArtwork];
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:imageParams];
    }

    // Check if there was a previous position
    BOOL hasSavedPlaybackPosition = episode.positionInSecondsValue > 0;
    BOOL prettyMuchAtTheEnd = episode.positionInSecondsValue > episode.durationValue - 120;

    if (hasSavedPlaybackPosition && !prettyMuchAtTheEnd ) {
        [FlurryAnalytics logEvent:@"PlayingEpisodeResumingFromPreviousPosition"];
        LOG_PLAYBACK(2, @"Resuming at %d seconds", episode.positionInSecondsValue);
        [_player seekToTime:CMTimeMake(episode.positionInSecondsValue, 1)];
    } else {
        LOG_PLAYBACK(2, @"Starting at the beginning");
    }
}
- (void)itemReachedEnd
{
    [[PodsterManagedDocument defaultContext] performBlock:^{
        self.currentEpisode.playedValue = YES;
        self.currentEpisode.positionInSecondsValue = 0;   

    }];
}
-(void)play
{
    if (_player) {
        userWantsPlayback = YES;
        [_player setRate:playbackRate];
    }
}

-(void)pause
{
    if (_player) {
        userWantsPlayback = NO;
        [_player pause];
    }
}

- (void)skipForward
{
    CMTime ammount = CMTimeMake(30, 1);
    [_player seekToTime:CMTimeAdd(ammount, _player.currentTime)];
}

- (void)skipBack
{
    CMTime ammount = CMTimeMake(7, 1);
    [_player seekToTime:CMTimeSubtract(_player.currentTime, ammount)];

}

#pragma mark - AVAudioSessionDelegate
- (void)endInterruptionWithFlags:(NSUInteger)flags {
   if (flags == AVAudioSessionInterruptionFlags_ShouldResume && userWantsPlayback) {
       NSAssert(_player !=nil, @"The player is expected to exist here");
       [self play];
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
                    [self play];
                    LOG_PLAYBACK(2,@"Started Playback");
                } else if (_player.status == AVPlayerItemStatusFailed) {
                    LOG_PLAYBACK(1,@"Playback failed with error: %@", _player.error);
                    [FlurryAnalytics logError:@"PlaybackFailed" message:[_player.error localizedDescription] error:_player.error];
                    _player = nil;           
                    self.currentEpisode = nil;
                    self.currentPodcast = nil;
                    //TODO: Reflect to user?
                }
            } else if ([keyPath isEqualToString:@"rate"]) {
                if (_player.rate == 0) {                
                    LOG_PLAYBACK(3, @"Pausing playback");
                    self.playbackState = kPlaybackStatePaused;
                    
                    
                    [_player removeTimeObserver:monitorId];
                } else {
                    if (self.playbackState !=kPlaybackStatePlaying) {
                        LOG_PLAYBACK(3, @"Starting playback");
                        [self startPositionMonitoring];
                        self.playbackState = kPlaybackStatePlaying;
                    }
                    
                    
                }
            }
        } else if (object == currentItem) {
            switch (currentItem.status) {
                case AVPlayerItemStatusFailed:
                {
                    NSAssert([NSThread isMainThread], @"Should only execute on main thread");
                    [FlurryAnalytics logError:@"PlaybackFailed" 
                                      message:[currentItem.error localizedDescription] 
                                        error:currentItem.error];
                    DDLogError(@"Playback Error:  %@", currentItem.error);
                    BlockAlertView *alertView = [[BlockAlertView alloc] initWithTitle:[MessageGenerator randomErrorAlertTitle]
                                                                              message:NSLocalizedString(@"There was a problem playing this podcast. Please try again later.", @"There was a problem playing this podcast. Please try again later.")];
                    [alertView setCancelButtonWithTitle:NSLocalizedString(@"OK", @"OK") block:^{
                        UIWindow *window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
                        UINavigationController *nav = nil;
                                        if ([window.rootViewController class] == [UINavigationController class]) {
                                            nav = (UINavigationController *)window.rootViewController;
                                        } else {
                                            //If the root isnt a nav controller, it's a banner controller;
                                            BannerViewController *bc = (BannerViewController *) window.rootViewController;
                                            nav = (UINavigationController *)[bc contentController];
                                        }

                            if ([[nav topViewController] class] == [SVPlaybackController class]) {
                                double delayInSeconds = 0.5;
                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                    [nav popViewControllerAnimated:YES];
                                });
                            }

                    }];
                    
                    [alertView show];
                    LOG_PLAYBACK(1, @"Error during playback: %@", currentItem.error);
                    break;    
                }
                default:
                    break;
            }
        }
    }
}
@end
