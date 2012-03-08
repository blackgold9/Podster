//
//  SettingsViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UISwitch *premiumSwitch;
- (IBAction)premiumSwitchToggled:(id)sender;

@end
