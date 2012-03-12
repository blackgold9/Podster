//
//  FeaturedController.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FeaturedController.h"
#import "ActsAsPodcast.h"
#import "PodcastGridCell.h"
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
    SVPodcastImageCache *imageCache;
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
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"honeycomb.png"]];
    [self.view addSubview:image];
    [self.view sendSubviewToBack:image];
     
    self.featuedGrid.cellSize = DEFAULT_GRID_CELL_SIZE;
    self.featuedGrid.backgroundColor = [UIColor clearColor]; //[UIColor colorWithPatternImage:[UIImage imageNamed:@"honeycomb.png"]];
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
    return [[featured objectAtIndex:section] valueForKey:@"name"];

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
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,140,140)];
        //view.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1];
        //        view.layer.masksToBounds = NO;
        //        //view.layer.cornerRadius = 8;
        //        view.layer.shadowColor = [UIColor whiteColor].CGColor;
        //        view.layer.shadowOpacity = 0.5;
        //        view.layer.shadowOffset = CGSizeMake(0, 0);
        //        view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
        //        view.layer.shadowRadius = 3;
        view.layer.borderColor = [[UIColor colorWithRed:0.48 green:0.48 blue:0.52  alpha:1] CGColor];
        view.layer.borderWidth = 2;
        
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.colors = [NSArray arrayWithObjects:
                           (id)[[UIColor colorWithHex:0x01408C] CGColor],
                           (id)[[UIColor colorWithHex:0x052D52] CGColor],
                           nil];
        gradient.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.3], [NSNumber numberWithFloat:1], nil];
        gradient.frame = view.bounds;
                [view.layer addSublayer:gradient];
        
       
        UIImageView *backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder.png"]];
        backgroundImage.frame = view.frame;
        [view addSubview:backgroundImage];

        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 10,10)];
       titleLabel.textColor = [UIColor whiteColor];
       titleLabel.backgroundColor = [UIColor clearColor];
       
       titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:27];
       titleLabel.numberOfLines = 0;
       titleLabel.tag = 1907;
       titleLabel.opaque = NO;
        [view addSubview:titleLabel];

        UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.frame, 0, 0)];
        imageView.tag = 1906;
        [view addSubview:imageView];
        [cell.contentView addSubview:view];
        
    }
    
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:1906];
    imageView.image = nil;
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:1907];

    NSDictionary *sectionDict = [featured objectAtIndex:indexPath.section];
    NSArray *feeds = [sectionDict valueForKey:@"feeds"];
    id<ActsAsPodcast> podcast = [feeds objectAtIndex:indexPath.row];
    label.text = [podcast title];
    [imageView setImageWithURL:[NSURL URLWithString:[podcast thumbLogoURL]]
                                   placeholderImage:nil];
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

- (void)gridView:(NRGridView *)gridView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionDict = [featured objectAtIndex:indexPath.section];
        NSArray *feeds = [sectionDict valueForKey:@"feeds"];
        id<ActsAsPodcast> podcast = [feeds objectAtIndex:indexPath.row];
    SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
        controller.podcast = podcast;
    [self.navigationController pushViewController:controller animated:YES];

    [gridView deselectCellAtIndexPath:indexPath animated:NO];

}

@end
