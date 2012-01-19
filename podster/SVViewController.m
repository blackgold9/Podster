//
//  SVViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/23/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVViewController.h"
#import "SVPlaybackManager.h"
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

- (void)viewDidUnload
{
    [super viewDidUnload];
    [localManager removeObserver:self forKeyPath:@"currentPodcast"];
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
        } else {
            
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
    if ([[SVPlaybackManager sharedInstance] currentEpisode]) {
        UIBarButtonItem *nowPlaying = [[UIBarButtonItem alloc] initWithTitle:@"Now Playing" style:UIBarButtonItemStyleBordered target:self action:@selector(showNowPlayingController)];
        [self setToolbarItems:[NSArray arrayWithObject:nowPlaying]];
    }

}
@end
