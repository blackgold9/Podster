//
//  SVSubscriptionGridViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"
#import "SVViewController.h"
@interface SVSubscriptionGridViewController : SVViewController<GMGridViewDataSource, GMGridViewActionDelegate, NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *noContentLabel;
@property (nonatomic, weak) IBOutlet GMGridView *gridView;
@end
