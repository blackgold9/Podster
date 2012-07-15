//
//  HomeController.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HomeController.h"
#import "SVSubscriptionGridViewController.h"
#import "JMTabItem.h"
#import "JMTabView.h"
#import "FeaturedController.h"
#import <QuartzCore/QuartzCore.h>
#import <CoreGraphics/CoreGraphics.h>
#import "GCDiscreetNotificationView.h"
#import "SVSubscriptionManager.h"
#import "PodsterManagedDocument.h"
#import "PodsterIAPHelper.h"
#import "BlockAlertView.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;
static NSString *const kIsBusyKey = @"isBusy";

@interface HomeController ()
@property(nonatomic, strong) SVSubscriptionGridViewController *subscriptionsController;
@property(nonatomic, strong) FeaturedController *featuredController;
@property(nonatomic, strong) JMTabView *titleTabView;
@property(nonatomic, weak) UIView *currentView;
@property(nonatomic, weak) UIViewController *currentController;

- (void)configureViewControllerForScreenType:(HomePageScreenType)screenType;

- (void)configureTabView;


@end

@implementation HomeController {
    GCDiscreetNotificationView *notificationView;
}

@synthesize scrollView = _scrollView;
@synthesize currentScreen = _currentScreen;
@synthesize subscriptionsController = _subscriptionsController;
@synthesize titleTabView = _titleTabView;
@synthesize currentView = _currentView;
@synthesize currentController = _currentController;
@synthesize featuredController = _featuredController;

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

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.currentScreen = HomePageFeaturedScreen;    
    }

    return self;
}
- (void)configureToolbar:(BOOL)animated
{
    NSMutableArray *items = [NSMutableArray array];
    [items addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gear.png"] 
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(settingsTapped:)]];
    UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [items addObject:spacer];
    [items addObject:[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"search2.png"]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(directoryButtonTapped:)]];
    
    [self setToolbarItems:items animated:animated];

}
- (void)viewDidLoad
{
    [super viewDidLoad];
//    UIImageView *placeHolder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background-gradient.jpg"]];
//    placeHolder.frame = self.view.bounds;
//    [self.view addSubview:placeHolder];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-gradient.jpg"]];


    [self configureToolbar:NO];


    [[PodsterManagedDocument sharedInstance] performWhenReady:^{
        
        [self configureTabView];
        self.scrollView.contentOffset = CGPointMake(0, 0);
        
        UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeLeft:)];
        
        leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
        
        [self.view addGestureRecognizer:leftSwipe];
        
        [self configureViewControllerForScreenType:[[SVSettings sharedInstance] homeScreen]];
        UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeRight:)];    
        [self.view addGestureRecognizer:rightSwipe];


        //   [placeHolder removeFromSuperview];


     }];

    notificationView = [[GCDiscreetNotificationView alloc] initWithText:NSLocalizedString(@"Updating Podcasts", @"Updating Podcasts")
                                                           showActivity:YES
                                                     inPresentationMode:GCDiscreetNotificationViewPresentationModeBottom
                                                                 inView:self.view];
}

- (void)directoryButtonTapped:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    [self.navigationController pushViewController:[storyboard instantiateViewControllerWithIdentifier:@"categoryListView"] animated:YES];
}

- (void)settingsTapped:(id)sender
{
    UIViewController *controller =[[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController];
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:controller 
                       animated:YES
                     completion:NULL];
}
- (void)swipeLeft:(UIGestureRecognizer *)rec
{
    if (rec.state == UIGestureRecognizerStateRecognized) {
        if (self.currentScreen == HomePageFeaturedScreen) {
            [self configureViewControllerForScreenType:HomePageSubscriptionsScreen];
        }
    }

}

- (void)swipeRight:(UIGestureRecognizer *)rec
{
    if (rec.state == UIGestureRecognizerStateRecognized) {
        if (self.currentScreen == HomePageSubscriptionsScreen) {
            [self configureViewControllerForScreenType:HomePageFeaturedScreen];
        }
    }
}

