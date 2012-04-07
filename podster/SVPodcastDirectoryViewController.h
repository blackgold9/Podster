//
//  SVTagListController.h
//  podster
//
//  Created by Vanterpool, Stephen on 12/24/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SVPodcastDirectoryViewController : UITableViewController <UISearchBarDelegate>
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

- (IBAction)cancelButtonTapped:(id)sender;
@end
