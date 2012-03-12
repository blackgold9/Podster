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
        
        NSString *versionNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        if ([[SVSettings sharedInstance] premiumMode]) {
            // Append a p if it's premium
            versionNumber = [NSString stringWithFormat:@"%@P", versionNumber];
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
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"honeycomb.png"]];
    [self.view addSubview:image];
    [self.view sendSubviewToBack:image];
    self.tableView.backgroundColor = [UIColor clearColor];
    [self.buyButton  setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    [self.buyButton setBackgroundImage:[UIImage imageNamed:@"standard-big.png"] forState:UIControlStateNormal  ];
    [self.buyButton setBackgroundImage:[UIImage imageNamed:@"standard-big-over.png"] forState:UIControlStateHighlighted];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
        if (indexPath.row == 1) {
            // Tapped contact us
            [self contactUsTapped];
        }                      
    } else if (indexPath.section == 0) {
        [self showPurchaseOptions];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
		
}


#pragma mark - Table view data source
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


- (NSString *)nameForProductIdentifier:(NSString *)identifier
{
    if ([identifier isEqualToString:@"net.vanterpool.podster.premium1month"]) {
        return NSLocalizedString(@"ONE_MONTH", @"Premium subscription for 1 month");
    } else if ([identifier isEqualToString:@"net.vanterpool.podster.premium1year"]) {
         return NSLocalizedString(@"ONE_YEAR", @"Premium subscription for 1 year");
    } else if ([identifier isEqualToString:@"net.vanterpool.podster.premium3months"]) {
        return NSLocalizedString(@"THREE_MONTHS", @"Premium subscription for 3 months");
    } else {
        return @"Invalid product ID";
    }    
}
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
                                                                   
                                                                   BlockActionSheet *sheet = [BlockActionSheet sheetWithTitle:@"Enable Premium Experience?"];
                                                                   NSArray *products = [[PodsterIAPHelper sharedInstance] products];
                                                                   
                                                                   NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
                                                                   [numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
                                                                   [numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
                                                                   BOOL hasProducts = NO;
                                                                   for (SKProduct *product in products) {
                                                                       hasProducts = YES;
                                                                       NSString *name = [self nameForProductIdentifier:product.productIdentifier];
                                                                       [numberFormatter setLocale:product.priceLocale];
                                                                       NSString *price = [numberFormatter stringFromNumber:product.price];
                                                                       
                                                                       [sheet addButtonWithTitle:[NSString stringWithFormat:@"%@ - %@", name, price]
                                                                                           block:^{
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

- (IBAction)purchaseTapped:(id)sender {
    [self showPurchaseOptions];      
}
@end
