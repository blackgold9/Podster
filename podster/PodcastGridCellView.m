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
#import "GridCellCountOverlay.h"
static const int ddLogLevel = LOG_LEVEL_INFO;
@implementation PodcastGridCellView {
    AFImageRequestOperation *imageLoadOp;
    SVPodcast *coreDataPodcast;
   
}
@synthesize progressBackground;
@synthesize progressBar;
@synthesize podcastArtImageView;
@synthesize titleLabel;
@synthesize unseenCountFlagImage;
@synthesize unseenCountLabel;
@synthesize countOverlay;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}
- (NSCache *)cache
{
     static NSCache *thumbCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        thumbCache = [[NSCache alloc] init];
    });
    
    return thumbCache;
}
- (void)loadWebImageWithURL:(NSString *)logoString
{
    
    self.titleLabel.hidden = NO;
    if(logoString) {
        NSURL *imageURL = [NSURL URLWithString: logoString];
        NSURLRequest *request = [NSURLRequest requestWithURL:imageURL];
        [self.podcastArtImageView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                                                 success:^(NSURLRequest *req, NSHTTPURLResponse *response, UIImage *image) {
                                                     self.titleLabel.hidden = YES;
                                                 } failure:^(NSURLRequest *req, NSHTTPURLResponse *response, NSError *error) {
                                                     
                                                 }];
    } else {            
        self.podcastArtImageView.image =  [UIImage imageNamed:@"placeholder.png"];
    }
    
}
- (void)loadImageWithPodcast:(id<ActsAsPodcast>)podcast
{
    if ([podcast class] == [SVPodcast class]) {
        SVPodcast *coreCast = (SVPodcast *)podcast;
        if (coreCast.gridSizeImageData && coreCast.objectID) {
            NSCache *cache = [self cache];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{                                
                UIImage *image = [cache objectForKey:coreCast.objectID];
                if (image == nil) {
                    DDLogVerbose( @"Loaded local image");
                    image = [UIImage imageWithData:coreCast.gridSizeImageData];
                    [cache setObject:image forKey:coreCast.objectID];
                } else {
                    DDLogVerbose(@"Loaded cached Image");
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.podcastArtImageView.image = nil;
                    [UIView animateWithDuration:0.33 animations:^{
                        self.podcastArtImageView.image = image;                        
                    }];
                    
                });
            });
        } else {
            [self loadWebImageWithURL:[podcast smallLogoURL]];
            DDLogWarn(@"Didnt have expected image data stored locally. Redownloading");
            [coreCast downloadOfflineImageData];
        }
    } else {
        [self loadWebImageWithURL:[podcast smallLogoURL]];
    }
}

- (void)setDownloadProgressHidden:(BOOL)hidden animated:(BOOL)animated
{
    [UIView animateWithDuration:animated ? 0.5 : 0
                     animations:^{
                         self.progressBackground.alpha = hidden ? 0 : 0.5;
                         self.progressBar.alpha = hidden ? 0 : 1;
                     }];
}
- (void)loadImage
{
    
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
    self.progressBar.alpha = 0;
    self.progressBackground.alpha = 0;
    
    self.accessibilityLabel = [podcast title];
    if ([podcast class] == [SVPodcast class]) {
        // It's a core data podcast, do download monitoring
        coreDataPodcast = (SVPodcast *)podcast;
                
        if (coreDataPodcast.isDownloadingValue) {         
            self.progressBackground.alpha = 0.5;
            self.progressBar.alpha = 1.0;
        } 

        [coreDataPodcast addObserver:self forKeyPath:@"downloadPercentage" options:NSKeyValueObservingOptionNew context:nil];
        [coreDataPodcast addObserver:self forKeyPath:@"isDownloading" options:NSKeyValueObservingOptionNew context:nil];
        [coreDataPodcast addObserver:self forKeyPath:@"unlistenedSinceSubscribedCount" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:nil];
        
    }
}

-(void)prepareForReuse
{
    if (coreDataPodcast) {
        self.countOverlay.hidden = YES;
        [coreDataPodcast removeObserver:self forKeyPath:@"downloadPercentage"];
        [coreDataPodcast removeObserver:self forKeyPath:@"isDownloading"];        
        [coreDataPodcast removeObserver:self forKeyPath:@"unlistenedSinceSubscribedCount"];
        
        self.progressBackground.alpha = 0;
        self.progressBar.alpha = 0;
        self.progressBar.progress = 0.0f;
        coreDataPodcast = nil;
    }
    [imageLoadOp cancel];
}
-(void)dealloc
{
    if (coreDataPodcast) {
        [coreDataPodcast removeObserver:self forKeyPath:@"downloadPercentage"];
        [coreDataPodcast removeObserver:self forKeyPath:@"isDownloading"];        
        [coreDataPodcast removeObserver:self forKeyPath:@"unlistenedSinceSubscribedCount"];
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == coreDataPodcast) { 
        if ([keyPath isEqualToString:@"downloadPercentage"]) {
            DDLogVerbose(@"%@ - download percentage: %f", coreDataPodcast.title, coreDataPodcast.downloadPercentageValue);
            self.progressBar.progress = coreDataPodcast.downloadPercentageValue / 100.0f;
        } else if ([keyPath isEqualToString:@"isDownloading"]) {
            DDLogVerbose(@"isDownloading changed to %@",  coreDataPodcast.isDownloadingValue ? @"true" : @"false");
            [self setDownloadProgressHidden:!coreDataPodcast.isDownloadingValue animated:YES];
            
        } else if ([keyPath isEqualToString:SVPodcastAttributes.unlistenedSinceSubscribedCount]) {
                                                                    
                                if (coreDataPodcast.unlistenedSinceSubscribedCountValue > 0) {
                                    [self.countOverlay setCount:coreDataPodcast.unlistenedSinceSubscribedCountValue];
                                    [self.countOverlay sizeToFit];
                                    CGRect newFrame = self.countOverlay.frame;
                                    newFrame.origin.x = self.frame.size.width - newFrame.size.width;
                                    self.countOverlay.frame = newFrame;
                                    self.countOverlay.hidden = NO;
                                } else {
                                    self.countOverlay.hidden = YES;
                                }                            
        }
    }    
}


@end
