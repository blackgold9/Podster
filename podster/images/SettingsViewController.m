//
//  SettingsViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import <StoreKit/StoreKit.h>
#import "PodsterIAPHelper.h"
#import "MBProgressHUD.h"
#import "BlockAlertView.h"
#import "BlockActionSheet.h"
static int ddLogLevel = LOG_LEVEL_INFO;
enum SettingsSections {
    SettingsSectionsPremiumSection = 0,
    SettingsSectionsDownloadsSection,
  //  SettingsSectionsSmartSyncSection,
    SettingsSectionsMiscSection,
    SettingsSectionsCount
};

enum SVPremiumLockedRows {
    SVPremiumLockedRowsTitle = 0,
    SVPremiumLockedRowsDescription,
    SVPremiumLockedRowsBuyButton,
    SVPremuimLockedRowsCount
};

enum SVPremiumUnlockedRows {
    SVPremiumUnlockedRowsTitle = 0,
    SVPremuimUnlockedRowsCount
};

enum SVDownloadsRows {
    SVDownloadsRowsAllowOn3g = 0,
    SVDownloadRowsCount
};

enum SVMiscRows {
    SVMiscRowsContactUs = 0,
    SVMiscRowsPrivacy,
    SVMiscRowsLegal,
    SVMiscRowsRestore,
#if DEBUG
    SVMiscRowsReset,
#endif
    SVMiscRowsCount
};

@interface SettingsViewController ()

@end

@implementation SettingsViewController
@synthesize cellularDownloadLabel;
@synthesize buyButton;
@synthesize premiumSwitch;

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)contactUsTapped {
    if ([MFMailComposeViewController canSendMail]) {
        [FlurryAnalytics logEvent:@"ContactUs"];
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];

        mailer.mailComposeDelegate = self;

        [mailer setSubject:NSLocalizedString(@"FEEDBACK_SUBJECT", @"Storyboard")];

        NSArray *toRecipients = [NSArray arrayWithObjects:@"support@vanterpool.net", nil];
        [mailer setToRecipients:toRecipients];

        NSDictionary *appInfo = [[NSBundle mainBundle] infoDictionary];
        NSString *versionNumber = [NSString stringWithFormat:@"%@ (%@)",
                                                             [appInfo objectForKey:@"CFBundleShortVersionString"],
                                                             [appInfo objectForKey:@"CFBundleVersion"]];

        if ([[SVSettings sharedInstance] premiumModeUnlocked]) {
            // Append a p if it's premium
            versionNumber = [NSString stringWithFormat:@"%@N", versionNumber];
        }
        NSString *emailBody = [NSString stringWithFormat:NSLocalizedString(@"FEEDBACK_BODY", @"Template for support email"), versionNumber];
        [mailer setMessageBody:emailBody isHTML:NO];

        [self presentModalViewController:mailer animated:YES];
    }
    else {
        [FlurryAnalytics logEvent:@"ContactUs-NoEmail"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't have e-mail configured"
                                                       delegate:nil cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    switch (result) {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled: you cancelled the operation and no email message was queued.");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved: you saved the email message in the drafts folder.");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail send: the email message is queued in the outbox. It is ready to send.");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail failed: the email message was not saved or queued, possibly due to an error.");
            break;
        default:
            NSLog(@"Mail not sent.");
            break;
    }

    // Remove the mail view
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.buyButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [self.buyButton setBackgroundImage:[UIImage imageNamed:@"standard-big.png"] forState:UIControlStateNormal];
    [self.buyButton setBackgroundImage:[UIImage imageNamed:@"standard-big-over.png"] forState:UIControlStateHighlighted];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlockedNotifications:) name:@"PremiumPurchased" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.navigationItem.title = NSLocalizedString(@"Settings", @"Settings");
    [FlurryAnalytics logEvent:@"SettingsPageView"];
}


