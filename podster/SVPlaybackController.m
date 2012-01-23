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
@implementation SVPlaybackController {
    AVPlayer *player;
    id playerObserver;
}
@synthesize skipForwardButton;
@synthesize skipBackButton;
@synthesize chromeViews;
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
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle
-(void)viewDidAppear:(BOOL)animated
{
    LOG_GENERAL(2, @"View did appear");
    LOG_NETWORK(4, @"Triggering albumart image load");
    NSURL *imageURL = [NSURL URLWithString:[SVPlaybackManager sharedInstance].currentPodcast.logoURL];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[SVPodcatcherClient sharedInstance] imageAtURL:imageURL onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {

            dispatch_async(dispatch_get_main_queue(), ^{
                LOG_NETWORK(4, @"Album art recieved");
                CATransition *transition = [CATransition animation];
                [self.artworkImage.layer addAnimation:transition forKey:nil];
                
                self.artworkImage.image = fetchedImage;

            });
            
        }];
    });
   

}
/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    LOG_GENERAL(4, @"Super viewdidload");
    [super viewDidLoad];

    
    player = [[SVPlaybackManager sharedInstance] player];
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
        if(!weakSelf.progressSlider.isTracking) {
            weakSelf.progressSlider.value = (float) (currentTimeInSeconds) / (duration.value / duration.timescale);
        }
    }];
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
    [super viewDidUnload];
    NSLog(@"Removing observers");
    [player removeObserver:self forKeyPath:@"status" context:(__bridge void*)self];
    [player removeObserver:self forKeyPath:@"rate" context:(__bridge void*)self];
    [player removeTimeObserver:playerObserver];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
                    [player play];
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
        [player play];
    } else {
        [player pause];
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
    CMTime ammount = CMTimeMake(30, 1);
    [player seekToTime:CMTimeAdd(ammount, player.currentTime)];
}

- (IBAction)skipBackTapped:(id)sender {
    CMTime ammount = CMTimeMake(7, 1);
    [player seekToTime:CMTimeSubtract(player.currentTime, ammount)];
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
@end
