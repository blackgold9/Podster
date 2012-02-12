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
-(void)updateNowPlayingControls;
// Private Properties:
@property (retain, nonatomic) UIPanGestureRecognizer *navigationBarPanGestureRecognizer;

@end
@implementation SVViewController{
    SVPlaybackManager *localManager;
    
}
@synthesize navigationBarPanGestureRecognizer;
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

    
    
}
-(void)dealloc
{
    self.navigationBarPanGestureRecognizer = nil;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if(localManager.playbackState == kPlaybackStateStopped) {
        LOG_GENERAL(2, @"Playback is stopped. Making sure toolbar is hiden");
        [self.navigationController setToolbarHidden:YES animated:NO];
    } else {
        LOG_GENERAL(2, @"An item is playing, show the toolbar");
        [self.navigationController setToolbarHidden:NO animated:NO];
        if (localManager.currentEpisode) {

            [self updateNowPlayingControls];
        } 
    }
    [localManager addObserver:self forKeyPath:@"currentEpisode" options:NSKeyValueObservingOptionNew context:nil];
    [localManager addObserver:self forKeyPath:@"playbackState" options:NSKeyValueObservingOptionNew context:nil];
    if ([self.navigationController.parentViewController respondsToSelector:@selector(revealGesture:)] && [self.navigationController.parentViewController respondsToSelector:@selector(revealToggle:)])
	{
		// Check if a UIPanGestureRecognizer already sits atop our NavigationBar.
		if (![[self.navigationController.navigationBar gestureRecognizers] containsObject:self.navigationBarPanGestureRecognizer])
		{
			// If not, allocate one and add it.
			UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self.navigationController.parentViewController action:@selector(revealGesture:)];
			self.navigationBarPanGestureRecognizer = panGestureRecognizer;
            
			[self.navigationController.navigationBar addGestureRecognizer:self.navigationBarPanGestureRecognizer];
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
    [localManager removeObserver:self forKeyPath:@"currentEpisode"];
    [localManager removeObserver:self forKeyPath:@"playbackState"];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  
    if (object == localManager) {
        if([keyPath isEqualToString:@"currentEpisode"]) {
            if (localManager.currentEpisode != nil) {
                LOG_PLAYBACK(2, @"Current episode changed: %@", localManager.currentEpisode);
                [self updateNowPlayingControls];
            }
        } else if ([keyPath isEqualToString:@"playbackState"]){
            if(localManager.playbackState == kPlaybackStateStopped) {
                [self.navigationController setToolbarHidden:YES animated:YES];
            } else {
                [self.navigationController setToolbarHidden:NO animated:YES];
            }
        }
    }
}
-(void)showNowPlayingController
{
    UIViewController *controller = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"playback"];
    [self.navigationController pushViewController:controller animated:YES];
}


-(void)updateNowPlayingControls
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
