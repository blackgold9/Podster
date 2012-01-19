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
@class DTAttributedTextView;
@interface SVEpisodeDetailsViewController : SVViewController
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *listenButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadButton;
@property (weak, nonatomic) IBOutlet DTAttributedTextView *summaryView;
- (IBAction)listenTapped:(id)sender;
- (IBAction)downloadTapped:(id)sender;
@property (strong) SVPodcastEntry *episode;
@end
