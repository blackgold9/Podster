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
#import "PodcastImage.h"
#import "BannerViewController.h"

// The percentage after which a podcast is marked as played
#define PLAYED_PERCENTAGE 0.95
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
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
            
//            DDLogInfo(@"A route change occurred that does not require pausing of application audio.");
		}
	}
}
@interface SVPlaybackManager()
@property (assign, readwrite) PlaybackState playbackState;
@property (assign, nonatomic) BOOL monitoringPlayback;
@property (assign, readwrite) BOOL isStreaming;
@property (nonatomic, strong, readwrite) AVPlayer *player;
@end
@implementation SVPlaybackManager {
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
        monitorQueue = dispatch_queue_create("com.vantertech.podster.playbackmonitor", DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(monitorQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
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

- (BOOL)startedPlayback {
    return self.player != nil;
}

-(void)setPlaybackRate:(CGFloat)rate
{
    playbackRate = rate;
    [self.player setRate:playbackRate];
}

- (void)startPositionMonitoring
{
    __weak __typeof(self) weakSelf = self;
    monitorId = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(5, 1) queue:monitorQueue usingBlock:^(CMTime time) {
        NSManagedObjectContext *localContext = [NSManagedObjectContext MR_rootSavingContext];
        [localContext performBlock:^{
            

            SVPlaybackManager *blockSelf = weakSelf;
            SVPodcastEntry *episode = [blockSelf.currentEpisode MR_inContext:localContext];
            NSInteger duration = blockSelf.player.currentItem.duration.value / blockSelf.player.currentItem.duration.timescale;
            if( episode.durationValue != duration) {
                episode.durationValue = duration;
            }
            
            episode.positionInSecondsValue = time.value / time.timescale;
            CGFloat currentPosition = (CGFloat)episode.positionInSecondsValue;
            CGFloat totalDuration = (CGFloat)episode.durationValue;
            CGFloat progresPercentage = currentPosition / totalDuration;
            if (progresPercentage > PLAYED_PERCENTAGE) {
                // Mark as played when you pass the played percentage
                if (episode.playedValue == NO) {
                    episode.playedValue = YES;
                }
            }
            
        }];
    }];
}


- (void)loadEpisode:(SVPodcastEntry *)episode
            andPlay:(BOOL)shouldPlay
{
    DDLogInfo(@"Assigning new current podcast/episode");
    
    NSParameterAssert(episode);
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    [self stopAndCleanUpPlayer];
    self.currentEpisode = [episode MR_inContext:context];
    self.currentPodcast = episode.podcast;
    BOOL isDownloaded = self.currentEpisode.downloadCompleteValue;
    NSString *localFilePath = self.currentEpisode.localFilePath;
    NSString *mediaURL  =self.currentEpisode.mediaURL;
    NSAssert(mediaURL != nil, @"The podcast must have a mediaURL");
    playbackRate = 1.0; // Reset playback rate
    NSString *episodeTitle = self.currentEpisode.title;
    NSString *podcastTitle = self.currentEpisode.podcast.title;
    NSInteger episodeId = self.currentEpisode.podstoreIdValue;
    BOOL hasSavedPlaybackPosition = self.currentEpisode.positionInSecondsValue > 0;
    BOOL prettyMuchAtTheEnd = self.currentEpisode.positionInSecondsValue > episode.durationValue - 120;
    NSError *error;
    DDLogVerbose(@"Setting Session to active");
    [[AVAudioSession sharedInstance] setActive: YES error: &error];
    NSAssert(error == nil, @"There should be no error starting the session");
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    DDLogVerbose(@"Session is now active");
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:localFilePath];
    BOOL actuallyDownloaded = isDownloaded && fileExists;
    NSURL *url = actuallyDownloaded ? [NSURL fileURLWithPath:localFilePath]: [NSURL URLWithString:mediaURL];
    self.isStreaming = !actuallyDownloaded;
    if(isDownloaded && !fileExists) {
        NSAssert(fileExists, @"The file should exist at this point");
        
        // If we're in this error state. Clean up.
        [self.currentEpisode.managedObjectContext performBlock:^void() {
            self.currentEpisode.downloadCompleteValue = NO;
        }];
        
        [Flurry logEvent:@"MissingLocalFile"];
        DDLogError(@"!!!!Expected to find a file for episode with id %d, did not.", episodeId);
    }
    
    self.playbackState = kPlaybackStateBuffering;
    
    DDLogInfo(@"Playing %@ - %@ at URL: %@", podcastTitle, episodeTitle, url);
    DDLogInfo(@"Playing %@ version", actuallyDownloaded ? @"local" : @"streaming");
    [[AVAudioSession sharedInstance] setDelegate:self];
    
    if (!self.player) {
        DDLogVerbose(@"Initializing player");
        self.player = [AVPlayer playerWithURL:url];
        DDLogVerbose(@"Player Initialized");
        
        [self.player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
        [self.player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
        [self.player addObserver:self forKeyPath:@"currentItem" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
        
        [(SVAppDelegate *)[[UIApplication sharedApplication] delegate] startListening];
    }
    
    
    // If there was an existing current item, clear it first
    if (currentItem) {
        //            [currentItem removeObserver:self forKeyPath:@"status"];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:currentItem];
        currentItem = nil;
    }
    
    DDLogInfo(@"Loading media at URL:%@", url);
    currentItem = [[AVPlayerItem alloc] initWithURL:url];
    //        [currentItem addObserver:self
    //                      forKeyPath:@"status"
    //                         options:NSKeyValueObservingOptionNew
    //                         context:(__bridge void*)self];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(itemReachedEnd)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification object:currentItem];
    
    [self.player replaceCurrentItemWithPlayerItem:currentItem];
    if (shouldPlay) {
        [self setPlaybackRate:1];
    } else {
        [self setPlaybackRate:0];
        self.playbackState = kPlaybackStatePaused;
    }
    NSDictionary *params = @{
    MPMediaItemPropertyTitle : episodeTitle,
    MPMediaItemPropertyAlbumTitle : podcastTitle
    };
    
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:params];
    
    [[NSManagedObjectContext MR_defaultContext] performBlock:^{
        if (self.currentPodcast.fullImage == nil) {
            AFImageRequestOperation *imageOp =
            [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self.currentPodcast logoURL]]]
                                                              success:^(UIImage *image) {
                                                                  NSMutableDictionary *imageParams = [NSMutableDictionary dictionaryWithDictionary:params];
                                                                  MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                                                                  [imageParams setObject:artwork forKey:MPMediaItemPropertyArtwork];
                                                                  [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:imageParams];
                                                                  
                                                                  
                                                              }];
            
            [imageOp start];
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = [[UIImage alloc] initWithData:currentPodcast.fullImage.imageData];
                NSMutableDictionary *imageParams = [NSMutableDictionary dictionaryWithDictionary:params];
                MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:image];
                [imageParams setObject:artwork forKey:MPMediaItemPropertyArtwork];
                [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:imageParams];
                
            });
        }
        
        if (hasSavedPlaybackPosition && !prettyMuchAtTheEnd ) {
            [Flurry logEvent:@"PlayingEpisodeResumingFromPreviousPosition"];
            DDLogInfo(@"Resuming at %d seconds", episode.positionInSecondsValue);
            [self.player seekToTime:CMTimeMake(episode.positionInSecondsValue, 1)];
        } else {
            DDLogInfo(@"Starting at the beginning");
        }
    }];   
}


