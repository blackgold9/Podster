//
//  SVMyPodcastsViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVMyPodcastsViewController.h"
#import "GMGridView.h"
#import <QuartzCore/QuartzCore.h>
#import "SVPodcatcherClient.h"
#import "SVPodcast.h"
#import "SVPodcastDetailsViewController.h"
#import "SVSubscription.h"
#import "JMTabView.h"
#import "JMTabItem.h"
#import "SVCategoryGridViewController.h"
#import "SVCategoryListViewController.h"
#import "SVSubscriptionGridViewController.h"
#import "SVSubscriptionListViewController.h"
#import "SVSubscriptionManager.h"
#import "GCDiscreetNotificationView.h"
@interface SVMyPodcastsViewController ()
-(SVCategoryListViewController *)categoryListController;
-(SVCategoryGridViewController *)categoryGridController;
-(SVSubscriptionGridViewController *)subscriptionGridController;
-(SVSubscriptionListViewController *)subscriptionListController;
@end
@implementation SVMyPodcastsViewController {
    NSFetchedResultsController *fetcher;
    JMTabView *tabView;
    NSUInteger currentMode;
    SVCategoryGridViewController *categoryGrid;
    SVCategoryListViewController *categoryListController;
    SVSubscriptionGridViewController *subscriptionGridController;
    SVSubscriptionListViewController *subscriptionListController;
    UIViewController *currentController;
    BOOL showGrid;
    GCDiscreetNotificationView *notificationView;
}
@synthesize gridView;
@synthesize segmentedControl;
@synthesize containerView;
@synthesize viewModeToggleButton;
- (NSFetchedResultsController *)fetcher {
    if (!fetcher) {
        fetcher = [SVSubscription fetchAllSortedBy:@"podcast.lastUpdated" ascending:NO withPredicate:nil groupBy:nil delegate:self];
    }
    
    return fetcher;
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        showGrid = YES;
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

- (UIViewController *)viewControllerForModeIndex:(NSUInteger)index gridMode:(BOOL)gridMode
{
    UIViewController *controller = nil;
    if(index == 0) {
        // We're in category mode
        controller =  gridMode ? [self categoryGridController] :[self categoryListController];
    } else {
        controller = gridMode ? [self subscriptionGridController] : [self subscriptionListController];
    }
    return controller;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.gridView.style = GMGridViewStyleSwap;
//    self.gridView.itemSpacing = 10;
//
//
//    self.gridView.actionDelegate = self;
//    self.gridView.dataSource = self;
    showGrid =  YES;
    currentMode = 0;
    currentController =  [self viewControllerForModeIndex:currentMode gridMode:showGrid];
    self.viewModeToggleButton.image = [UIImage imageNamed:@"list-icon.png"];
    [self addChildViewController:currentController];
    currentController.view.frame = self.containerView.frame;
    [self.containerView addSubview:currentController.view];

    tabView = [[JMTabView alloc] initWithFrame:CGRectMake(0, 0, 150, 32)];
    self.navigationItem.titleView  = tabView;
    tabView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
    [tabView addTabItemWithTitle:@"Discover" icon:nil];
    
    [tabView addTabItemWithTitle:@"Favorites" icon:nil];
    [tabView setBackgroundLayer:nil];
    [tabView setItemSpacing:10];
    tabView.delegate = self;
    [tabView setSelectedIndex:currentMode];
    
    UIImage *image = showGrid ? [UIImage imageNamed:@"list-button.png"]: [UIImage imageNamed:@"grid-button.png"];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setImage:image forState:UIControlStateNormal];
    button.frame = CGRectMake(0, 0, 30, 30);
    [button addTarget:self action:@selector(viewModeToggleTapped:) forControlEvents:UIControlEventTouchUpInside];
 self.viewModeToggleButton =  [[UIBarButtonItem alloc] initWithCustomView:button];
    [self.navigationItem setRightBarButtonItem:self.viewModeToggleButton animated:YES];
    notificationView = [[GCDiscreetNotificationView alloc] initWithText:@"Updating Podcasts" 
                                                           showActivity:YES 
                                                     inPresentationMode:GCDiscreetNotificationViewPresentationModeBottom 
                                                                 inView:self.navigationController.view];
    
}

