//
//  SVPodcastsForTagViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCategory.h"
#import "SVViewController.h"

@interface SVPodcastsSearchResultsViewController : SVViewController<UITableViewDelegate,UITableViewDataSource, UIScrollViewDelegate>
@property(strong) SVCategory *category;
@property(copy) NSString *searchString;
@property(weak) IBOutlet UITableView *tableView;
@end
