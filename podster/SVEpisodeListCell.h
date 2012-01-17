//
//  SVEpisodeListCell.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class SVPodcastEntry;
@interface SVEpisodeListCell : UITableViewCell
@property (weak) IBOutlet UILabel *titleLabel;
@property (weak) IBOutlet UILabel *subtitleLabel;
@property (weak) IBOutlet UILabel *durationLabel;
@property (weak) IBOutlet UIImageView *downloadedIndicator;
-(void)bind:(SVPodcastEntry *)entry;
@end
