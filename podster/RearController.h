//
//  RearController.h
//  podster
//
//  Created by Stephen Vanterpool on 2/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"
#import "SVViewController.h"
@interface RearController : UITableViewController<GMGridViewDataSource, GMGridViewActionDelegate>
- (IBAction)directoryTapped:(id)sender;
@property (weak, nonatomic) IBOutlet UIButton *addUrlButton;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
- (IBAction)addURLTapped:(id)sender;
- (IBAction)urlTextFieldValueChanged:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *notificationsSwitch;
- (IBAction)notificationsChanged:(id)sender;
@property (weak, nonatomic) IBOutlet GMGridView *gridView;

@end
