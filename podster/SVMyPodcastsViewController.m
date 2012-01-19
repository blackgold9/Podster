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
@interface SVMyPodcastsViewController ()
-(SVCategoryListViewController *)categoryListController;
-(SVCategoryGridViewController *)categoryGridController;
-(SVSubscriptionGridViewController *)subscriptionGridController;

@end
@implementation SVMyPodcastsViewController {
    NSFetchedResultsController *fetcher;
    NSInteger tappedIndex;
    JMTabView *tabView;
    NSUInteger currentMode;
    SVCategoryGridViewController *categoryGrid;
    SVCategoryListViewController *categoryListController;
    SVSubscriptionGridViewController *subscriptionGridController;
    
    UIViewController *currentController;
    BOOL showCategoryGrid;
    BOOL showSubscriptionGrid;
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
        showCategoryGrid = YES;
        showSubscriptionGrid = YES;        
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

- (UIViewController *)viewControllerForModeIndex:(NSUInteger)index
{
    UIViewController *controller = nil;
    if(index == 0) {
        // We're in category mode
        controller =  currentController == [self categoryGridController] ? [self categoryListController] : [self categoryGridController];
    } else {
        controller = [self subscriptionGridController];
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
    currentMode = 0;
    currentController =  [self viewControllerForModeIndex:currentMode];
    [self addChildViewController:currentController];
    currentController.view.frame = self.containerView.frame;
    [self.containerView addSubview:currentController.view];

    tabView = [[JMTabView alloc] initWithFrame:CGRectMake(0, 0, 150, 32)];
    self.navigationItem.titleView  = tabView;
    tabView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin |UIViewAutoresizingFlexibleRightMargin;
    [tabView addTabItemWithTitle:@"Discover" icon:nil];
    
    [tabView addTabItemWithTitle:@"Favorites" icon:nil];
    [tabView setBackgroundLayer:nil];
    [tabView setItemSpacing:10];
    tabView.delegate = self;
    [tabView setSelectedIndex:0];
    
}

-(void)tabView:(JMTabView *)tabView didSelectTabAtIndex:(NSUInteger)itemIndex
{
    currentMode = itemIndex;
    UIViewController *next = [self viewControllerForModeIndex:itemIndex];
    
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{ 
    if ([segue.identifier isEqualToString:@"showPodcast"]) {
        SVPodcastDetailsViewController *destination= segue.destinationViewController; 
        destination.podcast = ((SVSubscription *)[[self fetcher] objectAtIndexPath:[NSIndexPath indexPathForRow:tappedIndex inSection:0]]).podcast;
    }
}

- (void)viewDidUnload
{
    [self setGridView:nil];
    [self setViewModeToggleButton:nil];
    [self setContainerView:nil];
    [self setSegmentedControl:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



-(NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetcher] sections] objectAtIndex:0];
    LOG_GENERAL(2, @"Displaying %d podcats",  [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}

-(CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
   return CGSizeMake(150, 150); 
}

-(GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    SVPodcast *currentPodcast = ((SVSubscription *)[[self fetcher] objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]]).podcast;    
    CGSize size = [self GMGridView:self.gridView sizeForItemsInInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    GMGridViewCell *cell = [self.gridView dequeueReusableCell];
    
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] init];
        //        cell.deleteButtonIcon = [UIImage imageNamed:@"close_x.png"];
        //      cell.deleteButtonOffset = CGPointMake(-15, -15);
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        view.backgroundColor = [UIColor redColor];
        view.layer.masksToBounds = NO;
       //view.layer.cornerRadius = 8;
        view.layer.shadowColor = [UIColor whiteColor].CGColor;
        view.layer.shadowOpacity = 0.5;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
        view.layer.shadowRadius = 3;
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.frame, 0, 0)];
        imageView.tag = 1906;
        [view addSubview:imageView];
        
        cell.contentView = view;
    }
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:1906];
    imageView.image = nil;
    NSURL *imageURL = [NSURL URLWithString: currentPodcast.logoURL];
    [[SVPodcatcherClient sharedInstance] imageAtURL:imageURL
                                       onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                                           if (url == imageURL) {
                                               CATransition *transition = [CATransition animation];
                                               
                                              
                                               [imageView.layer addAnimation:transition forKey:nil];
                                               
                                               imageView.image = fetchedImage;
                                               if (!fetchedImage) {
                                                   LOG_NETWORK(1, @"Error loading image for url: %@", url);
                                               }
                                           }
                                       }];
    return cell;
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

- (IBAction)viewModeToggleTapped:(id)sender {
    if(currentMode == 0) {
        UIViewController *nextController =[self viewControllerForModeIndex:tappedIndex];
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
        
        
    }
}
@end
