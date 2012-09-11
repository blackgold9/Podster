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
@interface HomeController : UIViewController<UIScrollViewDelegate, JMTabViewDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource>
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIView *containedController;
@end
