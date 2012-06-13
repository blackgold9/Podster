//
//  PodcastSettingsViewController.h
//  podster
//
//  Created by Stephen Vanterpool on 6/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PodcastSettingsViewController;
@protocol PodcastSettingsViewControllerDelegate
- (void)podcastSettingsViewControllerShouldClose:(PodcastSettingsViewController *)controller;
@end

@interface PodcastSettingsViewController : UITableViewController
@property (nonatomic, assign) BOOL shouldNotify;
@property (nonatomic, assign) NSUInteger downloadsToKeep;
@property (nonatomic, assign) BOOL sortAscending;
@property (nonatomic, weak) id<PodcastSettingsViewControllerDelegate> delegate;
@end
