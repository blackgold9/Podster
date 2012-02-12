//
//  SVSubscriptionGridViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSubscriptionGridViewController.h"
#import "GMGridView.h"
#import "SVSubscription.h"
#import "SVSubscriptionManager.h"
#import "SVPodcast.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcatcherClient.h"
#import <QuartzCore/QuartzCore.h>
#import "UILabel+VerticalAlign.h"

#import "UIColor+Hex.h"
#import "GCDiscreetNotificationView.h"
@implementation SVSubscriptionGridViewController {
    NSUInteger tappedIndex;
    BOOL needsReload;
    GCDiscreetNotificationView *notificationView;
}
@synthesize fetcher;
@synthesize gridView = _gridView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

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
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[SVSubscriptionManager sharedInstance] refreshAllSubscriptions];
    if ([self.navigationController.parentViewController respondsToSelector:@selector(revealGesture:)] && [self.navigationController.parentViewController respondsToSelector:@selector(revealToggle:)])
	{
        
		// Check if we have a revealButton already.
		if (![self.navigationItem leftBarButtonItem])
		{
			// If not, allocate one and add it.
			UIBarButtonItem *revealButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reveal", @"Reveal") style:UIBarButtonItemStylePlain target:self.navigationController.parentViewController action:@selector(revealToggle:)];
            revealButton.image = [UIImage imageNamed:@"settings.png"];
			self.navigationItem.leftBarButtonItem = revealButton;
		}
	}
    if ([[SVSubscriptionManager sharedInstance] isBusy]) {
        [notificationView show:YES];
    }

   
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    LOG_GENERAL(2, @"Initializing");
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"subscription != nil"];
    self.fetcher = [SVPodcast fetchAllSortedBy:@"lastUpdated" 
                                     ascending:NO
                                 withPredicate:predicate
                                       groupBy:nil
                                      delegate:self];
    
    self.fetcher.delegate = self;
    self.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];//[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-gunmetal.png"]];
    notificationView = [[GCDiscreetNotificationView alloc] initWithText:@"Updating Podcasts" 
                                                           showActivity:YES 
                                                     inPresentationMode:GCDiscreetNotificationViewPresentationModeBottom
                                                                 inView:self.view];


}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    LOG_GENERAL(2, @"ViewWillAppear");
    [[SVSubscriptionManager sharedInstance] addObserver:self
                                             forKeyPath:@"isBusy"
                                                options:NSKeyValueObservingOptionNew 
                                                context:nil];
    [FlurryAnalytics logEvent:@"SubscriptionGridPageView" timed:YES];


    NSAssert(self.fetcher, @"Fetcher should exist");
    self.fetcher.delegate = self;
    NSError *error= nil;
    [self.fetcher performFetch:&error];
    NSAssert(error == nil, @"Error!");
    [self.gridView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [[SVSubscriptionManager sharedInstance] removeObserver:self
                                             forKeyPath:@"isBusy"
                                                ];

    [super viewWillDisappear:animated];
    [FlurryAnalytics endTimedEvent:@"SubscriptionGridPageView" withParameters:nil];
    self.fetcher.delegate = nil;
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma  mark - fetchedresults
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    LOG_GENERAL(2, @"Controller will changecontent");
    needsReload = NO;
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    LOG_GENERAL(2, @"Controller done changing content");
    if (needsReload) {
        LOG_GENERAL(2, @"Needs reload");
        [self.gridView reloadData];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.gridView insertObjectAtIndex:indexPath.row];
            break;
        case NSFetchedResultsChangeDelete:
            [self.gridView removeObjectAtIndex:indexPath.row];
            break;
        case NSFetchedResultsChangeMove:
            LOG_GENERAL(2, @"Updating item position");
            needsReload = YES;
            break;
        case NSFetchedResultsChangeUpdate:
            LOG_GENERAL(2, @"Refreshing item");
            [self.gridView reloadObjectAtIndex:indexPath.row]; 
        default:
            break;
    }
    
}
-(void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    tappedIndex = position;
    SVPodcast *podcast =  [fetcher objectAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]];

   SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
    controller.podcast = podcast;
    [self.navigationController pushViewController:controller animated:YES];
    
    
    
}

