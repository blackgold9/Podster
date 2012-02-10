//
//  RearController.m
//  podster
//
//  Created by Stephen Vanterpool on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RearController.h"
#import "GMGridViewCell.h"
#import "GMGridView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Hex.h"
#import "SVPodcast.h"
#import "GMGridViewLayoutStrategies.h"
#import "SVPodcastDetailsViewController.h"
#import "ZUUIRevealController.h"

@interface RearController () 
-(void)showController:(UIViewController *)controller;
@end
@implementation RearController
{
    NSArray *podcasts;
    BOOL loaded;
}

@synthesize gridView;
@synthesize notificationsSwitch;
@synthesize addUrlButton;
@synthesize urlTextField;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super init];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        podcasts = [NSArray array];
        loaded = NO;
    }
    return self;
}
- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)showController:(UIViewController *)controller
{
    
        ZUUIRevealController *revealController = [self.parentViewController isKindOfClass:[ZUUIRevealController class]] ? (ZUUIRevealController *)self.parentViewController : nil;
        
        //		if (![revealController.frontViewController isKindOfClass:[FrontViewController class]])
        //		{
        //			FrontViewController *frontViewController;
        //            
        //			if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        //			{
        //				frontViewController = [[FrontViewController alloc] initWithNibName:@"FrontViewController_iPhone" bundle:nil];
        //			}
        //			else
        //			{
        //				frontViewController = [[FrontViewController alloc] initWithNibName:@"FrontViewController_iPad" bundle:nil];
        //			}
        //            
        //			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:frontViewController];
        //			[frontViewController release];
        //			[revealController setFrontViewController:navigationController animated:NO];
        //			[navigationController release];
        //		}
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            UINavigationController *navController = (UINavigationController *)revealController.frontViewController;
            [navController pushViewController:controller animated:YES];
        });
        
        [revealController revealToggle:self];
        
    

}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    self.gridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutHorizontal];
    [super viewDidLoad];
        // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [self setAddUrlButton:nil];
    [self setUrlTextField:nil];
    [self setNotificationsSwitch:nil];
    [self setGridView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
-(NSMutableArray *)randomSortArray:(NSArray *)array {
    srandom(time(NULL));
    NSMutableArray *mutable = [NSMutableArray arrayWithArray:array];
    for (NSInteger x = 0; x < [array count]; x++) {
        NSInteger randInt = (arc4random() % ([array count] - x)) + x;
        [mutable exchangeObjectAtIndex:x withObjectAtIndex:randInt];
    }
    return mutable;
}
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!loaded) {
        loaded = YES;
        [[SVPodcatcherClient sharedInstance] topPodcastsStartingAtIndex:2 limit:16 onCompletion:^(NSArray *returnedPodcasts) {
            podcasts = (NSArray *)[self randomSortArray:returnedPodcasts];
            [self.gridView reloadData];
        } onError:^(NSError *error) {
            //TODO: Handle failre case when podcast dont load/offline
            LOG_NETWORK(3, @"There was an error downloading the top podcasts: %@", error);
        }];
    }

}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"dark-noise.png"]];  //[UIColor colorWithRed:0.15 green:0.15 blue:0.16 alpha:1.0];
}
- (IBAction)directoryTapped:(id)sender {
    
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    [self showController: [storyboard instantiateViewControllerWithIdentifier:@"categoryListView"]];

    
}
- (IBAction)addURLTapped:(id)sender {
}

- (IBAction)urlTextFieldValueChanged:(id)sender {
}
- (IBAction)notificationsChanged:(id)sender {
}

-(NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return podcasts.count;
}
- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return CGSizeMake(86, 86);
}

-(GMGridViewCell *)GMGridView:(GMGridView *)grid cellForItemAtIndex:(NSInteger)index
{
    SVPodcast *currentPodcast = [podcasts objectAtIndex:index];
    CGSize size = [self GMGridView:grid sizeForItemsInInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    GMGridViewCell *cell = [self.gridView dequeueReusableCell];
    
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] init];
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        view.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1];
        view.layer.borderColor = [[UIColor colorWithRed:0.48 green:0.48 blue:0.52  alpha:1] CGColor];
        view.layer.borderWidth = 2;
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.frame, 0, 0)];
        imageView.tag = 1906;
        imageView.backgroundColor = [UIColor clearColor];
        [view addSubview:imageView];
        
        cell.contentView = view;
    }
    
    UIImageView  *imageView = (UIImageView *)[cell.contentView viewWithTag:1906];
    NSString *url = [[UIScreen mainScreen] scale] == 1 ? currentPodcast.tinyLogoURL : currentPodcast.thumbLogoURL;
        NSURL *imageURL = [NSURL URLWithString: url];
    [imageView setImageWithURL:imageURL placeholderImage:nil shouldFade:YES];
       
    return cell;
   
}

-(void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    SVPodcastDetailsViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
    controller.podcast = [podcasts objectAtIndex:position];
    [self showController:controller];
}
@end
