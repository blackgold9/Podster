//
//  SVPodcastDetailsViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWFeedParser.h"
#import "ActsAsPodcast.h"
#import "SVViewController.h"
@class SVPodcastSearchResult;
@interface SVPodcastDetailsViewController : SVViewController<UITableViewDataSource,UITableViewDelegate, NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *metadataView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
- (IBAction)infoTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *hidePlayedSwitch;
- (IBAction)hidePlayedSwitchedByUser:(id)sender;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sortSegmentedControl;
- (IBAction)sortControlTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *notifySwitch;
- (IBAction)notifySwitchChanged:(id)sender;

- (IBAction)subscribeTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *subscribeButton;
@property (weak) id<ActsAsPodcast> podcast;
@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
- (IBAction)optionsButtonTapped:(id)sender;
@end