#pragma mark - grid data
-(NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetcher] sections] objectAtIndex:0];
    LOG_GENERAL(2, @"Displaying %d podcats",  [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}

-(CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return DEFAULT_GRID_CELL_SIZE;
}

-(GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    SVPodcast *currentPodcast = (SVPodcast *)[[self fetcher] objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];    
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    GMGridViewCell *cell = [gridView dequeueReusableCell];
    
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] init];
        //        cell.deleteButtonIcon = [UIImage imageNamed:@"close_x.png"];
        //      cell.deleteButtonOffset = CGPointMake(-15, -15);
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        view.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1];
//        view.layer.masksToBounds = NO;
//        //view.layer.cornerRadius = 8;
//        view.layer.shadowColor = [UIColor whiteColor].CGColor;
//        view.layer.shadowOpacity = 0.5;
//        view.layer.shadowOffset = CGSizeMake(0, 0);
//        view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
//        view.layer.shadowRadius = 3;
        view.layer.borderColor = [[UIColor colorWithRed:0.48 green:0.48 blue:0.52  alpha:1] CGColor];
        view.layer.borderWidth = 2;

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 10,10)];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        
        titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:27];
        titleLabel.numberOfLines = 0;
        titleLabel.tag = 1907;
        titleLabel.opaque = NO;
        [view addSubview:titleLabel];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.frame, 0, 0)];
        imageView.tag = 1906;
        imageView.backgroundColor = [UIColor clearColor];
        [view addSubview:imageView];
        
        UILabel *newCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 25, 20)];
        newCountLabel.backgroundColor = [UIColor colorWithHex:0x0066a4];
        newCountLabel.hidden = YES;
        newCountLabel.tag = 1908;
        newCountLabel.textColor =[UIColor whiteColor];
        newCountLabel.adjustsFontSizeToFitWidth = YES;
        newCountLabel.minimumFontSize = 13;
        
        newCountLabel.textAlignment = UITextAlignmentLeft;
        newCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
        
        UIImageView *countOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grid-count-overlay.png"]];
        countOverlay.tag = 1909;
        [view addSubview:countOverlay];
                               
        [view addSubview:newCountLabel];
        cell.contentView = view;
    }
    UILabel *label = (UILabel *)[cell viewWithTag:1907];
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:1906];
    label.text = currentPodcast.title;
    NSString *logoString = currentPodcast.smallLogoURL;
    if (!logoString) {
        logoString = currentPodcast.logoURL;
    }
     NSURL *imageURL = [NSURL URLWithString: currentPodcast.smallLogoURL];
    [imageView setImageWithURL:imageURL placeholderImage:nil shouldFade:YES];
    UILabel *countLabel = (UILabel *)[cell viewWithTag:1908];
    UIImageView *countOverlay = (UIImageView *)[cell viewWithTag:1909];
    if (currentPodcast.unseenEpsiodeCountValue > 0) {
        countOverlay.hidden = NO;
        countLabel.hidden = NO;
        countLabel.text = [NSString stringWithFormat:@"%d", currentPodcast.unseenEpsiodeCountValue];
    } else {
        countLabel.hidden = YES;
          countOverlay.hidden = YES;
    }
            
    return cell;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        
        if ([keyPath isEqualToString:@"isBusy"]){
            if([[SVSubscriptionManager sharedInstance] isBusy]) {
                [notificationView showAnimated]; 
            } else {
                LOG_GENERAL(2, @"Forcing reload at end");
                [notificationView hideAnimatedAfter:1.0];
            }
        }
    });
    
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
}

@end
