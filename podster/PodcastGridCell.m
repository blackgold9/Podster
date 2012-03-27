//
//  PodcastGridself.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PodcastGridCell.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+Hex.h"
#import "UIImage+ForceDecompress.h"
#import "ActsAsPodcast.h"
#import "UIImageView+AFNetworking.h"
#import "SVPodcast.h"
@interface PodcastGridCell()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@end
@implementation PodcastGridCell
{
    AFImageRequestOperation *imageLoadOp;
    id<ActsAsPodcast> storedPodcast;
    id downloadPercentageObserverToken;
    id isDownloadingObserverToken;
    SVPodcast *coreDataPodcast;
}
@synthesize imageView = _imageView;
@synthesize titleLabel = _titleLabel;
static UIImage * AFImageByScalingAndCroppingImageToSize(UIImage *image, CGSize size) {
    if (image == nil) {
        return nil;
    } else if (CGSizeEqualToSize(image.size, size) || CGSizeEqualToSize(size, CGSizeZero)) {
        return image;
    }
    
    CGSize scaledSize = size;
	CGPoint thumbnailPoint = CGPointZero;
    
    CGFloat widthFactor = size.width / image.size.width;
    CGFloat heightFactor = size.height / image.size.height;
    CGFloat scaleFactor = (widthFactor > heightFactor) ? widthFactor : heightFactor;
    scaledSize.width = image.size.width * scaleFactor;
    scaledSize.height = image.size.height * scaleFactor;
    if (widthFactor > heightFactor) {
        thumbnailPoint.y = (size.height - scaledSize.height) * 0.5; 
    } else if (widthFactor < heightFactor) {
        thumbnailPoint.x = (size.width - scaledSize.width) * 0.5;
    }
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0); 
    [image drawInRect:CGRectMake(thumbnailPoint.x, thumbnailPoint.y, scaledSize.width, scaledSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
	return newImage;
}
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {        
        UIView *view = [[UIView alloc] initWithFrame:frame];
        //view.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1];
        //        view.layer.masksToBounds = NO;
        //        //view.layer.cornerRadius = 8;
        //        view.layer.shadowColor = [UIColor whiteColor].CGColor;
        //        view.layer.shadowOpacity = 0.5;
        //        view.layer.shadowOffset = CGSizeMake(0, 0);
        //        view.layer.shadowPath = [UIBezierPath bezierPathWithRect:view.bounds].CGPath;
        //        view.layer.shadowRadius = 3;
        view.layer.borderColor = [[UIColor colorWithRed:0.48 green:0.48 blue:0.52  alpha:1] CGColor];
        view.layer.borderWidth = 2;
                
        
//        UIImageView *backgroundImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"placeholder.png"]];
//        backgroundImage.frame = view.frame;
//        [view addSubview:backgroundImage];
       
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.frame, 0, 0)];
        [view addSubview:self.imageView];
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 10,10)];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:27];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.tag = 1907;
        self.titleLabel.opaque = NO;
        self.titleLabel.adjustsFontSizeToFitWidth = YES;
        [view addSubview:self.titleLabel];

        
        UILabel *newCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 25, 20)];
        newCountLabel.backgroundColor = [UIColor colorWithHex:0x0066a4];
        newCountLabel.hidden = YES;
        newCountLabel.tag = 1908;
        newCountLabel.textColor =[UIColor whiteColor];
        newCountLabel.adjustsFontSizeToFitWidth = YES;
        newCountLabel.minimumFontSize = 13;
        
        newCountLabel.textAlignment = UITextAlignmentLeft;
        newCountLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
        
        UIImageView *countOverlay = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"grid-count-overlay.png"]];
        countOverlay.tag = 1909;
        [view addSubview:countOverlay];
        countOverlay.hidden = YES;
        newCountLabel.hidden = YES;
        
        [view addSubview:newCountLabel];
        self.contentView = view;
        self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
        self.layer.shouldRasterize = YES;
    }
    
    return self;
}
//-(void)drawRect:(CGRect)rect
//{
//    UIFont *titleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:27];
//    UIColor *titleColor = [UIColor colorWithHex:0x0066a4];
//    UIImage *overlayImage = [UIImage imageNamed:@"grid-count-overlay.png"];
//    if(
//    
//}
-(void)bind:(id<ActsAsPodcast>)podcast
  fadeImage:(BOOL)fadeImage
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
        
        [self.imageView setImageWithURLRequest:request placeholderImage:[UIImage imageNamed:@"placeholder.png"]
                                                                                    success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                                        self.titleLabel.hidden = YES;
                                                                                    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                                        
                                                                                    }];
    } else {            
        self.imageView.image =  [UIImage imageNamed:@"placeholder.png"];
    }
   
    [UIView animateWithDuration:0.33
                     animations:^{
                         
                         
                         UILabel *countLabel = (UILabel *)[self viewWithTag:1908];
                         UIImageView *countOverlay = (UIImageView *)[self viewWithTag:1909];
                         if ([[podcast unseenEpsiodeCount] integerValue] > 0) {
                             countOverlay.hidden = NO;
                             countLabel.hidden = NO;
                             countLabel.text = [NSString stringWithFormat:@"%d", [[podcast unseenEpsiodeCount] integerValue]];
                         } else {
                             countLabel.hidden = YES;
                             countOverlay.hidden = YES;
                         }
                     }];    

    self.accessibilityLabel = [podcast title];
    if ([podcast class] == [SVPodcast class]) {
        UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        progressView.tag = 1337;
        [self addSubview:progressView];
        
        // It's a core data podcast, do download monitoring
        coreDataPodcast = (SVPodcast *)podcast;
progressView.alpha = coreDataPodcast.isDownloadingValue ? 1 : 0; 
        
        __weak UIProgressView *weakProgressView  = progressView;
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
                } else {
                                        LOG_GENERAL(2, @"Not Downloading item");
                }
                [UIView animateWithDuration:0.5
                                 animations:^{
                                     progressView.alpha = local.isDownloadingValue ? 1 : 0; 
                                 }];
            }
        }];
    }


}


-(void)prepareForReuse
{
    [super prepareForReuse];
    if (coreDataPodcast) {
        if (downloadPercentageObserverToken) {
            [coreDataPodcast removeObserverForKeyPath:@"downloadPercentageValue" identifier:downloadPercentageObserverToken];
        }
        
        if (isDownloadingObserverToken) {
            [coreDataPodcast removeObserverForKeyPath:@"isDownloading" identifier:isDownloadingObserverToken];
        }
        coreDataPodcast = nil;
    }
    [imageLoadOp cancel];
    UILabel *countLabel = (UILabel *)[self viewWithTag:1908];
    UIImageView *countOverlay = (UIImageView *)[self viewWithTag:1909];
    countLabel.hidden = YES;
    countOverlay.hidden = YES;
}
@end
