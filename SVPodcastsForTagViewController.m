//
//  SVPodcastsForTagViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastsForTagViewController.h"
#import "SVPodcast.h"
#import "SVPodcatcherClient.h"
#import "SVPodcastDetailsViewController.h"
@implementation SVPodcastsForTagViewController {
    BOOL isLoading;
    NSArray *podcasts;
}
@synthesize category;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        podcasts = [NSArray array];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)dealloc
{
    LOG_GENERAL(4, @"Dealloc");
    
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
       
    isLoading = YES;
    self.navigationItem.title = self.category.name;
    [[SVPodcatcherClient sharedInstance] podcastsByCategory:self.category.categoryId
                                            startingAtIndex:0
                                                      limit:50
                                               onCompletion:^(NSArray *returnedPodcasts) {
                                                   podcasts = returnedPodcasts;
                                                   isLoading = NO;
                                                   [self.tableView reloadData];
                                                   
                                               } onError:^(NSError *error) {
                                                   [UIAlertView showWithError:error]; 
                                               }];
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
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
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return isLoading ? 1 : podcasts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if (isLoading) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
    } else {
        SVPodcast *podcast = [podcasts objectAtIndex:indexPath.row];
        cell = [tableView dequeueReusableCellWithIdentifier:@"PodcastCell"];
        cell.textLabel.text = podcast.title;
        cell.detailTextLabel.text = podcast.summary == nil ? @"": podcast.summary;
    }
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showPodcastDetails" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue 
                sender:(id)sender
{
    SVPodcastDetailsViewController *destination = segue.destinationViewController;
    SVPodcast *podcast = (SVPodcast *)[podcasts objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    
    destination.podcast = podcast;
}
@end
