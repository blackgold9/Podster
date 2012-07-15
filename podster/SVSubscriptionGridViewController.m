//
//  SVSubscriptionGridViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVSubscriptionGridViewController.h"
#import "GMGridView.h"
#import "SVSubscriptionManager.h"
#import "SVPodcast.h"
#import "SVPodcastDetailsViewController.h"
#import "SVPodcatcherClient.h"
#import <QuartzCore/QuartzCore.h>
#import "UILabel+VerticalAlign.h"

#import "UIColor+Hex.h"
#import "PodsterManagedDocument.h"
#import "PodcastGridCellView.h"
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
@interface SVSubscriptionGridViewController()

@end

@implementation SVSubscriptionGridViewController {
    NSUInteger tappedIndex;
    BOOL needsReload;
    NSArray *items;
    
}
@synthesize noContentLabel;
@synthesize gridView = _gridView;
@synthesize context = _context;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        items = [NSArray array];
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - core data context
- (NSManagedObjectContext *)context {
    if (!_context) {
        _context = [PodsterManagedDocument defaultContext];
    }

    return _context;
}


#pragma mark - View lifecycle

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
   //self.fetcher.delegate = nil;
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[PodsterManagedDocument sharedInstance] performWhenReady:^{                    
        [[SVSubscriptionManager sharedInstance] refreshAllSubscriptions];
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadNotificationRecieved:)
                                                 name:@"SVReloadData" 
                                               object:nil];



        [[SVPodcatcherClient sharedInstance] addObserver:self forKeyPath:@"networkReachabilityStatus"
                                                  options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
   
        

    DDLogVerbose(@"Registering for context change notification");
    [[NSNotificationCenter defaultCenter] addObserver:self
                                          selector:@selector(contextChanged:)
                                          name:NSManagedObjectContextDidSaveNotification
                                          object:[PodsterManagedDocument defaultContext]];
}

- (void)contextChanged:(NSNotification *)notification
{
    NSSet *inserted = [[notification userInfo] valueForKey:NSInsertedObjectsKey];
    NSSet *deleted = [[notification userInfo] valueForKey:NSDeletedObjectsKey];
    NSSet *combined = [inserted setByAddingObjectsFromSet:deleted];
    if (inserted.count > 0) {
        BOOL subscriptionsChanged = NO;
        for (NSManagedObject * o in combined) {
            if ([o isKindOfClass:[SVPodcast class]]) {
                SVPodcast *podcast = (SVPodcast *) o;
                if (podcast.isSubscribedValue) {
                    subscriptionsChanged = YES;
                    break;
                }
            }
        }

        if (subscriptionsChanged) {
            [self performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
        }
    }

}

- (void)reloadNotificationRecieved:(NSNotification *)notification
{
    [self reloadData];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    LOG_GENERAL(2, @"Initializing");
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background-gradient.jpg"]];
    [self.view addSubview:image];
    [self.view sendSubviewToBack:image];
    self.gridView.backgroundColor = [UIColor clearColor];
    self.gridView.centerGrid = NO;
    self.gridView.alwaysBounceVertical = YES;
}

- (void)viewDidUnload
{
    [self setNoContentLabel:nil];
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    LOG_GENERAL(2, @"ViewWillAppear");
    self.noContentLabel.hidden = YES;
    
    
    [FlurryAnalytics logEvent:@"SubscriptionGridPageView" timed:YES];
}

- (void)reloadData
{
    dispatch_async(dispatch_get_main_queue(), ^void() {
        NSPredicate *predicate;
        if ([[SVPodcatcherClient sharedInstance] networkReachabilityStatus] == AFNetworkReachabilityStatusNotReachable) {
            predicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES && downloadCount > 0"];
        }  else {
            predicate = [NSPredicate predicateWithFormat:@"isSubscribed == YES"];
        }
                    

        
        NSFetchRequest *request = [SVPodcast MR_requestAllWithPredicate:predicate inContext:self.context];
        [request setReturnsObjectsAsFaults:NO];
        [request setIncludesSubentities:NO];
        [request setIncludesPendingChanges:YES];
        
        NSError *error;
        NSArray *newItems = [self.context executeFetchRequest:request error:&error];
        NSAssert(error == nil, @"There was an error while fetching the next unplayed item:%@", error);
        DDLogVerbose(@"Retrieved %lu items for display", newItems.count);
        self.noContentLabel.text = NSLocalizedString(@"FAVORITES_NO_CONTENT", @"Message to show when the user hasn't added any favorites yet");
        self.noContentLabel.numberOfLines = 0;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            items = [newItems sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
            DDLogVerbose(@"Displayed Items: ");
            for (SVPodcast *podcast in items) {
                DDLogVerbose(@"%@", podcast.title);
            }
            [[self gridView] reloadData];
            self.noContentLabel.hidden = items.count > 0;
        });
    });
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [FlurryAnalytics endTimedEvent:@"SubscriptionGridPageView" withParameters:nil];
   // self.fetcher.delegate = nil;
    LOG_GENERAL(2, @"WilDisappear");
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"SVReloadData"
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:[PodsterManagedDocument defaultContext]];
    
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
#pragma  mark - fetchedresults
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    
    LOG_GENERAL(2, @"Controller will changecontent");
    needsReload = NO;
    
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    
    LOG_GENERAL(2, @"Controller done changing content");
    if (needsReload) {
        LOG_GENERAL(2, @"Needs reload");
        [self.gridView reloadData];
    }
    self.noContentLabel.hidden = items.count > 0;
    
}

-(void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{

    tappedIndex = position;
    SVPodcast *podcast =  [items objectAtIndex:position];
    
    SVPodcastDetailsViewController *controller =  [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"podcastDetailsController"];
    controller.context = self.context;
    controller.podcast = podcast;
    [self.navigationController pushViewController:controller animated:YES];
    
    
    
}

#pragma mark - grid data
-(NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    LOG_GENERAL(2, @"Displaying %d podcats",  items.count);
    return [items count];
}

-(CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    return DEFAULT_GRID_CELL_SIZE;
}

-(GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index
{
    static UINib *podcastNib = nil;
    if (podcastNib == nil) {
        podcastNib = [UINib nibWithNibName:@"PodcastGridCellView" bundle:nil];   
    }
    SVPodcast *currentPodcast = (SVPodcast *)[items objectAtIndex:index];
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    GMGridViewCell *cell = (GMGridViewCell *)[gridView dequeueReusableCellWithIdentifier:@"MySubscriptionsGridCell"];
    
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        cell.reuseIdentifier = @"MySubscriptionsGridCell";
        PodcastGridCellView *newCell = [[podcastNib instantiateWithOwner:nil options:nil] objectAtIndex:0]; 
        
        cell.contentView = newCell;
        
        
    } else {
        PodcastGridCellView *podcastCell =(PodcastGridCellView *) cell.contentView ;
        [podcastCell prepareForReuse];
    }
    
    PodcastGridCellView *podcastCell =(PodcastGridCellView *) cell.contentView ;
    [podcastCell bind:currentPodcast];
    cell.clipsToBounds = YES;
    return cell;
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == [SVPodcatcherClient sharedInstance]) {
        // It's a reachability change. Reload
        [self performSelectorOnMainThread:@selector(reloadData )withObject:nil waitUntilDone:NO];
    }
}
@end
