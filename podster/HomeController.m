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

@interface HomeController ()
@property(nonatomic, strong) SVSubscriptionGridViewController *subscriptionsController;
@property(nonatomic, strong) FeaturedController *featuredController;
@property(nonatomic, strong) JMTabView *titleTabView;
@property(nonatomic, weak) UIView *currentView;
@property(nonatomic, weak) UIViewController *currentController;

- (void)configureViewControllerForScreenType:(HomePageScreenType)screenType;

- (void)configureTabView;


@end

@implementation HomeController

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
        self.currentScreen = HomePageSubscriptionsScreen;

    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.scrollView.contentOffset = CGPointMake(0, 0);

    [self configureTabView];
    [self configureViewControllerForScreenType:HomePageSubscriptionsScreen];
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateRecognized) {
            if (self.currentScreen == HomePageFeaturedScreen) {
                [self configureViewControllerForScreenType:HomePageSubscriptionsScreen];
            }
        }
    }];
    
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [self.view addGestureRecognizer:leftSwipe];
    
    [self configureViewControllerForScreenType:HomePageSubscriptionsScreen];
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateRecognized) {
            if (self.currentScreen == HomePageSubscriptionsScreen) {
                [self configureViewControllerForScreenType:HomePageFeaturedScreen];
            }
        }
    }];
    
    [self.view addGestureRecognizer:rightSwipe];

}

- (UIViewController *)controllerForScreenType:(HomePageScreenType)screenType
{
    UIViewController *output = nil;
    if (screenType == HomePageSubscriptionsScreen) {
        if (!self.subscriptionsController) {
            UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            self.subscriptionsController = (SVSubscriptionGridViewController *) [storyBoard instantiateViewControllerWithIdentifier:@"subscriptionGridController"];
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
    
    [self.titleTabView setSelectedIndex:screenType == HomePageFeaturedScreen ? 0 : 1];
    self.currentScreen = screenType;
}

#pragma mark - View lifecycle




- (void)viewDidUnload
{
    [self setScrollView:nil];
    [super viewDidUnload];
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
    [self.titleTabView addTabItemWithTitle:@"Discovery"
                                      icon:nil executeBlock:^{
        [weakSelf configureViewControllerForScreenType:HomePageFeaturedScreen];
    }];

    [self.titleTabView addTabItemWithTitle:@"Favorites"
                                      icon:nil executeBlock:^{
        [weakSelf configureViewControllerForScreenType:HomePageSubscriptionsScreen];
    }];
    [self.titleTabView setBackgroundLayer:nil];
    [self.titleTabView setItemSpacing:10];

    [self.titleTabView setSelectedIndex:1];

}
@end
