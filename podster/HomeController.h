//
//  HomeController.h
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMTabView.h"
#import "SVViewController.h"
typedef enum {
    HomePageFeaturedScreen = 0,
    HomePageSubscriptionsScreen
    
} HomePageScreenType;
@interface HomeController : SVViewController<UIScrollViewDelegate, JMTabViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (assign) HomePageScreenType currentScreen;
@end
