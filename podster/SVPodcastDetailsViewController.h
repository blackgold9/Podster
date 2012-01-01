//
//  SVPodcastDetailsViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/25/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MWFeedParser.h"
@class SVPodcast;
@interface SVPodcastDetailsViewController : UIViewController<UITableViewDataSource,UITableViewDelegate, MWFeedParserDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong) SVPodcast *podcast;
@end
