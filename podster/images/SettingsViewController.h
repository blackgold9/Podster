//
//  SettingsViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UITableViewController<MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UISwitch *premiumSwitch;
- (IBAction)premiumSwitchToggled:(id)sender;
- (IBAction)purchaseTapped:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *buyButton;

@end
