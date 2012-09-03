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
#import "SVPodcast.h"
#import "PodsterIAPHelper.h"
#import "BlockAlertView.h"
#import "SVPodcastDetailsViewController.h"

static const int ddLogLevel = LOG_LEVEL_INFO;
static NSString *const kIsBusyKey = @"isBusy";

@interface HomeController ()
@property(nonatomic, strong) SVSubscriptionGridViewController *subscriptionsController;
@property(nonatomic, strong) FeaturedController *featuredController;
@property(nonatomic, strong) JMTabView *titleTabView;
@property(nonatomic, weak) UIView *currentView;
@property(nonatomic, weak) UIViewController *currentController;
@property (nonatomic, strong) UIPageViewController *pageView;


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
    [[NSNotificationCenter defaultCenter] addObserverForName:@"RecievedPodcastNotification"
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      NSNumber *feedId = [[note userInfo] objectForKey:@"feedId"];
                                                      NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.podstoreId, feedId];
                                                      SVPodcast *podcast = [SVPodcast MR_findFirstWithPredicate:predicate
                                                                                                      inContext:[NSManagedObjectContext MR_defaultContext]];
                                                      if (podcast) {
                                                          NSDictionary *params = [NSDictionary dictionaryWithObject:podcast.title
                                                                                                             forKey:@"Title"];
                                                          [Flurry logEvent:@"LaunchedFromNotification"
                                                                     withParameters:params];
                                                          
                                                          SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
                                                          NSAssert(controller, @"Controller should not be nil");
                                                          NSAssert([controller class] == [SVPodcastDetailsViewController class], @"Controller shouldbe the correct class");
                                                          controller.podcast = podcast;
                                                          controller.context = [NSManagedObjectContext MR_defaultContext];
                                                          [self.navigationController pushViewController:controller animated:YES];
                                                      }

                                                  }];
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-gradient.jpg"]];


    [self configureToolbar:NO];


        
        [self configureTabView];
        self.scrollView.contentOffset = CGPointMake(0, 0);

    [self.titleTabView setSelectedIndex:0];


    notificationView = [[GCDiscreetNotificationView alloc] initWithText:NSLocalizedString(@"Updating Podcasts", @"Updating Podcasts")
                                                           showActivity:YES
                                                     inPresentationMode:GCDiscreetNotificationViewPresentationModeBottom
                                                                 inView:self.view];
    self.pageView = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                    navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                  options:nil];
    [self.pageView setViewControllers:@[[self featuredController]] direction:UIPageViewControllerNavigationDirectionForward animated:YES
                           completion:^(BOOL finished) {
    
                           }];
    [self addChildViewController:self.pageView];
    self.pageView.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.pageView.view.frame = self.view.bounds;
    self.pageView.delegate = self;
    [self.view addSubview:self.pageView.view];
    self.pageView.dataSource = self;
}

- (SVSubscriptionGridViewController *)subscriptionsController
{
    
    if (!_subscriptionsController) {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        self.subscriptionsController = (SVSubscriptionGridViewController *) [storyBoard instantiateViewControllerWithIdentifier:@"subscriptionGridController"];
        // Configure the first context
        self.subscriptionsController.context = [NSManagedObjectContext MR_defaultContext];
    }
    
    return _subscriptionsController;

}
- (FeaturedController *)featuredController
{
    if (!_featuredController) {
        UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        self.featuredController = [storyBoard instantiateViewControllerWithIdentifier:@"featuredController"];
    }
    
    return _featuredController;

}
-(UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if ([viewController class] == [FeaturedController class]) {
        return [self subscriptionsController];
           } else {
        return nil;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if ([viewController class] == [FeaturedController class]) {
        return nil;
    } else {
        return [self featuredController];
           }
}

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (completed) {
        
        [self.titleTabView setSelectedIndex:[pageViewController.viewControllers[0] class] == [FeaturedController class] ? 0 : 1];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers
{
    
    
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
    
    NSString *whatsHot = NSLocalizedString(@"WHATS_HOT", @"What's Hot");
    [self.titleTabView addTabItemWithTitle:whatsHot
                                      icon:nil executeBlock:^{
                                          
    }];

    NSString *favorites = NSLocalizedString(@"FAVORITES", @"Favorites");
    [self.titleTabView addTabItemWithTitle:favorites
                                      icon:nil executeBlock:^{

    }];
    self.titleTabView.delegate = self;
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
    } else {
        
        
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

- (void)tabView:(JMTabView *)tabView didSelectTabAtIndex:(NSUInteger)itemIndex
{
    if (itemIndex == 0 && [self.pageView.viewControllers[0] class] != [FeaturedController class]) {
        [self.pageView setViewControllers:@[[self featuredController]] direction:UIPageViewControllerNavigationDirectionReverse animated:YES completion:^(BOOL finished) {
            
        }];
    }
    
    if (itemIndex == 1 && [self.pageView.viewControllers[0] class] != [SVSubscriptionGridViewController class]) {
        [self.pageView setViewControllers:@[[self subscriptionsController]] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:^(BOOL finished) {
            
        }];
    }
}

@end
