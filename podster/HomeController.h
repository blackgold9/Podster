//
//  HomeController.h
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMTabView.h"
typedef enum {
    HomePageSubscriptionsScreen = 0,
    HomePageFeaturedScreen
} HomePageScreenType;
@interface HomeController : UIViewController<UIScrollViewDelegate, JMTabViewDelegate>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (assign) HomePageScreenType currentScreen;
@end