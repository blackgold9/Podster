//
//  PodcastGridCell.h
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import "GMGridViewCell.h"
@protocol ActsAsPodcast;
@class SVPodcastImageCache;
@interface PodcastGridCell : GMGridViewCell
-(void)bind:(id<ActsAsPodcast>)podcast
  fadeImage:(BOOL)fadeImage;


@end
