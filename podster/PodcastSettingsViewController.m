//
//  PodcastSettingsViewController.m
//  podster
//
//  Created by Stephen Vanterpool on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PodcastSettingsViewController.h"
#import "SVInsetLabel.h"
#import "BlockAlertView.h"
enum SVSettingsSections {
    SVSettingsSectionsNotificationsSection = 0,
    SVSettingsSectionsSortSection,
    SVSettingsSectionsDownloadSection,
    SVSettingsSectionsCount
};

enum SVSortRows {
    SVSortRowsNewestFirst = 0,
    SVSortRowsOldestFirst,
    SVSortRowsCount
};

enum SVDownloadRows {
    SVDownloadRowsNone = 0,
    SVDownloadRowsFirstOne,
    SVDownloadRowsFirstThree,
    SVDownloadRowsCount
};

@interface PodcastSettingsViewController ()

@end

@implementation PodcastSettingsViewController
@synthesize shouldNotify = _shouldNotify;
@synthesize downloadsToKeep = _downloadsToKeep;
@synthesize sortAscending = _sortAscending;
@synthesize delegate = _delegate;

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneTapped:)];
    self.navigationItem.title = NSLocalizedString(@"Settings", @"Settings");
}
- (void)viewDidAppear:(BOOL)animated
{
    [Flurry logEvent:@"PodcastSettingsPageView"];
}
- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return SVSettingsSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    switch (section) {
        case SVSettingsSectionsDownloadSection:
            return SVDownloadRowsCount;
            break;
        case SVSettingsSectionsSortSection:
            return SVSortRowsCount;
            break;
        case SVSettingsSectionsNotificationsSection:
            return 1;
            break;
        default:
            return 1;
            break;
    };
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *output;
    switch (section) {
        case SVSettingsSectionsDownloadSection:
            output = NSLocalizedString(@"Episodes To Keep", @"Episodes To Keep");
            break;
        case SVSettingsSectionsSortSection:
            output = NSLocalizedString(@"Sort", @"Sort");
            break;
        case SVSettingsSectionsNotificationsSection:
            output = NSLocalizedString(@"Notifications", @"Notifications");
            break;
        default:
            break;
    }
    return output;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    NSString *output;
    switch (section) {
        case SVSettingsSectionsDownloadSection:
            output = NSLocalizedString(@"Podster can store episodes on your device for access offline", @"Podster can store episodes on your device for access offline");
            break;
        case SVSettingsSectionsNotificationsSection:
            output = NSLocalizedString(@"Get notified when new episodes are available", @"Get notified when new episodes are available");
            break;
        case SVSettingsSectionsSortSection:
        default:
            break;

    }
    return output;
}




- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = indexPath.section == SVSettingsSectionsNotificationsSection ? @"switchCell" : @"regularCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (indexPath.section == SVSettingsSectionsSortSection) {
        // Configure sort section
        if (indexPath.row == SVSortRowsNewestFirst) {
            cell.textLabel.text = NSLocalizedString(@"Newest First", @"Newest First");
            cell.accessoryType = !self.sortAscending ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        } else {
            cell.textLabel.text = NSLocalizedString(@"Oldest First", @"Oldest First");
            cell.accessoryType = self.sortAscending ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
    } else if (indexPath.section == SVSettingsSectionsDownloadSection) {
        // Configure download section
        switch (indexPath.row) {
            case SVDownloadRowsNone:
                cell.textLabel.text = NSLocalizedString(@"Don't Keep Any", @"Don't Keep Any");
                cell.accessoryType = self.downloadsToKeep == 0 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                break;
            case SVDownloadRowsFirstOne:
                cell.textLabel.text = NSLocalizedString(@"Next Episode", @"Next Episode");
                cell.accessoryType = self.downloadsToKeep == 1 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                break;
            case SVDownloadRowsFirstThree:
                cell.textLabel.text = NSLocalizedString(@"Next 3 Episodes", @"Next 3 Episodes");
                cell.accessoryType = self.downloadsToKeep == 3 ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                break;
            default:
                break;
        }
    } else if (indexPath.section == SVSettingsSectionsNotificationsSection) {
        if (!cell.accessoryView) {
            UISwitch *onOffSwitch = [[UISwitch alloc] init];
            [onOffSwitch addTarget:self action:@selector(notificationChanged:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = onOffSwitch;
            cell.textLabel.text = NSLocalizedString(@"Notify me", @"Notify me");
        }

        UISwitch *notifySwitch = (UISwitch *) cell.accessoryView;
        notifySwitch.on = self.shouldNotify;

    }
    
    // Configure the cell...
    
    return cell;
}

- (void)notificationChanged:(id)sender
{
    UISwitch *notificationSwitch = sender;
    if([[SVSettings sharedInstance] notificationsEnabled]){
        self.shouldNotify = notificationSwitch.on;
    }
    else
    {
        // Notifications not enabled
        BlockAlertView *alertView = [BlockAlertView alertWithTitle:NSLocalizedString(@"NOTIFICATIONS_ARE_DISABLED", @"Notifications are disabled")
                                                           message:NSLocalizedString(@"NOTIFICATIONS_DISABLED_BODY", @"Please enable notifications in settings if you would like to recieve updates when new episodes are posted.")];
        [alertView setCancelButtonWithTitle:NSLocalizedString(@"OK",nil) block:^{

        }];

        [alertView show];

        [notificationSwitch setOn:NO animated:YES];
    }

}

- (void)doneTapped:(id)sender
{
    NSAssert(self.delegate, @"Delegate should always be assigned");
    [self.delegate podcastSettingsViewControllerShouldClose:self];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case SVSettingsSectionsDownloadSection:
            switch (indexPath.row) {
                case SVDownloadRowsNone:
                    self.downloadsToKeep = 0;
                    break;
                case SVDownloadRowsFirstOne:
                    self.downloadsToKeep = 1;
                    break;
                case SVDownloadRowsFirstThree:
                    self.downloadsToKeep = 3;
                    break;
                default:
                    break;
            }

            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SVSettingsSectionsDownloadSection]
                    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case SVSettingsSectionsSortSection:
            self.sortAscending = indexPath.row == SVSortRowsOldestFirst;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SVSettingsSectionsSortSection]
                    withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        default:
            break;
    }

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
