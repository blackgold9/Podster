//
//  SVSubscriptionGridViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"
@interface SVSubscriptionGridViewController : UIViewController<GMGridViewDataSource, GMGridViewActionDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSFetchedResultsController *fetcher;
@property (nonatomic, weak) IBOutlet GMGridView *gridView;
@end
