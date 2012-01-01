//
//  SVPlaybackController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/31/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVPlaybackController.h"
#import <AVFoundation/AVFoundation.h>
@implementation SVPlaybackController {
    AVPlayer *player;
    id playerObserver;
}
@synthesize skipForwardButton;
@synthesize skipBackButton;
@synthesize chromeViews;
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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];

    player = [AVPlayer playerWithURL:[NSURL URLWithString:@"http://localhost:5000/cheating.mp3"]];
    [player addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:(__bridge void*)self];
    playerObserver = [player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CMTime duration = player.currentItem.duration;
        NSInteger remaining = duration.value - time.value;

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
    [super viewDidUnload];
    [player removeObserver:self forKeyPath:@"status" context:(__bridge void*)self];
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
        if ([keyPath isEqualToString:@"status"]) {
            if (object == player) {
                [player play];
                NSLog(@"Started Playback");
            }
        }
    }
}
- (IBAction)playTapped:(id)sender {
}

#pragma mark - helpers
+(NSString *)formattedStringRepresentationOfSeconds:(NSInteger)totalSeconds
{
    NSInteger hourInSeconds = 3600;
    NSInteger hours = totalSeconds / hourInSeconds;
    NSInteger minutes = (totalSeconds % hourInSeconds) / 60;
    NSInteger seconds = totalSeconds % 60;
    return [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes,seconds];
}
@end
