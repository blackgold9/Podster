//
//  SVMyPodcastsViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"

@interface SVMyPodcastsViewController : UIViewController<GMGridViewDataSource, GMGridViewActionDelegate, NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) IBOutlet GMGridView *gridView;

@end
