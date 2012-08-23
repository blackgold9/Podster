//
//  PodcastGridCellView.h
//  podster
//
//  Created by Vanterpool, Stephen on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GridCellCountOverlay;
@protocol ActsAsPodcast;
@interface PodcastGridCellView : UICollectionViewCell
@property (strong, nonatomic) IBOutlet UIView *progressBackground;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;

@property (strong, nonatomic) IBOutlet UIImageView *podcastArtImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView *unseenCountFlagImage;
@property (strong, nonatomic) IBOutlet UILabel *unseenCountLabel;
@property (strong, nonatomic) IBOutlet GridCellCountOverlay *countOverlay;

-(void)prepareForReuse;
- (void)bind:(id<ActsAsPodcast>)podcast;
@end

