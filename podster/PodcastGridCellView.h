//
//  PodcastGridCellView.h
//  podster
//
//  Created by Vanterpool, Stephen on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol ActsAsPodcast;
@interface PodcastGridCellView : UIView
@property (strong, nonatomic) IBOutlet UIView *progressBackground;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;

@property (strong, nonatomic) IBOutlet UIImageView *podcastArtImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *downloadCountLabel;
@property (strong, nonatomic) IBOutlet UIImageView *unseenCountFlagImage;
@property (strong, nonatomic) IBOutlet UILabel *unseenCountLabel;

-(void)prepareForReuse;
- (void)bind:(id<ActsAsPodcast>)podcast;
@end

