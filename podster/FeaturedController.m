
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
#import "SVPodcatcherClient.h"
#import "UIColor+Hex.h"
#import "BlockAlertView.h"
#import "SVPodcast.h"
#import "MBProgressHUD.h"
static int ddLogLevel = LOG_LEVEL_VERBOSE;
@implementation FeaturedController {
    NSArray *featured;
}
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
    [self.featuedGrid registerNib:[UINib nibWithNibName:@"PodcastGridCellView" bundle:nil] forCellWithReuseIdentifier:@"PodcastCell"];
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
                                                            DDLogError( @"Error occured downloading featured podcasts");
                                                            BlockAlertView *alert = [BlockAlertView alertWithTitle:@"Oh No!" message:@"There was a problem downloading the featured podcasts for today. Please try again later."];
                                                            [alert setCancelButtonWithTitle:NSLocalizedString(@"OK", @"OK button text") block:^{
                                                                
                                                            }];
                                                            [alert show];
                                                        }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self.featuedGrid reloadData];
    // self.gridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];
}

//-(NSString *)gridView:(NRGridView *)gridView titleForHeaderInSection:(NSInteger)section
//{
//    return NSLocalizedString([[featured objectAtIndex:section] valueForKey:@"name"], @"Localized header");
//}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    NSArray *podcasts = [[featured objectAtIndex:section] objectForKey:@"feeds"];
    return podcasts.count;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return featured.count;
}
//- (NSInteger)gridView:(NRGridView*)gridView numberOfItemsInSection:(NSInteger)section
//{
//    NSArray *podcasts = [[featured objectAtIndex:section] objectForKey:@"feeds"];
//    return 0;
//}
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    PodcastGridCellView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"PodcastCell"
                                                                          forIndexPath:indexPath];
    
    NSDictionary *sectionDict = [featured objectAtIndex:indexPath.section];
    NSArray *feeds = [sectionDict valueForKey:@"feeds"];
    id<ActsAsPodcast> podcast = [feeds objectAtIndex:indexPath.row];
    
    [cell bind:podcast];
    cell.clipsToBounds = YES;
    return cell;
    
    
}

//-(UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
//{
//    UIView *background = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
//
//    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 280, 50)];
//    [label setFont:[UIFont boldSystemFontOfSize:17.0f]];
//    label.backgroundColor = [UIColor clearColor];
//    [background addSubview:label];
//    label.text = [self gridView:grid titleForHeaderInSection:section];
//    background.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"list-item.png"]];
//    label.textColor = [UIColor whiteColor];
//    return background;
//
//}

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

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionDict = [featured objectAtIndex:indexPath.section];
    NSArray *feeds = [sectionDict valueForKey:@"feeds"];
    id<ActsAsPodcast> podcast = [feeds objectAtIndex:indexPath.row];
    SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
    DDLogInfo( @"Looking up podcast in data store with Id: %@", podcast.podstoreId);
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", SVPodcastAttributes.podstoreId, podcast.podstoreId];
    NSFetchRequest *request = [SVPodcast MR_requestFirstWithPredicate:predicate];
    NSAssert(podcast.feedURL != nil, @"feedURL should not be nil");
    controller.podcastId = podcast.podstoreId;
    
    SVPodcast *coreDataPodcast = [[[NSManagedObjectContext MR_defaultContext] executeFetchRequest:request error:nil] lastObject];
    DDLogVerbose(@"Lookup complete");
    if (!coreDataPodcast) {
        DDLogInfo( @"Podcast with id %@ didn't exist, creating it", podcast.podstoreId);
        __block SVPodcast *newPodcast;
        
        [MagicalRecord saveInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
            
            
            newPodcast = [SVPodcast MR_createInContext:localContext];
            [newPodcast populateWithPodcast:podcast];

        } completion:^{
            DDLogVerbose(@"Saved newly created podcast into root context");
            int64_t delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.navigationController pushViewController:controller animated:YES];
                });

            });
            
        }];;
    } else {
        DDLogVerbose(@"updated existing podcast with new json");
        [coreDataPodcast populateWithPodcast:podcast];
        [[NSManagedObjectContext MR_defaultContext] MR_saveNestedContexts];
        [self.navigationController pushViewController:controller animated:YES];
    }
    
    
    
    
}


@end
