//
//  FeaturedController.h
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"
#import "NRGridViewDataSource.h"
#import "NRGridViewDelegate.h"

@interface FeaturedController : UIViewController< NRGridViewDataSource, NRGridViewDelegate>
@property (weak, nonatomic) IBOutlet GMGridView *gridView;
@property (weak, nonatomic) IBOutlet NRGridView *featuedGrid;
@end
