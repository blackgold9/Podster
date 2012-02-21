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
#import <QuartzCore/QuartzCore.h>
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
    [localManager removeObserver:self forKeyPath:@"currentEpisode"];
    [localManager removeObserver:self forKeyPath:@"playbackState"];

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

        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
        imageView.layer.cornerRadius = 3;
        imageView.layer.masksToBounds = YES;
        [NSURL URLWithString:[[SVPlaybackManager sharedInstance] currentPodcast].tinyLogoURL];
        imageView.image = AFImageByScalingAndCroppingImageToSize([UIImage imageNamed:@"Thumb-Placeholder.png"], imageView.frame.size) ;

        NSURL *url =  [NSURL URLWithString:[[SVPlaybackManager sharedInstance] currentPodcast].tinyLogoURL];
            AFImageRequestOperation *imageLoadOp = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:url]
                                                                                        imageProcessingBlock:^UIImage *(UIImage *returnedImage) {
                                                                                            return AFImageByScalingAndCroppingImageToSize(returnedImage, imageView.frame.size);
                                                                                        } cacheName:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                                            imageView.image = image;
                                                                                        } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                   
                                                                                        }];
            
            [[SVPodcatcherClient sharedInstance] enqueueHTTPRequestOperation:imageLoadOp];
        __weak SVViewController *weakSelf = self;
        [imageView setUserInteractionEnabled:YES];
        [imageView whenTapped:^{
            [weakSelf showNowPlayingController];
        }];
        UIBarButtonItem *nowPlaying = [[UIBarButtonItem alloc] initWithCustomView:imageView];
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

static UIImage * AFImageByScalingAndCroppingImageToSize(UIImage *image, CGSize size) {
    if (image == nil) {
        return nil;
    } else if (CGSizeEqualToSize(image.size, size) || CGSizeEqualToSize(size, CGSizeZero)) {
        return image;
    }
    
    CGSize scaledSize = size;
	CGPoint thumbnailPoint = CGPointZero;
    
    CGFloat widthFactor = size.width / image.size.width;
    CGFloat heightFactor = size.height / image.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = image.size.width * scaleFactor;
    scaledSize.height = image.size.height * scaleFactor;
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5; 
    } else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0); 
    [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
	return newImage;
}
@end
