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
#import "SVPodcast.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcatcherClient.h"
#import <QuartzCore/QuartzCore.h>
@implementation SVSubscriptionGridViewController {
    NSUInteger tappedIndex;
}
@synthesize fetcher;
@synthesize gridView = _gridView;
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

#pragma mark - View lifecycle


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma  mark - fetchedresults
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
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


@end