- (void)viewDidUnload {
    [self setPremiumSwitch:nil];
    [self setBuyButton:nil];
    [self setCellularDownloadLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)      tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case SettingsSectionsMiscSection:
            if (indexPath.row == SVMiscRowsContactUs) {
                // Tapped contact us
                [self contactUsTapped];
            } else if (indexPath.row == SVMiscRowsPrivacy) {

                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://policy-portal.truste.com/core/privacy-policy/Stephen-Vanterpool/6bcbf001-fefc-4ea7-86e6-aee92ceb40ad"]];
            } else if (indexPath.row == SVMiscRowsLegal) {
                [self performSegueWithIdentifier:@"showLegal" sender:self];
            } else if (indexPath.row == SVMiscRowsRestore) {
                [[PodsterIAPHelper sharedInstance] restoreTransactions];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
#if DEBUG
             else if (indexPath.row == SVMiscRowsReset) {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"net.vanterpool.podster.notifications"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [tableView reloadData];
            }
#endif
            break;
        case SettingsSectionsPremiumSection:
            if (![[SVSettings sharedInstance] premiumModeUnlocked]) {
                [self showPurchaseOptions];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            break;
//        case SettingsSectionsSmartSyncSection:
//            [self smartSyncTapped];
//            break;
        default:
            break;

    }
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSInteger cellCount;
    switch (section) {
        case SettingsSectionsPremiumSection:
            if ([[SVSettings sharedInstance] premiumModeUnlocked])
                cellCount = SVPremuimUnlockedRowsCount;
            else
                cellCount = SVPremuimLockedRowsCount;
            break;
        case SettingsSectionsDownloadsSection:
            cellCount = SVDownloadRowsCount;
            break;
        case SettingsSectionsMiscSection:
            // Show the restore purchase option if we're not already premium
            cellCount = SVMiscRowsCount;
            break;
        default:
            cellCount = 1;
            break;
    }
    return cellCount;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsSectionsCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == SettingsSectionsPremiumSection && indexPath.row == SVPremiumLockedRowsDescription) {
        return 88.0;
    } else {
        return 44.0f;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *output;
    switch (section) {
        case SettingsSectionsDownloadsSection:
            output = NSLocalizedString(@"Download podcasts over your 3g connection for maximum flexibility.\n(Premium Feature)", @"Download podcasts over your 3g connection for maximum flexibility.\n(Premium Feature)");
            break;
//        case SettingsSectionsSmartSyncSection:
//            output = NSLocalizedString(@"SmartSync will automatically download new episodes when you arrive at or leave locations you specify.\n(Premium Feature)", @"SmartSync will automatically download new episodes when you arrive at or leave locations you specify.\n(Premium Feature)");
//            break;
        default:
            break;
    }

    return output;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *output;
    switch (section) {
        case SettingsSectionsPremiumSection:
            output = NSLocalizedString(@"PREMIUM_MODE", @"Premium Mode");
            break;
        case SettingsSectionsDownloadsSection:
            output = NSLocalizedString(@"Downloads", @"Downloads");
            break;
//        case SettingsSectionsSmartSyncSection:
//            output = NSLocalizedString(@"SmartSync", @"SmartSync");
//            break;
        default:
            break;
    }

    return output;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    if (indexPath.section == SettingsSectionsPremiumSection) {
        // Configure premium info section
        if ([[SVSettings sharedInstance] premiumModeUnlocked]) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"unlimitedAlertsStatusCell"];
            cell.textLabel.text = NSLocalizedString(@"PREMIUM_MODE", nil);
            cell.detailTextLabel.text = NSLocalizedString(@"Enabled", @"Enabled");
        } else {
            switch (indexPath.row) {
                case SVPremiumLockedRowsTitle:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"unlimitedAlertsStatusCell"];
                    cell.textLabel.text = NSLocalizedString(@"PREMIUM_MODE", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Disabled", @"Disabled");
                    break;
                case SVPremiumLockedRowsDescription: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"premiumDescription"];
                    UILabel *label = (UILabel *) [cell viewWithTag:1906];
                    label.text = NSLocalizedString(@"PREMIUM_MODE_DESCRIPTION", nil);
                    break;
                }
                case SVPremiumLockedRowsBuyButton:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"upgradeButton"];
                    cell.textLabel.text = NSLocalizedString(@"TAP_TO_UNLOCK", @"Tap to Unlock");
                    break;
                default:
                    break;
            }
        }
    } else if (indexPath.section == SettingsSectionsDownloadsSection) {
        switch (indexPath.row) {
            case SVDownloadsRowsAllowOn3g: {
                cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
                UISwitch *cellularSwitch = (UISwitch *) [cell.contentView viewWithTag:57];
                cellularSwitch.on = [[SVSettings sharedInstance] downloadOn3g];
                cellularDownloadLabel = (UILabel *) [cell.contentView viewWithTag:56];
                cellularDownloadLabel.text = NSLocalizedString(@"Allow On 3g", @"Allow On 3g");
                break;
            }
            default:
                break;
        }
    } else if (indexPath.section == SettingsSectionsMiscSection) {
        switch (indexPath.row) {
            case SVMiscRowsContactUs:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:@"Contact"];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.textLabel.text = NSLocalizedString(@"CONTACT_US", @"Contact Us");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case SVMiscRowsPrivacy:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"Privacy"];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = NSLocalizedString(@"PRIVACY_POLICY", @"Privacy Policy");
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                break;
            case SVMiscRowsLegal:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"Legal"];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = NSLocalizedString(@"LEGAL_INFO", @"Legal Information");
                break;
            case SVMiscRowsRestore:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"Restore"];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = NSLocalizedString(@"RESTORE_PURCHASES", @"Restore Purchases");
                break;
