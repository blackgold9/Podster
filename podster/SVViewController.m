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
// Private Properties:
@property (retain, nonatomic) UIPanGestureRecognizer *navigationBarPanGestureRecognizer;

@end
@implementation SVViewController{
    SVPlaybackManager *localManager;
    
}
@synthesize navigationBarPanGestureRecognizer;
@synthesize context = _context;

- (NSManagedObjectContext *)context {
    if (!_context) {
        _context = [NSManagedObjectContext MR_defaultContext];
    }

    return _context;
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

- (void)clearNowPlayingIcon
{
    self.navigationItem.rightBarButtonItem = nil;
}

-(void)showNowPLayingIcon
{


    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay
                                                                                             target:self
                                                                                             action:@selector(showNowPlayingController)]
                                      animated:NO];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self clearNowPlayingIcon];

    
    [localManager addObserver:self
                   forKeyPath:@"currentEpisode" 
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
                      context:nil];

    [localManager addObserver:self 
                   forKeyPath:@"playbackState" 
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial)
                      context:nil];
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
                [self showNowPLayingIcon];
            }
        } else if ([keyPath isEqualToString:@"playbackState"]){
            if(localManager.playbackState == kPlaybackStateStopped) {
                [self clearNowPlayingIcon];
            } else {
                [self showNowPLayingIcon];
            }
        }
    }
}
-(void)showNowPlayingController
{
    UIViewController *controller = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"playback"];
    [self.navigationController pushViewController:controller animated:YES];
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
