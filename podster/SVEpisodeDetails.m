//
//  SVEpisodeDetails.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVEpisodeDetails.h"
#import "SVPodcastEntry.h"
#import "SVPodcast.h"
#import "SVPlaybackManager.h"
#import "UILabel+VerticalAlign.h"
#import "DTAttributedTextView.h"
#import "NSAttributedString+HTML.h"
#import "NSString+MW_HTML.h"
@implementation SVEpisodeDetailsViewController
@synthesize titleLabel;
@synthesize listenButton;
@synthesize downloadButton;
@synthesize summaryView;
@synthesize episode;
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
-(void)bind:(SVPodcastEntry *)theEpisode
{
    self.titleLabel.text = theEpisode.title;
    LOG_GENERAL(3, @"Summary: %@", [theEpisode.summary stringWithNewLinesAsBRs]);
    NSData *stringData = [[theEpisode.summary stringWithNewLinesAsBRs] dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"1.2",NSTextSizeMultiplierDocumentOption,@"Helvetica Neue Light", DTDefaultFontFamily, nil];
    [self.summaryView setAttributedString:[NSAttributedString attributedStringWithHTML:stringData options:dictionary]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSAssert(episode, @"There should be an episode here");
    [self bind:self.episode];
    [self.titleLabel alignTop];
    
}



- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setListenButton:nil];
    [self setDownloadButton:nil];
    [self setSummaryView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)listenTapped:(id)sender {
    // Playback logic
    LOG_GENERAL(3, @"Triggering playback");
    [[SVPlaybackManager sharedInstance] playEpisode:self.episode ofPodcast:self.episode.podcast];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *controller = [storyboard instantiateViewControllerWithIdentifier:@"playback"];
    NSParameterAssert(controller);
    
    LOG_GENERAL(3, @"Navigating to player");
    [[self navigationController] pushViewController:controller animated:YES];

}

- (IBAction)downloadTapped:(id)sender {
}
@end
