//
//  SettingsViewController.m
//  podster
//
//  Created by Vanterpool, Stephen on 3/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SettingsViewController.h"
#import "BlockActionSheet.h"
#import <StoreKit/StoreKit.h>
#import "PodsterIAPHelper.h"
#import "MBProgressHUD.h"
#import "BlockAlertView.h"
@interface SettingsViewController ()

@end

@implementation SettingsViewController
@synthesize buyButton;
@synthesize premiumSwitch;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}
- (void)contactUsTapped
{
    if ([MFMailComposeViewController canSendMail])
    {
        [FlurryAnalytics logEvent:@"ContactUs"];
        MFMailComposeViewController *mailer = [[MFMailComposeViewController alloc] init];
        
        mailer.mailComposeDelegate = self;

        [mailer setSubject:NSLocalizedString(@"FEEDBACK_SUBJECT", @"Storyboard")];

        NSArray *toRecipients = [NSArray arrayWithObjects:@"support@vanterpool.net", nil];
        [mailer setToRecipients:toRecipients];
        
//        UIImage *myImage = [UIImage imageNamed:@"mobiletuts-logo.png"];
//        NSData *imageData = UIImagePNGRepresentation(myImage);
//        [mailer addAttachmentData:imageData mimeType:@"image/png" fileName:@"mobiletutsImage"]; 
        
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
    else
    {
        [FlurryAnalytics logEvent:@"ContactUs-NoEmail"];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Failure"
                                                        message:@"Your device doesn't have e-mail configured"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    switch (result)
    {
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
- (void)viewDidLoad
{
    [super viewDidLoad];
//    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"honeycomb.png"]];
//    [self.view addSubview:image];
//    [self.view sendSubviewToBack:image];
//    self.tableView.backgroundColor = [UIColor clearColor];
    [self.buyButton  setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [self.buyButton setBackgroundImage:[UIImage imageNamed:@"standard-big.png"] forState:UIControlStateNormal  ];
    [self.buyButton setBackgroundImage:[UIImage imageNamed:@"standard-big-over.png"] forState:UIControlStateHighlighted];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unlockedNotifications:) name:@"PremiumPurchased" object:nil];
                                                         // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
//    [[NSNotificationCenter defaultCenter] addObserver:self 
//                                             selector:@selector(purchaseSuccessful) 
//                                                 name:@"SVPremiumModeChanged" 
//                                               object:[SVSettings sharedInstance]];
    [FlurryAnalytics logEvent:@"SettingsPageView"];
}


- (void)viewDidUnload
{
    [self setPremiumSwitch:nil];
    [self setBuyButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            // Tapped contact us
            [self contactUsTapped];
        } else if (indexPath.row == 1) {
            
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://policy-portal.truste.com/core/privacy-policy/Stephen-Vanterpool/6bcbf001-fefc-4ea7-86e6-aee92ceb40ad"]];
        } else if (indexPath.row == 2) {
            [self performSegueWithIdentifier:@"showLegal" sender:self];
        } else if(indexPath.row == 3) {
            if ([[SVSettings sharedInstance] premiumModeUnlocked]) {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"net.vanterpool.podster.notifications"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [tableView reloadData];
            } else {
                [[PodsterIAPHelper sharedInstance] restoreTransactions];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                
                
            }
        } else if (indexPath.row == 4) {
            [TestFlight openFeedbackView];
        }
    } else if (indexPath.section == 0) {
        if(![[SVSettings sharedInstance] premiumModeUnlocked]) {
            [self showPurchaseOptions];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
		
}


#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger cellCount;
    switch (section) {
        case 0:
            if ([[SVSettings sharedInstance] premiumModeUnlocked])
                cellCount = 1;
            else
                cellCount = 3;
            break;
        case 1:
            // Show the restore purchase option if we're not already premium
#if DEBUG
            cellCount = 5;
#else
            cellCount = [[SVSettings sharedInstance] premiumModeUnlocked] ? 3 : 4;
#endif
            break;
        default:
            cellCount = 1;
            break;
    }
    return cellCount;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

    if (indexPath.section == 0 && indexPath.row == 1) {
        return 88.0;
    } else {
        return 44.0f;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *output;
    if(section == 0) {
        output = NSLocalizedString(@"PREMIUM_MODE", @"Premium Mode");
    }
    
    return output;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    if (indexPath.section == 0) {
        // Configure premium info section
        if ([[SVSettings sharedInstance] premiumModeUnlocked]) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"unlimitedAlertsStatusCell"];
            cell.textLabel.text = NSLocalizedString(@"PREMIUM_MODE", nil);
            cell.detailTextLabel.text = NSLocalizedString(@"Enabled", @"Enabled");
        } else {
            switch (indexPath.row) {
                case 0:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"unlimitedAlertsStatusCell"];
                    cell.textLabel.text = NSLocalizedString(@"PREMIUM_MODE", nil);
                    cell.detailTextLabel.text = NSLocalizedString(@"Disabled", @"Disabled");
                    break;
                case 1:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"premiumDescription"];
                    UILabel *label = (UILabel *)[cell viewWithTag:1906];
                    label.text = NSLocalizedString(@"PREMIUM_MODE_DESCRIPTION",nil);
                    break;
                }
                case 2:
                    cell = [tableView dequeueReusableCellWithIdentifier:@"upgradeButton"];
                    cell.textLabel.text = NSLocalizedString(@"TAP_TO_UNLOCK", @"Tap to Unlock");
                    break;
                default:
                    break;
            }
        }

    } else if (indexPath.section == 1) {
        switch (indexPath.row) {
            case 0:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                              reuseIdentifier:@"Contact"];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.textLabel.text = NSLocalizedString(@"CONTACT_US", @"Contact Us");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            case 1:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"Privacy"];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = NSLocalizedString(@"PRIVACY_POLICY", @"Privacy Policy");
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                break;
            case 2:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"Legal"];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = NSLocalizedString(@"LEGAL_INFO", @"Legal Information");
                break;
            case 3:
                if ([[SVSettings sharedInstance] premiumModeUnlocked]) {
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                  reuseIdentifier:@"Restore"];
                    cell.selectionStyle = UITableViewCellSelectionStyleGray;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = @"DEBUG: RESET PURCHASES";
 
                } else {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                                 reuseIdentifier:@"Restore"];
                   cell.selectionStyle = UITableViewCellSelectionStyleGray;
                   cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                   cell.textLabel.text = NSLocalizedString(@"RESTORE_PURCHASES", @"Restore Purchases");
                   break;
                }
            case 4:
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                              reuseIdentifier:@"Restore"];
                cell.selectionStyle = UITableViewCellSelectionStyleGray;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.textLabel.text = @"DEBUG: Send feedback";
            default:
            break;

        }

    }
    NSAssert(cell != nil, @"cell should not be nil");
    return cell;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (IBAction)premiumSwitchToggled:(id)sender {

   
}
-(void)showPurchaseOptions
{
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
    

}

-(void) waitForPurchaseCompletion
{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.navigationController.view animated:YES];
    hud.dimBackground = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseComplete) name:kProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseComplete) name:kProductPurchaseFailedNotification object:nil];

    
}

- (void)purchaseComplete
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductPurchaseFailedNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kProductPurchasedNotification object:nil];    
    [MBProgressHUD hideHUDForView:self.navigationController.view animated:YES];
   
}

-(void)unlockedNotifications:(NSNotification *)notificaiton
{
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
    if ([SKPaymentQueue canMakePayments]) {
        [self showPurchaseOptions];
    } else {
        BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"PURCHASE_DISABLED_TITLE", @"Purchasing Disabled") message:NSLocalizedString(@"PURCHASE_DISABLED_BODY", @"Your device is currently unable to make purchases. Make sure they are enabled in the settings application")];
        [alert setCancelButtonWithTitle:NSLocalizedString(@"OK", nil) block:nil];
        [alert show];
    }
}
@end
