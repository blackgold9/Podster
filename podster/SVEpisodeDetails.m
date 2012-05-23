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
#import "NSAttributedString+HTML.h"
#import "NSString+MW_HTML.h"
#import <QuartzCore/QuartzCore.h>
#import "SVDownloadManager.h"
#import <Twitter/Twitter.h>
@implementation SVEpisodeDetailsViewController {
    NSManagedObjectContext *context;
    SVPodcastEntry *episode;
}
@synthesize imageBackground;
@synthesize titleLabel;
@synthesize episode;
@synthesize markAsPlayedButton;
@synthesize webView;
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
- (void)updatePlayedToggle
{
    NSString *playedButtonText = episode.playedValue ? NSLocalizedString(@"Mark as Unplayed", @"Mark an episode as NOT having been played") : NSLocalizedString(@"Mark as Played", @"Mark an episode as having been played");
    [UIView animateWithDuration:0.33f 
                          delay:0.0f
                        options:UIViewAnimationOptionTransitionCrossDissolve
                     animations:^{
                         [self.markAsPlayedButton setTitle:playedButtonText forState:UIControlStateNormal];    
                     } completion:^(BOOL finished) {
                         
                     }];


}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [FlurryAnalytics logEvent:@"EpisodeDetailsPageView"];
    
}
-(void)bind:(SVPodcastEntry *)theEpisode
{
    self.titleLabel.text = theEpisode.title;
    self.titleLabel.numberOfLines = 0;
    CGSize titleSize = [theEpisode.title sizeWithFont:self.titleLabel.font constrainedToSize:self.titleLabel.frame.size];
    self.titleLabel.frame = CGRectMake(10, 10, titleSize.width, titleSize.height);
    self.imageBackground.layer.shadowColor = [[UIColor blackColor] CGColor];
    self.imageBackground.layer.shadowOpacity=0.5;
    
    self.imageBackground.frame = CGRectMake(0, 0, self.view.bounds.size.width, titleSize.height+20);
    
    CGRect webFrame = CGRectMake(0, CGRectGetMaxY(self.imageBackground.frame), 320, self.view.frame.size.height - CGRectGetMaxY(self.imageBackground.frame));
    self.webView.frame = webFrame;
//    NSString *bodyText = theEpisode.content ? theEpisode.content : theEpisode.summary;
//    NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:@"1.4",NSTextSizeMultiplierDocumentOption,@"Helvetica Neue Light", DTDefaultFontFamily,[UIColor whiteColor], DTDefaultTextColor,[UIColor colorWithRed:0.7 green:0.8 blue:1.0 alpha:1.0], DTDefaultLinkColor, nil];
//    self.summaryView.textDelegate = self;
//    NSAttributedString *string = [NSAttributedString attributedStringWithHTML:stringData options:dictionary];
//    [self.summaryView setAttributedString:string];
    NSString *myDescriptionHTML = [NSString stringWithFormat:@"<html> \n"
                                   "<head> \n"
                                   "<meta name = \"viewport\" content = \"width = 320,"
                                   "initial-scale = 2.3, user-scalable = no\">"
                                   "<style type=\"text/css\"> \n"
                                   "body {font-family: \"%@\"; font-size: %@; color:#fff;}\n"
                                   "img { max-width: 280;} \n"
                                   "a { color:#9af} \n"
                                   "</style> \n"
                                   "</head> \n"
                                   "<body>%@</body> \n"
                                   "</html>", @"HelveticaNeue", [NSNumber numberWithInt:15], [theEpisode.rawSummary stringWithNewLinesAsBRs]];
    [self.webView loadHTMLString:myDescriptionHTML
                         baseURL:nil];
    self.webView.delegate = self;

    context = theEpisode.managedObjectContext;
    episode = theEpisode;
        [self configureToolbar];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType; 
{
    NSURL *requestURL = [request URL]; 
    if ( ( [ [ requestURL scheme ] isEqualToString: @"http" ] || [ [ requestURL scheme ] isEqualToString: @"https" ] || [ [ requestURL scheme ] isEqualToString: @"mailto" ]) 
        && ( navigationType == UIWebViewNavigationTypeLinkClicked ) ) { 
        [FlurryAnalytics logEvent:@"UserTappedLinkFromShowNotes"];
        return ![ [ UIApplication sharedApplication ] openURL: requestURL ]; 
    }
    return YES; 
}
- (void)configureToolbar
{
    UIImage *playedStatusImage;
    if (episode.playedValue) {
        playedStatusImage = [UIImage imageNamed:@"played-toolbar.png"];
    } else {
        if (episode.positionInSecondsValue > 0) {
            playedStatusImage = [UIImage imageNamed:@"partialplay-toolbar.png"];
        } else {
            playedStatusImage = [UIImage imageNamed:@"unplayed-toolbar.png"];
        }
    }
    
    UIBarButtonItem *playedItem = [[UIBarButtonItem alloc] initWithImage:playedStatusImage
                                                                   style:UIBarButtonItemStylePlain target:self action:@selector(markAsPlayedTapped:)];
    
    UIImage *downloadImage;
    if (episode.downloadCompleteValue) {
        downloadImage = [UIImage imageNamed:@"trash-can.png"];        
    } else if (episode.download != nil) {
        // Not downloaded, but one is scheduled
        downloadImage = [UIImage imageNamed:@"cancel.png"];        
    } else {
       downloadImage = [UIImage imageNamed:@"download.png"];   
    }
//    
//    UIBarButtonItem *downloadItem = [[UIBarButtonItem alloc] initWithImage:downloadImage
//                                                                     style:UIBarButtonItemStylePlain
//                                                                    target:self
//                                                                    action:@selector(downloadTapped:)];
    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self action:@selector(shareTapped:)];
    
    UIBarButtonItem *separator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    [self setToolbarItems:[NSArray arrayWithObjects:playedItem,separator,shareItem, nil] animated:YES];
}



- (void)downloadTapped:(id)sender
{
    
}

- (void)shareTapped:(id)sender
{
    TWTweetComposeViewController *tweet = [[TWTweetComposeViewController alloc] init];
    [tweet setInitialText:[NSString stringWithFormat:@"Sharing an episode of %@ (via @ItsPodster)",     episode.podcast.title]];
    [tweet addURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.podsterapp.com/feed_items/%d",episode.podstoreIdValue]]];
    
    // Show the controller
    [self presentModalViewController:tweet animated:YES];
    
    // Called when the tweet dialog has been closed
    tweet.completionHandler = ^(TWTweetComposeViewControllerResult result) 
    {
        
        
        // Dismiss the controller
        [self dismissModalViewControllerAnimated:YES];
    };

}
- (void)viewDidLoad
{

    [super viewDidLoad];
    NSAssert(episode, @"There should be an episode here");
    //self.summaryView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    [self bind:self.episode];
    [self.titleLabel alignTop];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-gradient.jpg"]];

    
}



- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setImageBackground:nil];
    [self setMarkAsPlayedButton:nil];
    [self setWebView:nil];
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

- (IBAction)markAsPlayedTapped:(id)sender {
    [context performBlock:^{
        episode.playedValue = !episode.playedValue;  
        if (!episode.playedValue) {
            // If we are now unplayed, reset playback location
            episode.positionInSecondsValue = 0;            
        }
        
        //[episode.podcast updateNextItemDateAndDownloadIfNecessary:YES];
        [self performSelectorOnMainThread:@selector(configureToolbar) withObject:nil waitUntilDone:NO];
    }];

       
      
}
@end