-(void)tabView:(JMTabView *)tabView didSelectTabAtIndex:(NSUInteger)itemIndex
{

    if (currentMode !=itemIndex) {
        currentMode = itemIndex;
        UIViewController *next = [self viewControllerForModeIndex:itemIndex gridMode:showGrid];
        
        [self addChildViewController:next];
        next.view.frame = self.containerView.frame;
        [currentController willMoveToParentViewController:nil];
        [self transitionFromViewController:currentController
                          toViewController:next
                                  duration:0.25
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:nil
                                completion:^(BOOL finished) {
                                    [currentController removeFromParentViewController];
                                    currentController = next;
                                }];
    }

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if ([[SVSubscriptionManager sharedInstance] isBusy]) {
     
    }
    
    [[SVSubscriptionManager sharedInstance] addObserver:self
                                             forKeyPath:@"isBusy"
                                                options:NSKeyValueObservingOptionNew context:nil];
    [notificationView show:NO];
    [notificationView setTextLabel:@"BOOGOAAAA"];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
   // [[SVSubscriptionManager sharedInstance] refreshAllSubscriptions];
    
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[SVSubscriptionManager sharedInstance] removeObserver:self forKeyPath:@"isBusy"];
}
- (void)viewDidUnload
{
    [self setGridView:nil];
    [self setViewModeToggleButton:nil];
    [self setContainerView:nil];
    [self setSegmentedControl:nil];
    [super viewDidUnload];
    categoryGrid.view = nil;
    categoryListController.view = nil;
    subscriptionGridController.view = nil;
    subscriptionListController.view = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    
}


-(SVCategoryListViewController *)categoryListController
{
    if (!categoryListController) {
        categoryListController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"categoryListView"];
    }
    
    return categoryListController;
}

-(SVCategoryGridViewController *)categoryGridController
{
    if (!categoryGrid)
    {
        categoryGrid =  [[SVCategoryGridViewController alloc] initWithNibName:nil bundle:nil];
        [self addChildViewController:categoryGrid];
    }
    
    return categoryGrid;
}

-(SVSubscriptionGridViewController *)subscriptionGridController
{
    if(!subscriptionGridController) {
        subscriptionGridController = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"subscriptionGridController"]; 
        subscriptionGridController.fetcher = [SVSubscription fetchAllSortedBy:@"podcast.lastUpdated" ascending:NO withPredicate:nil groupBy:nil delegate:self];
    }
    
    return subscriptionGridController;
}

-(SVSubscriptionListViewController *)subscriptionListController
{
    if (!subscriptionListController) {
        subscriptionListController = [[SVSubscriptionListViewController alloc] initWithNibName:@"SVSubscriptionListViewController" bundle:nil];
         subscriptionListController.fetcher = [SVSubscription fetchAllSortedBy:@"podcast.lastUpdated" ascending:NO withPredicate:nil groupBy:nil delegate:self];
    }
    
    return subscriptionListController;
}

- (IBAction)viewModeToggleTapped:(id)sender {
  //  [TestFlight passCheckpoint:@"FLIPPED_HOME_VIEW"];
    showGrid = !showGrid;
    UIViewController *nextController =[self viewControllerForModeIndex:currentMode gridMode:showGrid];
    nextController.view.frame = currentController.view.frame; 
    [currentController willMoveToParentViewController:nil];
    [self addChildViewController:nextController];
    [self transitionFromViewController:currentController
                      toViewController:nextController 
                              duration:0.5
                               options:UIViewAnimationOptionTransitionFlipFromLeft
                            animations:nil
                            completion:^(BOOL finished) {
                                [currentController removeFromParentViewController];
                                currentController = nextController;
                            }];
    [UIView transitionWithView:self.viewModeToggleButton.customView
                      duration:0.5 options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                          UIButton *button = (UIButton *)self.viewModeToggleButton.customView;
                              UIImage *image = showGrid ? [UIImage imageNamed:@"list-button.png"]: [UIImage imageNamed:@"grid-button.png"];
                          [button setImage:image forState:UIControlStateNormal];
                      }
                    completion:^(BOOL finished) {
                        
                    }];
        
        
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

//        if ([keyPath isEqualToString:@"isBusy"]){
//            if([[SVSubscriptionManager sharedInstance] isBusy]) {
//                [notificationView showAnimated]; 
//            } else {
//                [notificationView hideAnimated];
//            }
//        }
   
}
@end
