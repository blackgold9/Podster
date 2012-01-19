//
//  SVCategoryGridViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"
#import "SVViewController.h"

@interface SVCategoryGridViewController : SVViewController<GMGridViewDataSource, GMGridViewActionDelegate, UISearchBarDelegate>
@property (nonatomic, strong) IBOutlet GMGridView *gridView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;

@end
