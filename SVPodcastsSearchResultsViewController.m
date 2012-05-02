//
//  SVPodcastsForTagViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastsSearchResultsViewController.h"
#import "SVPodcast.h"
#import "SVPodcatcherClient.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcastListCell.h"
#import "ActsAsPodcast.h"
#import "MBProgressHUD.h"
#import <QuartzCore/QuartzCore.h>
static const NSInteger kDefaultPageSize = 50;
@interface SVPodcastsSearchResultsViewController()
-(void)loadNextPage;
@end
@implementation SVPodcastsSearchResultsViewController {
    BOOL isLoading;
    NSMutableArray *podcasts;
    UINib *nib;
    NSInteger currentPage;
    BOOL noMoreData;
}
@synthesize category;
@synthesize searchString;
@synthesize tableView = _tableView;
-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        podcasts = [NSMutableArray array];
        noMoreData = NO;
        currentPage = NSNotFound;
    }
    
    return self;
}
- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        podcasts = [NSMutableArray array];
        noMoreData = NO;
        currentPage = NSNotFound;
    }
    
    return self;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
    LOG_GENERAL(4, @"Dealloc");

}

#pragma mark - View lifecycle
- (UINib *)listNib
{
    if (!nib) {
        nib = [UINib nibWithNibName:@"SVPodcastListCell" bundle:nil];
    }
    return nib;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.backgroundColor=[UIColor colorWithPatternImage:[UIImage imageNamed:@"CarbonFiber-1.png"]];
    [self.tableView registerNib:[self listNib] forCellReuseIdentifier:@"SVPodcastListCell"];
    self.tableView.rowHeight = 88;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    if (self.searchString) {
        [FlurryAnalytics logEvent:@"SearchResultsPageView" withParameters:[NSDictionary dictionaryWithObject:@"Search" forKey:@"Type"]];
        
    } else {
        [FlurryAnalytics logEvent:@"SearchResultsPageView" withParameters:[NSDictionary dictionaryWithObject:@"CategoryList" forKey:@"Type"]];
    }

    [self loadNextPage];
       // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
- (void)processPodcasts:(NSArray *)newPodcasts withStartIndex:(NSInteger)startIndex andPageSize:(NSInteger)pageSize
{
    if (newPodcasts.count < pageSize) {
        noMoreData = YES;
    }
    [podcasts addObjectsFromArray:newPodcasts];

    [self.tableView beginUpdates];
    NSMutableArray *indexPaths = [NSMutableArray array];
    NSUInteger returnedItemCount = newPodcasts.count;
    for(int i = 0; i<returnedItemCount; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:startIndex+ i inSection:0]];
    }
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
    
    
    // Remove the loading cell
    isLoading = NO;
    [[self tableView] deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:podcasts.count inSection:0]] 
                            withRowAnimation:UITableViewRowAnimationAutomatic];



}
-(void)loadNextPage
{
    if (currentPage == NSNotFound) {
        currentPage = 0;
    } else {
        currentPage ++;
    }
    [FlurryAnalytics logEvent:@"LoadSearchResultsPage" withParameters:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:currentPage] forKey:@"Page"]];
    isLoading = YES;
    // Insert the loading row
    [[self tableView] insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:podcasts.count inSection:0]] 
                            withRowAnimation:UITableViewRowAnimationAutomatic];
    self.navigationItem.title = NSLocalizedString(self.category.name, @"localized category name");

    NSInteger startIndex = currentPage * kDefaultPageSize;
    
    if (self.searchString) {

        self.navigationItem.title = self.searchString;
        
        LOG_GENERAL(2, @"A search string was entered");
        [[SVPodcatcherClient sharedInstance] searchForPodcastsMatchingQuery:self.searchString onCompletion:^(NSArray *returnedPodcasts) {
            [self processPodcasts:returnedPodcasts 
                   withStartIndex:startIndex 
                      andPageSize:kDefaultPageSize];
            
        }                                                           onError:^(NSError *error) {
            LOG_GENERAL(2, @"search failed with error: %@", error);
        }];
    } else {
        [[SVPodcatcherClient sharedInstance] podcastsByCategory:self.category.categoryId
                                                startingAtIndex:startIndex
                                                          limit:50
                                                   onCompletion:^(NSArray *returnedPodcasts) {
                                                       [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                       [self processPodcasts:returnedPodcasts 
                                                              withStartIndex:startIndex 
                                                                 andPageSize:kDefaultPageSize];                                          
                                                   }    onError:^(NSError *error) {
                                                       [MBProgressHUD hideHUDForView:self.view animated:YES];
                                                       //   [UIAlertView showWithError:error];
                                                   }];
    }
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
   
    if (!isLoading && scrollView.contentSize.height > scrollView.frame.size.height){
        if(!noMoreData) {        
            if(scrollView.contentSize.height - scrollView.contentOffset.y < 400) {
                [self loadNextPage];
            }
        }
    }
    
}
- (void)viewDidUnload {
    [super viewDidUnload];
    nib = nil;
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
   }

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return isLoading ? podcasts.count + 1 : podcasts.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if (isLoading && indexPath.row == podcasts.count) {
        // WE are one past the last podcast, and loading. show the indicator
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LoadingCell"];
        return cell;
    } else {   
        SVPodcastListCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SVPodcastListCell"];
       // cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"list-item-darker.png"]];
        
        id<ActsAsPodcast> podcast = [podcasts objectAtIndex:indexPath.row];
        [cell bind:podcast];
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    static UIColor *cellBackground;
    if (!cellBackground) {
        cellBackground = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"CarbonListBackground.png"]];
    }
    cell.backgroundColor = cellBackground;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [self performSegueWithIdentifier:@"showPodcastDetails" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue
                 sender:(id)sender {
    SVPodcastDetailsViewController *destination = segue.destinationViewController;
    SVPodcast *podcast = (SVPodcast *) [podcasts objectAtIndex:(NSUInteger) [self.tableView indexPathForSelectedRow].row];
    NSAssert(podcast.feedURL != nil, @"feedURL should not be nil");
    destination.podcast = podcast;
}
@end
