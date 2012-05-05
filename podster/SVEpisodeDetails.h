//
//  SVEpisodeDetails.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVPodcastEntry.h"
#import "SVViewController.h"

@interface SVEpisodeDetailsViewController : SVViewController<UIWebViewDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imageBackground;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
- (IBAction)listenTapped:(id)sender;
@property (strong) SVPodcastEntry *episode;
@property (weak, nonatomic) IBOutlet UIButton *markAsPlayedButton;
@property (strong, nonatomic) IBOutlet UIWebView *webView;
- (IBAction)markAsPlayedTapped:(id)sender;

@end
