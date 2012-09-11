//
//  SVSubscriptionGridViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVViewController.h"
#import "CoreDataController.h"
@interface SVSubscriptionGridViewController : UIViewController<CoreDataController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) IBOutlet UILabel *noContentLabel;
@property (nonatomic, weak) IBOutlet UICollectionView *gridView;

@end