#if DEBUG
            case SVMiscRowsReset:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"Restore"];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = @"DEBUG: RESET PURCHASES";
                break;
#endif
            default:
                break;

        }
    }
//    } else if (indexPath.section == SettingsSectionsSmartSyncSection) {
//        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
//                                      reuseIdentifier:@"SmartSync"];
//        cell.selectionStyle = UITableViewCellSelectionStyleGray;
//        cell.textLabel.text = [[SVSettings sharedInstance] smartSyncEnabled] ? NSLocalizedString(@"Configure SmartSync", @"Configure SmartSync") : NSLocalizedString(@"Enable SmartSync", @"Enable SmartSync");
//        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//
//
//    }
    NSAssert(cell != nil, @"cell should not be nil");
    return cell;
}

#pragma mark - Table view delegate

- (IBAction)premiumSwitchToggled:(id)sender {


}

- (void)showPurchaseOptions {
#if defined (CONFIGURATION_AppStore)    
    [[PodsterIAPHelper sharedInstance] requestProducts];
    MBProgressHUD *hud = [[MBProgressHUD alloc] initWithView:self.navigationController.view];
    hud.dimBackground = YES;
    [self.navigationController.view addSubview:hud];
    [hud show:YES];
    __block id tmpObserver;
    tmpObserver= [[NSNotificationCenter defaultCenter] addObserverForName:kProductsLoadedNotification
                                                                   object:nil
                                                                    queue:[NSOperationQueue mainQueue]
                                                                 usingBlock:^(NSNotification *note) {
                                                                   [hud hide:YES];
                                                                   
                                                                   BlockActionSheet *sheet = [BlockActionSheet sheetWithTitle:NSLocalizedString(@"PURCHASE_PROMPT_TITLE", nil)];
                                                                   NSArray *products = [[PodsterIAPHelper sharedInstance] products];
                                                                   
                                                                   NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                                                                   [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                                                                   [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                                                                   BOOL hasProducts = NO;
                                                                   for (SKProduct *product in products) {
                                                                       hasProducts = YES;
                                                                       
                                                                       NSString *name = [product localizedTitle];
                                                                       [numberFormatter setLocale:product.priceLocale];
                                                                       NSString *price = [numberFormatter stringFromNumber:product.price];
                                                                       NSString *buyFormatString = NSLocalizedString(@"BUY_FORMAT_STRING", @"Format string for listing buy option");
                                                                       [sheet addButtonWithTitle:[NSString stringWithFormat:buyFormatString, name, price]
                                                                                           block:^{
                                                                                               [FlurryAnalytics logEvent:@"PurchaseTapped" withParameters:[NSDictionary dictionaryWithObject:name forKey:@"sku"]];
                                                                                               
                                                                                               [[PodsterIAPHelper sharedInstance] buyProductIdentifier:[product productIdentifier]];
                                                                                               [self waitForPurchaseCompletion];
                                                                                           }];
                                                                   }
                                                                   
                                                                   [sheet setCancelButtonWithTitle:@"Cancel" block:^{
                                                                       [FlurryAnalytics logEvent:@"CanceledPurchase"];   
                                                                   }];
                                                                   if (!hasProducts) {
                                                                       [FlurryAnalytics logEvent:@"NoProductsAvailable"];        
                                                                   }
                                                                   [FlurryAnalytics logEvent:@"ShowPurchaseOptions"];   
                                                                   [sheet showInView:self.view];
                                                                   LOG_GENERAL(2, @"Removing observer");
                                                                   [[NSNotificationCenter defaultCenter] removeObserver:tmpObserver
                                                                                                                   name:kProductsLoadedNotification
                                                                                                                 object:nil];
                                                                   
                                                               }];
    
#else
    [[PodsterIAPHelper sharedInstance] provideContent:@"net.vanterpool.podster.notifications"];
#endif
}

- (void)waitForPurchaseCompletion {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.dimBackground = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseComplete) name:kProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseComplete) name:kProductPurchaseFailedNotification object:nil];


}

