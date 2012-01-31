//
//  SVPodcastsForTagViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCategory.h"

@interface SVPodcastsSearchResultsViewController : UITableViewController<UIScrollViewDelegate>
@property(strong) SVCategory *category;
@property(copy) NSString *searchString;

@end