- (void)itemReachedEnd
{
    [[NSManagedObjectContext MR_defaultContext] performBlock:^{
        self.currentEpisode.playedValue = YES;
        self.currentEpisode.positionInSecondsValue = 0;
        
    }];
}
-(void)play
{
    if (self.player) {
        userWantsPlayback = YES;
        [self.player setRate:playbackRate];
    }
}

-(void)pause
{
    if (self.player) {
        userWantsPlayback = NO;
        [self.player pause];
    }
}

- (void)skipForward
{
    CMTime ammount = CMTimeMake(30, 1);
    [self.player seekToTime:CMTimeAdd(ammount, self.player.currentTime)];
}

- (void)skipBack
{
    CMTime ammount = CMTimeMake(7, 1);
    [self.player seekToTime:CMTimeSubtract(self.player.currentTime, ammount)];
    
}

#pragma mark - AVAudioSessionDelegate
- (void)endInterruptionWithFlags:(NSUInteger)flags {
    if (flags == AVAudioSessionInterruptionOptionShouldResume && userWantsPlayback) {
        NSAssert(self.player !=nil, @"The player is expected to exist here");
        [self setPlaybackRate:1];
        [[AVAudioSession sharedInstance] setActive: YES error: nil];
    }
    
}

- (void)stopAndCleanUpPlayer
{
    [self stopMonitoring];
    [self.player pause];
    self.currentEpisode = nil;
    self.currentPodcast = nil;


}