- (void)purchaseComplete {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductPurchasedNotification object:nil];
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];

}

- (void)unlockedNotifications:(NSNotification *)notificaiton {
    if ([[SVSettings sharedInstance] premiumModeUnlocked]) {
        [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PremiumPurchased" object:nil];
        NSString *title = NSLocalizedString(@"THANK_YOU_REALLY", nil);
        NSString *body = NSLocalizedString(@"PURCHASE_COMPLETE_MESSAGE", nil);
        BlockAlertView *alertView = [BlockAlertView alertWithTitle:title message:body];
        [alertView setCancelButtonWithTitle:NSLocalizedString(@"OK", nil) block:^{
            [self.tableView reloadData];
        }];
        [alertView show];
    }
}

- (IBAction)purchaseTapped:(id)sender {
#if defined (CONFIGURATION_Ad_Hoc)
    [[PodsterIAPHelper sharedInstance] provideContent:@"net.vanterpool.podster.notifications"];
#else
    if ([SKPaymentQueue canMakePayments]) {
        [self showPurchaseOptions];
    } else {
        BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"PURCHASE_DISABLED_TITLE", @"Purchasing Disabled") message:NSLocalizedString(@"PURCHASE_DISABLED_BODY", @"Your device is currently unable to make purchases. Make sure they are enabled in the settings application")];
        [alert setCancelButtonWithTitle:NSLocalizedString(@"OK", nil) block:nil];
        [alert show];
    }
#endif
}

- (IBAction)doneTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)smartSyncTapped {
    if (![[SVSettings sharedInstance] premiumModeUnlocked]) {
        [FlurryAnalytics logEvent:@"HitSmartSyncUpsell"];
        BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"MAX_NOTIFICATIONS_UPDGRADE_PROMPT_TITLE", @"Unlock Premium Mode") message:@"SmartSync is a Premium Feature. Unlock it now!"];
        [alert addButtonWithTitle:@"Unlock" block:^{
            [self showPurchaseOptions];
        }];

        [alert setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
        [alert show];
    } else {
        [self performSegueWithIdentifier:@"showSmartSyncSettings" sender:self];
    }

}

- (IBAction)cellularSwitchChanged:(id)sender {
    UISwitch *theSwitch = sender;
    if (theSwitch.on && ![[SVSettings sharedInstance] premiumModeUnlocked]) {
        [FlurryAnalytics logEvent:@"HitCellularDownloadUpsell"];
        BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"MAX_NOTIFICATIONS_UPDGRADE_PROMPT_TITLE", @"Unlock Premium Mode") message:@"Downloading episodes over 3g is a premium feature. Unlock it now!"];
        [alert addButtonWithTitle:@"Unlock" block:^{
            [self showPurchaseOptions];
        }];

        [alert setCancelButtonWithTitle:NSLocalizedString(@"Cancel", nil) block:nil];
        [alert show];
        [theSwitch setOn:NO animated:YES];
    } else {

        DDLogInfo(@"User Set Allow downloads on 3g to %@", theSwitch.on ? @"ON" : @"OFF");
        [[SVSettings sharedInstance] setDownloadOn3g:theSwitch.on];
        if (theSwitch.on) {
            [FlurryAnalytics logEvent:@"AllowDownloadsOnCellular"];
        }
    }
}
@end
