//
//  RootController.m
//  podster
//
//  Created by Stephen Vanterpool on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RootController.h"
@implementation RootController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    self = [super initWithFrontViewController:[storyBoard instantiateViewControllerWithIdentifier:@"mainNavigationController"]
                                                                               rearViewController:[storyBoard instantiateViewControllerWithIdentifier:@"rearController"]];
    if (self) {
        self.delegate = self;
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
    UINavigationController *navController = (UINavigationController *)self.frontViewController;
    [FlurryAnalytics logAllPageViews:navController];
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
- (BOOL)revealController:(ZUUIRevealController *)revealController shouldRevealRearViewController:(UIViewController *)rearViewController
{
	return YES;
}

- (BOOL)revealController:(ZUUIRevealController *)revealController shouldHideRearViewController:(UIViewController *)rearViewController 
{
	return YES;
}

- (void)revealController:(ZUUIRevealController *)revealController willRevealRearViewController:(UIViewController *)rearViewController 
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(ZUUIRevealController *)revealController didRevealRearViewController:(UIViewController *)rearViewController
{
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    UIView *coverView = [[UIView alloc] initWithFrame:self.frontViewController.view.bounds];
    [closeButton whenTapped:^{        
        [self revealToggle:self];
        [closeButton removeFromSuperview]; 
    }];
    
    [closeButton addSubview:coverView];
    coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    [UIView animateWithDuration:0.33
                     animations:^{
                         coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5]; 
                     }];
    
}

- (void)revealController:(ZUUIRevealController *)revealController willHideRearViewController:(UIViewController *)rearViewController
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}

- (void)revealController:(ZUUIRevealController *)revealController didHideRearViewController:(UIViewController *)rearViewController 
{
	NSLog(@"%@", NSStringFromSelector(_cmd));
}


@end
