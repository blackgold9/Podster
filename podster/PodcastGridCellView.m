//
//  PodcastGridCellView.m
//  podster
//
//  Created by Vanterpool, Stephen on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PodcastGridCellView.h"
#import "ActsAsPodcast.h"
#import "SVPodcast.h"
#import <QuartzCore/QuartzCore.h>

@implementation PodcastGridCellView {
    AFImageRequestOperation *imageLoadOp;
    id downloadPercentageObserverToken;
    id isDownloadingObserverToken;
    id newEpisodeCountObserverToken;
    SVPodcast *coreDataPodcast;
}
@synthesize progressBackground;
@synthesize progressBar;
@synthesize podcastArtImageView;
@synthesize titleLabel;
@synthesize downloadCountLabel;
@synthesize unseenCountFlagImage;
@synthesize unseenCountLabel;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (void)bind:(id<ActsAsPodcast>)podcast
{
    
    [imageLoadOp cancel];
    
    self.titleLabel.text = podcast.title;
    NSString *logoString = podcast.smallLogoURL;
    if (!logoString) {
        logoString = podcast.logoURL;
            }
        self.titleLabel.hidden = NO;
        if(logoString) {
            NSURL *imageURL = [NSURL URLWithString: logoString];
            NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
            
            [self.podcastArtImageView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                         self.titleLabel.hidden = YES;
                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                         
                                                     }];
        } else {            
            self.podcastArtImageView.image =  [UIImage imageNamed:@"placeholder.png"];
        }

    self.podcastArtImageView.layer.borderColor = [[UIColor colorWithWhite:0.7 alpha:1.0] CGColor];
    self.podcastArtImageView.layer.borderWidth = 2.0;
    self.unseenCountFlagImage.alpha = 0.0;
    self.unseenCountLabel.alpha = 0.0;
    self.downloadCountLabel.alpha = 0;
    self.progressBar.alpha = 0;
    self.progressBackground.alpha = 0;
    [UIView animateWithDuration:0.33
                     animations:^{
                         
                         
                         if ([[podcast unseenEpsiodeCount] integerValue] > 0) {
                             self.unseenCountFlagImage.alpha = 1.0;
                             self.unseenCountLabel.alpha = 1.0;
                             self.unseenCountLabel.text = [NSString stringWithFormat:@"%d", [[podcast unseenEpsiodeCount] integerValue]];
                         } 
                     }];    
    
    self.accessibilityLabel = [podcast title];
    if ([podcast class] == [SVPodcast class]) {
        
        

        self.downloadCountLabel.alpha = 1.0;

        // It's a core data podcast, do download monitoring
        coreDataPodcast = (SVPodcast *)podcast;
        self.downloadCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloaded: %d", @"Downloaded: %d"), [coreDataPodcast downloadedEpisodes]];
        if (coreDataPodcast.isDownloadingValue) {
            //Downloading, so configure ui
            self.downloadCountLabel.text = NSLocalizedString(@"Downloading...", @"Downloading...");
            self.downloadCountLabel.alpha = 1.0;
            self.progressBackground.alpha = 0.5;
            self.progressBar.alpha = 1.0;
        }
        
        newEpisodeCountObserverToken = [coreDataPodcast addObserverForKeyPath:@"unseenEpisodeCount" task:^(id obj, NSDictionary *change) {
            [UIView animateWithDuration:0.33
                             animations:^{
                                 
                                 
                                 if ([[podcast unseenEpsiodeCount] integerValue] > 0) {
                                     self.unseenCountFlagImage.alpha = 1.0;
                                     self.unseenCountLabel.alpha = 1.0;
                                     self.unseenCountLabel.text = [NSString stringWithFormat:@"%d", [[podcast unseenEpsiodeCount] integerValue]];
                                 } else {
                                     self.unseenCountLabel.alpha = 0;
                                     self.unseenCountFlagImage.alpha = 0;
                                 }
                             }];     
        }];
        __weak UIProgressView *weakProgressView  = self.progressBar;
        __weak UIView *WeakprogressBackground = self.progressBackground;
        downloadPercentageObserverToken = [coreDataPodcast addObserverForKeyPath:@"downloadPercentage" task:^(id obj, NSDictionary *change) { 
            if (weakProgressView) {
                LOG_GENERAL(2, @"Updating grid cell with download progress");
                SVPodcast *local = obj;
                weakProgressView.progress = local.downloadPercentageValue / 100.0f;
            }
        }];
                
        isDownloadingObserverToken = [coreDataPodcast addObserverForKeyPath:@"isDownloading" task:^(id obj, NSDictionary *change) {
            if (weakProgressView) {
                
                SVPodcast *local = obj;
                if (local.isDownloadingValue) { 
                    LOG_GENERAL(2, @"Downloading item");
                    self.downloadCountLabel.text = NSLocalizedString(@"Downloading...", @"Downloading...");
                } else {
                    LOG_GENERAL(2, @"Not Downloading item");
                    self.downloadCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloaded: %d", @"Downloaded: %d"), [local downloadedEpisodes]];
                }
                [UIView animateWithDuration:0.5
                                 animations:^{
                                     WeakprogressBackground.alpha = local.isDownloadingValue ? 0.5 : 0;
                                     weakProgressView.alpha = local.isDownloadingValue? 1 : 0;
                                 }];
            }
        }];
    }
}
    
-(void)prepareForReuse
{
    if (coreDataPodcast) {
        if (downloadPercentageObserverToken) {
            [coreDataPodcast removeObserverForKeyPath:@"downloadPercentageValue" identifier:downloadPercentageObserverToken];
        }
        
        if (isDownloadingObserverToken) {
            [coreDataPodcast removeObserverForKeyPath:@"isDownloading" identifier:isDownloadingObserverToken];
        }
        
        if (newEpisodeCountObserverToken) {
            [coreDataPodcast removeObserverForKeyPath:@"unseenEpisodeCount" identifier:newEpisodeCountObserverToken];
        }
        
        self.progressBackground.alpha = 0;
        self.progressBar.alpha = 0;
        coreDataPodcast = nil;
    }
    [imageLoadOp cancel];
}


@end
