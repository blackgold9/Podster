//
//  SVSubscriptionListViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSubscriptionListViewController.h"
#import "SVPodcastListCell.h"
#import "SVSubscription.h"
#import "SVPodcastListCell.h"
#import "ActsAsPodcast.h"
#import "SVPodcatcherClient.h"
#import "SVPodcast.h"
#import "SVPodcastDetailsViewController.h"
@implementation SVSubscriptionListViewController
{
    UINib *nib;
}
@synthesize tableView = _tableView;
@synthesize fetcher = _fetcher;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (UINib *)listNib
{
    if (!nib) {
        nib = [UINib nibWithNibName:@"SVPodcastListCell" bundle:nil];
    }
    return nib;
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
    self.fetcher.delegate  = self;
    [self.tableView reloadData];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    nib = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}
- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject 
       atIndexPath:(NSIndexPath *)indexPath 
     forChangeType:(NSFetchedResultsChangeType)type 
      newIndexPath:(NSIndexPath *)newIndexPath 
{
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        default:
            NSLog(@"Other udpate");
            break;
    }
    
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
    
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    
}
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[[self fetcher] sections] objectAtIndex:0];
    LOG_GENERAL(2, @"Displaying %d podcats",  [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    
    SVPodcastListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"podcastListCell"];
    if (!cell) {
        cell = [SVPodcastListCell cellForTableView:tableView fromNib:[self listNib]];
        cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"list-item.png"]];
    }
    
    SVSubscription *sub = [self.fetcher objectAtIndexPath:indexPath];
    SVPodcast *podcast = sub.podcast;
    [cell bind:(id<ActsAsPodcast>)podcast];
    
    
  
    return cell;
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    SVPodcast *podcast =  ((SVSubscription *)[self.fetcher objectAtIndexPath:indexPath]).podcast;
    
    SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
    controller.podcast = podcast;
    [self.navigationController pushViewController:controller animated:YES];

}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
