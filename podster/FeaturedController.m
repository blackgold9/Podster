
//
//  FeaturedController.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeaturedController.h"
#import "ActsAsPodcast.h"
#import "PodcastGridCellView.h"
#import <QuartzCore/QuartzCore.h>
#include <stdlib.h>
#import "SVPodcastsSearchResultsViewController.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcastImageCache.h"
#import "NRGridView.h"
#import "SVPodcatcherClient.h"
#import "UIColor+Hex.h"
#import "BlockAlertView.h"
#import "SVPodcast.h"
#import "MBProgressHUD.h"
@implementation FeaturedController {
    NSArray *featured;
}
@synthesize gridView;
@synthesize featuedGrid;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        featured = [NSArray array];
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
- (void)viewDidLoad
{
    [super viewDidLoad];
//    self.featuedGrid.cellSize = DEFAULT_GRID_CELL_SIZE;
//    self.gridView.centerGrid = NO;
    UIImage *image = [UIImage imageNamed:@"background-gradient.jpg"];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:imageView];
    [self.view sendSubviewToBack:imageView];
     
    self.featuedGrid.cellSize = CGSizeMake(160, 160);
    self.featuedGrid.backgroundColor = [UIColor clearColor];
    self.featuedGrid.dataSource = self;
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    [[SVPodcatcherClient sharedInstance] featuredPodcastsForLanguage:nil
                                                        onCompletion:^(NSArray *returned) {
                                                            featured = returned;                                                                                                                                                                                 
                                                            [self.featuedGrid reloadData];
                                                                [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                        } onError:^(NSError *error) {
                                                            [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                            LOG_GENERAL(2, @"Error occured downloading featured podcasts");
                                                            BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Oh No!" message:@"There was a problem downloading the featured podcasts for today. Please try again later."];
                                                            [alert setCancelButtonWithTitle:NSLocalizedString(@"OK", @"OK button text") block:^{
                                                                
                                                            }];
                                                            [alert show];
                                                        }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.featuedGrid reloadData];
    self.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];
}
-(NSInteger)numberOfSectionsInGridView:(NRGridView *)gridView
{
    return featured.count;
}

-(NSString *)gridView:(NRGridView *)gridView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString([[featured objectAtIndex:section] valueForKey:@"name"], @"Localized header");

}

- (NSInteger)gridView:(NRGridView*)gridView numberOfItemsInSection:(NSInteger)section
{
    NSArray *podcasts = [[featured objectAtIndex:section] objectForKey:@"feeds"];
    return podcasts.count;
}

-(UIView *)gridView:(NRGridView *)grid viewForHeaderInSection:(NSInteger)section
{
    UIView *background = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 280, 50)];
    [label setFont:[UIFont boldSystemFontOfSize:17.0f]];
    label.backgroundColor = [UIColor clearColor];
    [background addSubview:label];
    label.text = [self gridView:grid titleForHeaderInSection:section];
    background.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"list-item.png"]];
    label.textColor = [UIColor whiteColor];
    return background;
}

-(NRGridViewCell *)gridView:(NRGridView *)gridView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *MyCellIdentifier = @"FeaturedCell";
    
    NRGridViewCell* cell = [self.featuedGrid dequeueReusableCellWithIdentifier:MyCellIdentifier];
    
    if(cell == nil){
        cell = [[NRGridViewCell alloc] initWithReuseIdentifier:MyCellIdentifier];

        static UINib *podcastNib = nil;
        if (podcastNib == nil) {
            podcastNib = [UINib nibWithNibName:@"PodcastGridCellView" bundle:nil];   
        }
        
        PodcastGridCellView *podCell = [[podcastNib instantiateWithOwner:nil options:nil] objectAtIndex:0]; 
        podCell.tag = 29;
        podCell.frame = CGRectOffset(podCell.frame, 5, 0);

        [cell.contentView addSubview:podCell];
        
    }

    NSDictionary *sectionDict = [featured objectAtIndex:indexPath.section];
    NSArray *feeds = [sectionDict valueForKey:@"feeds"];
    id<ActsAsPodcast> podcast = [feeds objectAtIndex:indexPath.row];
    PodcastGridCellView *gridCell = (PodcastGridCellView *) [[cell contentView] viewWithTag:29];
        [gridCell bind:podcast];
    return cell;
}



- (void)viewDidUnload
{
    self.featuedGrid = nil;
    [super viewDidUnload];
    
  //  featuredPodcasts = [NSArray array];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)gridView:(NRGridView *)theGridView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionDict = [featured objectAtIndex:indexPath.section];
        NSArray *feeds = [sectionDict valueForKey:@"feeds"];
        id<ActsAsPodcast> podcast = [feeds objectAtIndex:indexPath.row];
    SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
        controller.podcast = podcast;
    [self.navigationController pushViewController:controller animated:YES];

    [theGridView deselectCellAtIndexPath:indexPath animated:NO];

}

@end
