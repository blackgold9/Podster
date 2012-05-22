//
//  SVPlaybackController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVPlaybackController.h"
#import <AVFoundation/AVFoundation.h>
#import "OBSlider.h"
#import "SVPodcast.h"
#import "SVPodcastEntry.h"
#import "SVPlaybackManager.h"
#import "SVPodcatcherClient.h"
#import <QuartzCore/QuartzCore.h>
#import <MediaPlayer/MediaPlayer.h>
#import <Twitter/Twitter.h>

@implementation SVPlaybackController {
    AVPlayer *player;
    id playerObserver;
    CGFloat playbackSpeed;
}
@synthesize containerView;
@synthesize rateLabel;
@synthesize foregroundAlbumArt;
@synthesize skipForwardButton;
@synthesize skipBackButton;
@synthesize chromeViews;
@synthesize rateImage;
@synthesize titleLabel;
@synthesize artworkImage;
@synthesize progressSlider;
@synthesize timeRemainingLabel;
@synthesize timeElapsedLabel;
@synthesize playButton;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle
-(void)viewDidAppear:(BOOL)animated
{
    [FlurryAnalytics logEvent:@"PlaybackPageView" timed:YES];

    NSURL *imageURL = [NSURL URLWithString:[SVPlaybackManager sharedInstance].currentPodcast.logoURL];
    SVPodcastEntry *episode = [SVPlaybackManager sharedInstance].currentEpisode;
    if (episode.podcast.fullIsizeImageData != nil) {
        self.artworkImage.image = [UIImage imageWithData:episode.podcast.fullIsizeImageData];
    } else {
        [self.artworkImage setImageWithURL:imageURL placeholderImage:nil];
    }
}
-(void)viewDidDisappear:(BOOL)animated
{
    [FlurryAnalytics endTimedEvent:@"PlaybackPageView" withParameters:nil];
    [player removeObserver:self forKeyPath:@"status" context:(__bridge void*)self];
    [player removeObserver:self forKeyPath:@"rate" context:(__bridge void*)self];
    [player removeTimeObserver:playerObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self];

}
- (void)registerObservers
{
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
    [player addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
    __weak SVPlaybackController  *weakSelf = self;
    playerObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 2) queue:NULL usingBlock:^(CMTime time) {
        if (weakSelf == nil) {
            return;
        }
        
        
        CMTime duration = weakSelf->player.currentItem.duration;
        CMTimeValue currentTimeInSeconds = time.value / time.timescale;
        NSInteger remaining = (duration.value / duration.timescale) - (currentTimeInSeconds);
        weakSelf.timeElapsedLabel.text = [SVPlaybackController formattedStringRepresentationOfSeconds:(currentTimeInSeconds)];
        weakSelf.timeRemainingLabel.text = [SVPlaybackController formattedStringRepresentationOfSeconds:remaining];
        if (player.rate != 0 && remaining != 0) {
            if(!weakSelf.progressSlider.isTracking) {
                weakSelf.progressSlider.value = (float) (currentTimeInSeconds) / (duration.value / duration.timescale);
            }
        }
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.navigationController popViewControllerAnimated:YES];
                                                  }];

}

