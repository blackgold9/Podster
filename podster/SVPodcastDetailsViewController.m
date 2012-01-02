//
//  SVPodcastDetailsViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastDetailsViewController.h"
#import "MWFeedItem.h"
#import "MWFeedParser.h"
#import "MWFeedInfo.h"
#import "SVPodcast.h"
#import "SVGPodderClient.h"
@implementation SVPodcastDetailsViewController {
    BOOL isLoading;
    NSMutableArray *feedItems;
    MWFeedInfo *feedInfo;
    MWFeedParser *parser;
    
    
}
@synthesize titleLabel;
@synthesize descriptionLabel;
@synthesize tableView = _tableView;
@synthesize podcast;

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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


- (void)viewDidLoad
{
    [super viewDidLoad];
    self.titleLabel.text = self.podcast.title;
    self.descriptionLabel.text = self.podcast.podcastDescription;
    isLoading = YES;
    [self.tableView reloadData];
    MKNetworkOperation *op = [[SVGPodderClient sharedInstance] operationWithURLString:self.podcast.feedURL];
    [op onCompletion:^(MKNetworkOperation *completedOperation) {
        parser = [[MWFeedParser alloc] initWithFeedData:[completedOperation responseData] textEncodingName:@"NSUnicodeStringEncoding"];
        parser.delegate = self;
   
        [parser parse];
    

    } onError:^(NSError *error) {
        [UIAlertView showWithError:error];
    }];
    
    [[SVGPodderClient sharedInstance] enqueueOperation:op];

    
}

- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setDescriptionLabel:nil];
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MWFeedItem *item = [feedItems objectAtIndex:indexPath.row];


}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(isLoading) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"episodeCell"];
        MWFeedItem *item = [feedItems objectAtIndex:indexPath.row];
        cell.textLabel.text = item.title;
    }
    
    return cell;
    
}
    #pragma mark - datasource
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return isLoading ? 1 : feedItems.count;
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info
{
    feedInfo = info;
    
    
}

-(void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item
{
    if (!feedItems) {
        feedItems = [NSMutableArray array];
    }
    
    [feedItems addObject:item];
    
}

-(void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error
{
    [UIAlertView showWithError:error];
}

-(void)feedParserDidStart:(MWFeedParser *)parser
{
    NSLog(@"Feed Parsing Started");
}

-(void)feedParserDidFinish:(MWFeedParser *)parser
{
    isLoading = NO;
    [self.tableView reloadData]; 
}
@end
