//
//  SettingsViewController.h
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "SVCustomGroupedTableViewController.h"

@interface SettingsViewController : SVCustomGroupedTableViewController <MFMailComposeViewControllerDelegate>
@property(strong, nonatomic) IBOutlet UISwitch *premiumSwitch;

- (IBAction)premiumSwitchToggled:(id)sender;

- (IBAction)purchaseTapped:(id)sender;

- (IBAction)doneTapped:(id)sender;

@property(strong, nonatomic) IBOutlet UIButton *buyButton;

- (IBAction)cellularSwitchChanged:(id)sender;

@property(weak, nonatomic) IBOutlet UILabel *cellularDownloadLabel;

@end