- (void)stopMonitoring
{
    if (monitorId) {
        [self.player removeTimeObserver:monitorId];
        monitorId = nil;
    }
}

#pragma mark - KVO
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //if ((__bridge id)context == self) {
        

        if (object == self.player) {
            if ([keyPath isEqualToString:@"currentItem"]) {
                DDLogVerbose(@"Currentitem changed to : %@", [self.player currentItem]);
                NSLog(@"Test");
            } else if ([keyPath isEqualToString:@"status"]) {
                
                if (self.player.status == AVPlayerStatusReadyToPlay) {
                    [self setPlaybackRate:1];
                    DDLogInfo(@"Started Playback");
                } else if (self.player.status == AVPlayerItemStatusFailed) {
                    DDLogError(@"Playback failed with error: %@", self.player.error);
                    [Flurry logError:@"PlaybackFailed" message:[self.player.error localizedDescription] error:self.player.error];
                    [self stopAndCleanUpPlayer];
                    //TODO: Reflect to user?
                }
            } else if ([keyPath isEqualToString:@"rate"]) {
                if (self.player.rate == 0) {
                    DDLogInfo(@"Pausing playback");
                    self.playbackState = kPlaybackStatePaused;
                    
                    [self stopMonitoring];
                    
                } else {
                    if (self.playbackState !=kPlaybackStatePlaying) {
                        DDLogInfo(@"Starting playback");
                        [self startPositionMonitoring];
                        NSAssert([self.player status] != AVPlayerStatusFailed,@"Invalids tatus");
                        self.playbackState = kPlaybackStatePlaying;
                    }
                    
                    
                }
            }
        } else if (object == currentItem) {
            switch (currentItem.status) {
                case AVPlayerItemStatusFailed:
                {
                    NSAssert([NSThread isMainThread], @"Should only execute on main thread");
                    [Flurry logError:@"PlaybackFailed"
                             message:[currentItem.error localizedDescription]
                               error:currentItem.error];
                    DDLogError(@"Playback Error:  %@", currentItem.error);
                    NSString *errorMessage;
                    if ([[currentItem.error domain] isEqualToString:@"NSURLErrorDomain"] && currentItem.error.code == -1102) {
                        errorMessage = @"This episode is no longer avaialble from the publisher. Please select another episode";
                    } else {
                        errorMessage = NSLocalizedString(@"There was a problem playing this podcast. Please try again later.", @"There was a problem playing this podcast. Please try again later.");
                    }
                    BlockAlertView *alertView = [[BlockAlertView alloc] initWithTitle:[MessageGenerator randomErrorAlertTitle]
                                                                              message:errorMessage];
                    
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
                    DDLogError(@"Error during playback: %@", currentItem.error);
                    break;    
                }
                default:
                    break;
            }
        }
   // }
}

#pragma mark - state restoration
- (void)savePlaybackStateToCoder:(NSCoder *)coder
{
    if (self.currentEpisode) {
        [coder encodeObject:self.currentEpisode.podstoreId forKey:@"playingPodstoreId"];
    }
}

- (void)loadPlaybackStateFromCoder:(NSCoder *)coder
{
    if ([coder decodeObjectForKey:@"playingPodstoreId"]) {
        DDLogInfo(@"Found playback state to restore");
        NSNumber *podstoreId = [coder decodeObjectForKey:@"playingPodstoreId"];
        SVPodcastEntry *entry = [SVPodcastEntry MR_findFirstByAttribute:@"podstoreId" withValue:podstoreId];
        if (entry) {
            [self loadEpisode:entry
                      andPlay:NO];
        }
    } else {
        DDLogInfo(@"Didn't find any playback state to restore");
    }
}
@end
