//
//  SVMyPodcastsViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"
#import "SVViewController.h"
#import "JMTabView.h"

@interface SVMyPodcastsViewController : SVViewController<GMGridViewDataSource,JMTabViewDelegate, GMGridViewActionDelegate, NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) IBOutlet GMGridView *gridView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *viewModeToggleButton;
- (IBAction)viewModeToggleTapped:(id)sender;

@end