-(void)viewWillAppear:(BOOL)animated
{
        self.navigationController.toolbarHidden = YES;
    LOG_GENERAL(2, @"View did appear");
    LOG_NETWORK(4, @"Triggering albumart image load");
    if (player.rate == 0) {
        self.playButton.selected = NO;
    } else {
        self.playButton.selected = YES;
    }
    self.timeRemainingLabel.text = [SVPlaybackController formattedStringRepresentationOfSeconds:[SVPlaybackManager sharedInstance].currentEpisode.durationValue];
    self.navigationItem.title = @"Now Playing";
    self.titleLabel.text = [SVPlaybackManager sharedInstance].currentEpisode.title;
    [self registerObservers];
    [self.navigationController setToolbarHidden:YES animated:NO];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    LOG_GENERAL(4, @"Super viewdidload");
    [super viewDidLoad];
    
    UIView *placeholder = [self.view viewWithTag:1111];
    CGRect placeholderFrame = placeholder.frame;
    UIView *placeholderSuperView = [placeholder superview];
    [placeholder removeFromSuperview];

    MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:placeholderFrame];
    volumeView.showsRouteButton = YES;
    volumeView.showsVolumeSlider = NO;
    [placeholderSuperView addSubview:volumeView];
          
    player = [[SVPlaybackManager sharedInstance] player];
    rateImage.userInteractionEnabled = YES;
    rateImage.alpha = player.rate == 1.5 ? 1.0 : 0.5;
    playbackSpeed = player.rate;
    UITapGestureRecognizer *tapRec = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rateTapped:)];
    [rateImage addGestureRecognizer:tapRec];
}
- (void)rateTapped:(UIGestureRecognizer *)sender
{
    if (player.rate == 1.5) {
        rateImage.alpha = 0.5;   
        [[SVPlaybackManager sharedInstance] setPlaybackRate:1];
        playbackSpeed =1.0;
    } else {
        rateImage.alpha = 1.0;
        [[SVPlaybackManager sharedInstance] setPlaybackRate:1.5];
        playbackSpeed = 1.5;
    }
    
 
}
- (void)viewDidUnload
{
    [self setProgressSlider:nil];
    [self setTimeRemainingLabel:nil];
    [self setTimeElapsedLabel:nil];
    [self setPlayButton:nil];
    [self setSkipBackButton:nil];
    [self setSkipForwardButton:nil];
    [self setArtworkImage:nil];
    [self setTitleLabel:nil];
    [self setContainerView:nil];
    [self setForegroundAlbumArt:nil];
    [self setRateLabel:nil];
    [self setRateImage:nil];
    [super viewDidUnload];
        // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    NSLog(@"Removing observers");
    [player removeObserver:self forKeyPath:@"status" context:(__bridge void*)self];
    [player removeObserver:self forKeyPath:@"rate" context:(__bridge void*)self];
    [player removeTimeObserver:playerObserver];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ((__bridge id)context == self) {
        if (object == player) {
            if ([keyPath isEqualToString:@"status"]) {
        
                if (player.status == AVPlayerStatusReadyToPlay) {
                    [[SVPlaybackManager sharedInstance] play];
                    LOG_GENERAL(3, @"Started Playback");
                } else {
                    LOG_GENERAL(3, @"Error downloing");
                }
            } else if ([keyPath isEqualToString:@"rate"]){
                if (player.rate == 0) {
                    self.playButton.selected = NO;
                } else {
                    self.playButton.selected = YES;
                }
            }
        }
    }
}
- (IBAction)playTapped:(id)sender {
    if (player.rate == 0) {
        [[SVPlaybackManager sharedInstance] play];
        [FlurryAnalytics logEvent:@"PlayTapped"];
    } else {
        [[SVPlaybackManager sharedInstance] pause];
        [FlurryAnalytics logEvent:@"PauseTapped"];
    }
}
- (IBAction)sliderChanged:(id)sender {
    OBSlider *slider = sender;
    if (slider.isTracking) {

        CMTime duration = [player.currentItem duration];
        NSInteger durationInSeconds = duration.value / duration.timescale;
        NSInteger currentSeconds = (float)slider.value * durationInSeconds;
        self.timeElapsedLabel.text = [SVPlaybackController formattedStringRepresentationOfSeconds:currentSeconds];
        self.timeRemainingLabel.text = [SVPlaybackController formattedStringRepresentationOfSeconds:durationInSeconds - currentSeconds];

        [player seekToTime:CMTimeMake(currentSeconds, 1)];
        
    }
}

- (IBAction)skipForwardTapped:(id)sender {
    [FlurryAnalytics logEvent:@"SkipBackTapped"];
    [[SVPlaybackManager sharedInstance] skipForward];
    
}

- (IBAction)skipBackTapped:(id)sender {
    [FlurryAnalytics logEvent:@"SkipForwardTapped"];
        [[SVPlaybackManager sharedInstance] skipBack];
  }

- (IBAction)shareTapped:(id)sender {
    TWTweetComposeViewController *tweet = [[TWTweetComposeViewController alloc] init];
    [tweet setInitialText:[NSString stringWithFormat:@"Sharing an episode of %@ (via @ItsPodster)",     [SVPlaybackManager sharedInstance].currentPodcast.title]];
    [tweet addURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.podsterapp.com/feed_items/%d",[SVPlaybackManager sharedInstance].currentEpisode.podstoreIdValue]]];
    
    // Show the controller
    [self presentModalViewController:tweet animated:YES];
    
    // Called when the tweet dialog has been closed
    tweet.completionHandler = ^(TWTweetComposeViewControllerResult result) 
    {
        // Dismiss the controller
        [self dismissModalViewControllerAnimated:YES];
    };
    

}
#pragma mark - helpers


+(NSString *)formattedStringRepresentationOfSeconds:(NSInteger)totalSeconds
{
    NSInteger hourInSeconds = 3600;
    NSInteger hours = totalSeconds / hourInSeconds;
    NSInteger minutes = (totalSeconds % hourInSeconds) / 60;
    NSInteger seconds = totalSeconds % 60;
    if( hours > 0 ) {
        return [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes,seconds];
    } else {
        return [NSString stringWithFormat:@"%02d:%02d", minutes,seconds];

    }
}
- (IBAction)actionTapped:(id)sender {
}
@end
