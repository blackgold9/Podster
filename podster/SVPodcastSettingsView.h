//
//  SVPodcastSettingsView.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "JMTabView.h"
@interface SVPodcastSettingsView : UIView
@property (weak, nonatomic) IBOutlet JMTabView *sortTabBar;
@property (weak, nonatomic) IBOutlet UISwitch *hidePlayedEpsodesSwitch;
@end