- (UIViewController *)controllerForScreenType:(HomePageScreenType)screenType
{
    UIViewController *output = nil;
    if (screenType == HomePageSubscriptionsScreen) {
        if (!self.subscriptionsController) {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            self.subscriptionsController = (SVSubscriptionGridViewController *) [storyBoard instantiateViewControllerWithIdentifier:@"subscriptionGridController"];
            // Configure the first context
            self.subscriptionsController.context = [PodsterManagedDocument defaultContext];
        }

        output = self.subscriptionsController;
    } else if (screenType == HomePageFeaturedScreen) {
        if (!self.featuredController) {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            self.featuredController = [storyBoard instantiateViewControllerWithIdentifier:@"featuredController"];
        }

        output = self.featuredController;
    }

    NSAssert(output, @"There should be a view controller returned");
    return output;
}

- (void)configureViewControllerForScreenType:(HomePageScreenType)screenType
{
    UIViewController *controller = [self controllerForScreenType:screenType];
    if (self.currentView == controller.view) {
        // Nothing to do here
        return;
    } else if (self.currentView == nil) {
        [self addChildViewController:controller];
        controller.view.frame = self.view.bounds;
        [self.view addSubview:controller.view];
        [controller didMoveToParentViewController:self];        
        self.currentController = controller;
        self.currentView = controller.view;
    } else {
        [self addChildViewController:controller];
        controller.view.frame = self.view.bounds;
        [self transitionFromViewController:self.currentController
                          toViewController:controller
                                  duration:0.33
                                   options: screenType == HomePageFeaturedScreen ?  UIViewAnimationOptionTransitionFlipFromLeft : UIViewAnimationOptionTransitionFlipFromRight
                                animations:^{}
                                completion:^(BOOL complete) {
                                    self.currentView = controller.view;
                                    [[self currentController] removeFromParentViewController];
                                    [controller didMoveToParentViewController:self];
                                    self.currentController = controller;
        }];
    }
    
    controller.view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    [self.titleTabView setSelectedIndex:screenType == HomePageFeaturedScreen ? 0 : 1];
    self.currentScreen = screenType;
    
    
    [[SVSettings sharedInstance] setHomeScreen:screenType];
}

#pragma mark - View lifecycle

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    DDLogInfo(@"HomeController:ViewDidDisappear");
    [[SVSubscriptionManager sharedInstance] removeObserver:self
                                                forKeyPath:kIsBusyKey];

}

-(void)viewDidAppear:(BOOL)animated
{
    DDLogInfo(@"HomeController:ViewDidAppear");
    [super viewDidAppear:animated];
    [[SVSubscriptionManager sharedInstance] addObserver:self
                                             forKeyPath:kIsBusyKey
                                                options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial
                                                context:NULL];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)viewDidUnload
{
    [self setScrollView:nil];
    [super viewDidUnload];
    notificationView = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)configureTabView
{
    self.titleTabView = [[JMTabView alloc] initWithFrame:CGRectMake(0, 0, 150, 32)];
    self.navigationItem.titleView = self.titleTabView;
    self.titleTabView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    
    __weak HomeController *weakSelf = self;
    NSString *whatsHot = NSLocalizedString(@"WHATS_HOT", @"What's Hot");
    [self.titleTabView addTabItemWithTitle:whatsHot
                                      icon:nil executeBlock:^{
        [weakSelf configureViewControllerForScreenType:HomePageFeaturedScreen];
    }];

    NSString *favorites = NSLocalizedString(@"FAVORITES", @"Favorites");
    [self.titleTabView addTabItemWithTitle:favorites
                                      icon:nil executeBlock:^{
        [weakSelf configureViewControllerForScreenType:HomePageSubscriptionsScreen];
    }];
    [self.titleTabView setBackgroundLayer:nil];
    [self.titleTabView setItemSpacing:10];

    [self.titleTabView setSelectedIndex:1];

}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    BOOL updating = [[SVSubscriptionManager sharedInstance] isBusy];
  
    if ([keyPath isEqualToString:kIsBusyKey]){
        
        dispatch_async(dispatch_get_main_queue(), ^{
           if (updating) {
               DDLogVerbose(@"Showing loading message");
               [self.view bringSubviewToFront:notificationView];
               [notificationView show:YES];
           } else if([notificationView isShowing]) {
               DDLogVerbose(@"Hiding loading message");
               [notificationView hideAnimatedAfter:1.0];
           }
        });
    }
 
    
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}

- (void)tabView:(JMTabView *)tabView didSelectTabAtIndex:(NSUInteger)itemIndex
{
    
}

@end
