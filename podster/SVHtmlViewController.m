//
//  SVHtmlViewController.m
//  podster
//
//  Created by Stephen Vanterpool on 6/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVHtmlViewController.h"
#import "SVHtmlViewer.h"

@interface SVHtmlViewController ()
@property (nonatomic, weak) SVHtmlViewer *htmlViewer;
@end

@implementation SVHtmlViewController
@synthesize htmlViewer = _htmlViewer;
@synthesize html = _html;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    id viewer = [[SVHtmlViewer alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:viewer];
    self.htmlViewer = viewer;
    NSAssert(self.html != nil, @"There should be html at this point");
    [self.htmlViewer setHtml:self.html];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [FlurryAnalytics logEvent:@"PodcastDescriptionView"];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
