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
@implementation SVSubscriptionGridViewController {
    NSUInteger tappedIndex;
    BOOL needsReload;
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
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    LOG_GENERAL(2, @"Initializing");
    self.fetcher.delegate = self;
    self.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];//[UIColor colorWithPatternImage:[UIImage imageNamed:@"bg-gunmetal.png"]];

}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
-(void)viewWillAppear:(BOOL)animated
{
    [FlurryAnalytics logEvent:@"SubscriptionGridPageView"];
    [super viewWillAppear:animated];
    self.fetcher.delegate = self;
    [self.fetcher performFetch:nil];
    [self.gridView reloadData];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
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
    needsReload = NO;
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    if (needsReload) {
        [self.gridView reloadData];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.gridView insertObjectAtIndex:indexPath.row withAnimation:GMGridViewItemAnimationFade];
            break;
        case NSFetchedResultsChangeDelete:
            [self.gridView removeObjectAtIndex:indexPath.row withAnimation:GMGridViewItemAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            needsReload = YES;
            break;
        case NSFetchedResultsChangeUpdate:
            [self.gridView reloadObjectAtIndex:indexPath.row withAnimation:GMGridViewItemAnimationFade]; 
        default:
            break;
    }
    
}
-(void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    tappedIndex = position;
    SVPodcast *podcast =  ((SVSubscription *)[fetcher objectAtIndexPath:[NSIndexPath indexPathForRow:position inSection:0]]).podcast;

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
    SVPodcast *currentPodcast = ((SVSubscription *)[[self fetcher] objectAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]]).podcast;    
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


@end
