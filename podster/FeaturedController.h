//
//  FeaturedController.h
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"

@interface FeaturedController : UIViewController<GMGridViewDataSource, GMGridViewActionDelegate>
@property (weak, nonatomic) IBOutlet GMGridView *gridView;

@end
