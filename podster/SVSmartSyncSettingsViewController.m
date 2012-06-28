//
//  SVSmartSyncSettingsViewController.m
//  podster
//
//  Created by Stephen Vanterpool on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SVSmartSyncSettingsViewController.h"
#import "BlockAlertView.h"
@interface SVSmartSyncSettingsViewController ()

@end

@implementation SVSmartSyncSettingsViewController {
    CLLocationManager *locationManager;
    NSArray *locations;
}

- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    locationManager = [[CLLocationManager alloc] init];
    locationManager.purpose = NSLocalizedString(@"We use your location to enable smart sync to function when you change locations.", @"We use your location to enable smart sync to function when you change locations.");

    [self.tableView setEditing:YES];
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    self.navigationItem.title = @"SmartSync";

}

- (void)viewWillAppear:(BOOL)animated {
    [FlurryAnalytics logEvent:@"SmartSyncSettingsPageView"];
    [super viewWillAppear:animated];
    locations = [locationManager.monitoredRegions sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];
    [self.tableView reloadData];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return @"Sync Locations";
    }
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 1) {
        return NSLocalizedString(@"You will automatically download new episodes when you arrive at or leave these locations. This can be use a LOT of data if 3g downloads are enabled.", @"You will automatically download new episodes when you arrive at or leave these locations. This can be use a LOT of data if 3g downloads are enabled.");
    }

    return NSLocalizedString(@"Enable SmartSync to download new episodes whenever you arrive at or leave locations you define", @"Enable SmartSync to download new episodes whenever you arrive at or leave locations you define");
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    BOOL smartSyncOn = [[SVSettings sharedInstance] smartSyncEnabled] && [CLLocationManager regionMonitoringEnabled];
    // Return the number of sections.
    return smartSyncOn ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL showAdd = NO;
    if (locations.count < 3) {
        showAdd = YES;
    }
    // Return the number of rows in the section.
    return section == 0 ? 1 : (locationManager.monitoredRegions.count + (showAdd ? 1 : 0));
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;// = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"switchCell"];
        BOOL smartSyncOn = [[SVSettings sharedInstance] smartSyncEnabled] && [CLLocationManager regionMonitoringEnabled];
        UISwitch *theSwitch = (UISwitch *) [cell.contentView viewWithTag:57];
        theSwitch.on = smartSyncOn;

    } else {
        if (indexPath.row < locationManager.monitoredRegions.count) {
            cell = [tableView dequeueReusableCellWithIdentifier:@"locationCell"];
            CLRegion *region = [locations objectAtIndex:indexPath.row];
            cell.textLabel.text = [region identifier];
        } else {
            cell = [tableView dequeueReusableCellWithIdentifier:@"addCell"];
        }
    }

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCellEditingStyle style = UITableViewCellEditingStyleNone;
    if (indexPath.section == 1) {
        style = indexPath.row == locationManager.monitoredRegions.count ? UITableViewCellEditingStyleInsert : UITableViewCellEditingStyleDelete;
    }

    return style;
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {

    // Return NO if you do not want the specified item to be editable.
    return indexPath.section == 1;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {

        CLRegion *region = [[locationManager.monitoredRegions sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]]
                objectAtIndex:indexPath.row];
        [locationManager stopMonitoringForRegion:region];
        locations = [locationManager.monitoredRegions sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES]]];

        [tableView beginUpdates];
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        // We just deleted the 3rd location, so re-add the button
        if (locations.count == 2) {

            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:2 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }

        [tableView endUpdates];

    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
}

#pragma mark - Table view delegate
- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row < locations.count) {
        return nil;
    }
    
    return indexPath;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}


- (IBAction)switchValueChanged:(id)sender {
    UISwitch *theSwitch = sender;
//    BOOL smartSyncOn = [[SVSettings sharedInstance] smartSyncEnabled] && [CLLocationManager regionMonitoringEnabled];
    if (theSwitch.on) {
        if (![CLLocationManager regionMonitoringAvailable] || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusRestricted || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied ) {
            BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"We are unable to access your location", @"We are unable to access your location")
                                   message:NSLocalizedString(@"It appears that location services have been disabled for this application. Please enable it in your device's settings menu", @"It appears that location services have been disabled for this application. Please enable it in your device's settings menu")];
            [alert setCancelButtonWithTitle:NSLocalizedString(@"OK", @"OK") block:^{
                
            }];
            
            [alert show];
            

            theSwitch.on = NO;
            return;
        }

        [[SVSettings sharedInstance] setSmartSyncEnabled:YES];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else {
        [[SVSettings sharedInstance] setSmartSyncEnabled:NO];
        for (CLRegion *region in locationManager.monitoredRegions) {
            [locationManager stopMonitoringForRegion:region];
        }
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
@end
