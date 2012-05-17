//
//  SettingsViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
@interface SettingsViewController : UITableViewController<MFMailComposeViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UISwitch *premiumSwitch;
- (IBAction)premiumSwitchToggled:(id)sender;
- (IBAction)purchaseTapped:(id)sender;
- (IBAction)doneTapped:(id)sender;
@property (strong, nonatomic) IBOutlet UIButton *buyButton;

@end
