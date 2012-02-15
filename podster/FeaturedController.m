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
@implementation FeaturedController {
    NSArray *featuredPodcasts;
}
@synthesize gridView;

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
        featuredPodcasts = [NSArray array];
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
    self.gridView.centerGrid = NO;
    
    [[SVPodcatcherClient sharedInstance] topPodcastsStartingAtIndex: arc4random() % 100
                                                              limit:21
                                                       onCompletion:^(NSArray *podcasts) {
                                                           featuredPodcasts = podcasts;
                                                           [self.gridView reloadData];
                                                       } onError:^(NSError *error) {
                                                           LOG_GENERAL(2, @"Error occured downloading featured podcasts");
                                                           NSAssert(false, @"This should be handled");
                                                       }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.gridView reloadData];
    self.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];
}
-(NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return featuredPodcasts.count + 1;
}

-(CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return DEFAULT_GRID_CELL_SIZE;
}

-(GMGridViewCell *)GMGridView:(GMGridView *)grid cellForItemAtIndex:(NSInteger)index
{
    NSString *identifier = index == 0 ? @"DirectoryCell" : @"PodcastCell";
    CGSize cellSize = DEFAULT_GRID_CELL_SIZE;
    GMGridViewCell *cell = [grid dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        CGRect frame = CGRectMake(0, 0, cellSize.width, cellSize.height);
        if (index == 0) {            
            // Make the directory teaser
            cell = [[GMGridViewCell alloc] initWithFrame:frame];
            UIView *view = [[UIView alloc] initWithFrame:frame];
            view.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1];
            view.layer.borderColor = [[UIColor colorWithRed:0.48 green:0.48 blue:0.52  alpha:1] CGColor];
            view.layer.borderWidth = 2;
            
            UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 10,10)];
            titleLabel.textColor = [UIColor whiteColor];
            titleLabel.backgroundColor = [UIColor clearColor];
            
            titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:27];
            titleLabel.numberOfLines = 0;
            titleLabel.tag = 1907;
            titleLabel.opaque = NO;
            titleLabel.text = @"Podcast Directory";
            [view addSubview:titleLabel];
            [cell addSubview:view];

        } else {
            cell = [[PodcastGridCell alloc] initWithFrame:frame];           
        }        
    }
    
    if (index > 0) {
        // We bind the actual podcast if it isnt the first one.
        NSLog(@"Processing podcast at index %d", index);
        [((PodcastGridCell *)cell) bind:[featuredPodcasts objectAtIndex:index - 1] 
                              fadeImage:YES];
    }
    
    return cell;
}

-(void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    if (position == 0) {
       
        [self.navigationController pushViewController:[storyboard instantiateViewControllerWithIdentifier:@"categoryListView"] animated:YES];
    } else {
        id<ActsAsPodcast> podcast = (id<ActsAsPodcast>) [featuredPodcasts objectAtIndex:position - 1];
        SVPodcastDetailsViewController *destination = [storyboard instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
        destination.podcast = podcast;
        [self.navigationController pushViewController:destination animated:YES];

    }
}



- (void)viewDidUnload
{
    [self setGridView:nil];
    [super viewDidUnload];
    featuredPodcasts = [NSArray array];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
