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
- (void)loadWebImageWithURL:(NSString *)logoString
{
    
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

}
- (void)loadImageWithPodcast:(id<ActsAsPodcast>)podcast
{
      if ([podcast class] == [SVPodcast class]) {
          SVPodcast *coreCast = (SVPodcast *)podcast;
          if (coreCast.gridSizeImageData) {
              LOG_GENERAL(3, @"Loaded local image");
              UIImage *image = [UIImage imageWithData:coreCast.gridSizeImageData];
              self.podcastArtImageView.image = image;
          } else {
              [self loadWebImageWithURL:[podcast smallLogoURL]];
          }
      } else {
          [self loadWebImageWithURL:[podcast smallLogoURL]];
      }
    
}
- (void)bind:(id<ActsAsPodcast>)podcast
{
    
    [imageLoadOp cancel];
    [self loadImageWithPodcast:podcast];
    self.titleLabel.text = podcast.title;
       
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
        
        
        
        
        
        // It's a core data podcast, do download monitoring
        coreDataPodcast = (SVPodcast *)podcast;
        self.downloadCountLabel.alpha = coreDataPodcast.isDownloadingValue? 1 : 0;
        self.downloadCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloaded: %d", @"Downloaded: %d"), [coreDataPodcast downloadedEpisodes]];
        if (coreDataPodcast.isDownloadingValue) {
            //Downloading, so configure ui
            self.downloadCountLabel.text = NSLocalizedString(@"Downloading...", @"Downloading...");
            self.downloadCountLabel.alpha = 1.0;
            self.progressBackground.alpha = 0.5;
            self.progressBar.alpha = 1.0;
        } 
        
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

        [coreDataPodcast addObserver:self forKeyPath:@"downloadPercentage" options:NSKeyValueObservingOptionNew context:nil];
        [coreDataPodcast addObserver:self forKeyPath:@"isDownloading" options:NSKeyValueObservingOptionNew context:nil];

    }
}
    
-(void)prepareForReuse
{
    if (coreDataPodcast) {
     [coreDataPodcast removeObserver:self forKeyPath:@"downloadPercentage"];
     [coreDataPodcast removeObserver:self forKeyPath:@"isDownloading"];        
//        if (newEpisodeCountObserverToken) {
//            [coreDataPodcast removeObserverForKeyPath:@"unseenEpisodeCount" identifier:newEpisodeCountObserverToken];
//        }
        
        self.progressBackground.alpha = 0;
        self.progressBar.alpha = 0;
        coreDataPodcast = nil;
    }
    [imageLoadOp cancel];
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == coreDataPodcast) { 
        if ([keyPath isEqualToString:@"downloadPercentage"]) {
 
            LOG_GENERAL(2, @"Updating grid cell with download progress");
            SVPodcast *local = object;
            self.progressBar.progress = local.downloadPercentageValue / 100.0f;
        } else if ([keyPath isEqualToString:@"isDownloading"]) {
            SVPodcast *local = object;
            if (local.isDownloadingValue) { 
                LOG_GENERAL(2, @"Downloading item");
                self.downloadCountLabel.text = NSLocalizedString(@"Downloading...", nil);
            } else {
                LOG_GENERAL(2, @"Not Downloading item");
                NSUInteger downloaded = [coreDataPodcast downloadedEpisodes];
                if (downloaded > 0) {
                    self.downloadCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Downloaded: %d", @"Downloaded: %d"), downloaded];                    
                } else {
                    self.downloadCountLabel.text = @"";
                }
            }

            [UIView animateWithDuration:0.5
                             animations:^{
                                 self.progressBackground.alpha = local.isDownloadingValue ? 1 : 0;
                                 self.progressBar.alpha = local.isDownloadingValue ? 1 : 0;
                             }];
            
        }
    }
    
}


@end
