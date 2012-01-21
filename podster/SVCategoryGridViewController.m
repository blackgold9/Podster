//
//  SVCategoryGridViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SVCategoryGridViewController.h"
#import "SVPodcatcherClient.h"
#import "SVCategory.h"
#import "SVPodcastsSearchResultsViewController.h"

@implementation SVCategoryGridViewController
{
    BOOL _loading;
    NSArray *categories;
}

@synthesize searchBar = _searchBar;
@synthesize gridView = _gridView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _loading = YES;
        categories = [NSArray array];   
    }
    
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[SVPodcatcherClient sharedInstance] categoriesInLanguage:nil onCompletion:^(NSArray *returnedPodcasts)
                                                                               {
                                                                                   categories = returnedPodcasts;
                                                                                   _loading = NO;
                                                                                   [self.gridView reloadData];

                                                                               } onError:^(NSError *error)
                                                                                                                                                           {
                                                                                              [UIAlertView showWithError:error];
                                                                                                                                                           }];

}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle


// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView {
    return _loading ? 0 : categories.count;
}

- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation {
    return DEFAULT_GRID_CELL_SIZE;
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index {
    SVCategory *category = [categories objectAtIndex:(NSUInteger) index];
    
    CGSize size = [self GMGridView:self.gridView sizeForItemsInInterfaceOrientation:UIInterfaceOrientationPortrait];
    
    GMGridViewCell *cell = [self.gridView dequeueReusableCell];
     
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] init];
        //        cell.deleteButtonIcon = [UIImage imageNamed:@"close_x.png"];
        //      cell.deleteButtonOffset = CGPointMake(-15, -15);
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        view.backgroundColor = [UIColor grayColor];
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
        CGFloat overlayHeight = 50;
        UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0, size.height - overlayHeight, size.width, overlayHeight)];
        [view addSubview:overlayView];
        overlayView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(overlayView.frame, 5, 5)];
        titleLabel.textColor = [UIColor whiteColor];
        titleLabel.backgroundColor = [UIColor clearColor];
        titleLabel.numberOfLines = 2;
        titleLabel.tag = 42;
        titleLabel.opaque = YES;
        [view addSubview:titleLabel];
        
        cell.contentView = view;
    }

    UILabel *titleLabel = (UILabel *)[cell viewWithTag:42];
    titleLabel.text = category.name;
    
    UIImageView *imageView = (UIImageView *)[cell.contentView viewWithTag:1906];
    imageView.image = nil;
    if (category.imageURL) {
        [[SVPodcatcherClient sharedInstance] imageAtURL:category.imageURL
                                           onCompletion:^(UIImage *fetchedImage, NSURL *url, BOOL isInCache) {
                                               if (url == category.imageURL) {
                                                   CATransition *transition = [CATransition animation];
                                                   
                                                   
                                                   [imageView.layer addAnimation:transition forKey:nil];
                                                   
                                                   imageView.image = fetchedImage;
                                                   if (!fetchedImage) {
                                                       LOG_NETWORK(1, @"Error loading image for url: %@", url);
                                                   }
                                               }
                                           }];
    }
    return cell;
    

}

- (void)loadView
{
    [super loadView];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bg-gunmetal.png"]];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:imageView];
                              
    self.gridView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    self.gridView.actionDelegate = self;
    self.gridView.dataSource = self;
    self.gridView.backgroundColor = [UIColor clearColor];
    self.gridView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    UISearchBar *searchbar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    searchbar.placeholder = @"Search for a specific Podcast";
    searchbar.delegate = self;
    self.gridView.gridHeaderView = searchbar;

    self.gridView.style = GMGridViewStyleSwap;
    self.gridView.itemSpacing = 10;
    [self.view addSubview:self.gridView];
    
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

-(void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
    LOG_GENERAL(2, @"USer tapped a category");
    SVPodcastsSearchResultsViewController *controller =[[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"searchResultsController"];
    
    
    controller.category = [categories objectAtIndex:position];
    [self.navigationController pushViewController:controller animated:YES];
}

-(void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    LOG_GENERAL(2, @"User tapped search");
    SVPodcastsSearchResultsViewController *controller =[[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"searchResultsController"];
    
    
    controller.searchString = searchBar.text;
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    [self.navigationController pushViewController:controller animated:YES];
}
@end
