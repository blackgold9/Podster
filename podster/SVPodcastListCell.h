//
//  SVPodcastListCell.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ActsAsPodcast;
@interface SVPodcastListCell : UITableViewCell
-(void)bind:(id<ActsAsPodcast>)podcast;
+ (UINib *)nib;
+ (NSString *)nibName;

+ (NSString *)cellIdentifier;
+ (id)cellForTableView:(UITableView *)tableView fromNib:(UINib *)nib;
@property (weak) IBOutlet UILabel *titleLabel;
@property (weak) IBOutlet UILabel *summaryLabel;
@property (weak) IBOutlet UIImageView *logoImageView;
@end
