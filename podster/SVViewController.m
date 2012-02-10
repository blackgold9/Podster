//
//  SVViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVViewController.h"
#import "SVPlaybackManager.h"
#import "GCDiscreetNotificationView.h"
#import "SVSubscriptionManager.h"
@interface SVViewController() 
-(void)showNowPlayingController;
-(void)showNowPLayingButton;
@end
@implementation SVViewController{
    SVPlaybackManager *localManager;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    localManager = [SVPlaybackManager sharedInstance];
    [localManager addObserver:self forKeyPath:@"currentPodcast" options:NSKeyValueObservingOptionNew context:nil];
    
}
-(void)dealloc
{
    [localManager removeObserver:self forKeyPath:@"currentPodcast"];

}

- (void)viewDidUnload
{
    [localManager removeObserver:self forKeyPath:@"currentPodcast"];
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (localManager.currentEpisode) {
        if (self.toolbarItems.count == 0 ) {
            [self showNowPLayingButton];
        }
    }
 
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  
    if (object == localManager) {
        if([keyPath isEqualToString:@"currentPodcast"]) {
            if (self.toolbarItems.count == 0) {
                [self showNowPLayingButton];
            }
        } 
    }
}
-(void)showNowPlayingController
{
    UIViewController *controller = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"playback"];
    [self.navigationController pushViewController:controller animated:YES];
}


-(void)showNowPLayingButton
{
    SVPodcastEntry *episode = [[SVPlaybackManager sharedInstance] currentEpisode];
    if ([[SVPlaybackManager sharedInstance] currentEpisode]) {

        UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        [image setImageWithURL:[NSURL URLWithString:[[SVPlaybackManager sharedInstance] currentPodcast].tinyLogoURL]];
        __weak SVViewController *weakSelf = self;
        [image setUserInteractionEnabled:YES];
        [image whenTapped:^{
            [weakSelf showNowPlayingController];
        }];
        UIBarButtonItem *nowPlaying = [[UIBarButtonItem alloc] initWithCustomView:image];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,self.view.bounds.size.width - 60, 30)];
        label.text = episode.title;
        label.font = [UIFont systemFontOfSize:13];
        [label setUserInteractionEnabled:YES];
        [label whenTapped:^{
            [weakSelf showNowPlayingController];
        }];

        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        UIBarButtonItem *title = [[UIBarButtonItem alloc] initWithCustomView:label];
        
        [self setToolbarItems:[NSArray arrayWithObjects:nowPlaying, title,[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace handler:nil], nil]];
        
    }

}
@end
