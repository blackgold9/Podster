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
#import "SVPodcastImageCache.h"
#import "ActsAsPodcast.h"
#import "UIImageView+WebCache.h"
@interface PodcastGridCell()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@end
@implementation PodcastGridCell
{
    AFImageRequestOperation *imageLoadOp;
    id<ActsAsPodcast> storedPodcast;
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
                
        
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.colors = [NSArray arrayWithObjects:
                           (id)[[UIColor colorWithHex:0x01408C] CGColor],
                           (id)[[UIColor colorWithHex:0x052D52] CGColor],
                           nil];
        gradient.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.3], [NSNumber numberWithFloat:1], nil];
        gradient.frame = self.bounds;
        [view.layer addSublayer:gradient];

        self.imageView = [[UIImageView alloc] initWithFrame:CGRectInset(view.frame, 0, 0)];
        [view addSubview:self.imageView];
       
        
        
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectInset(view.bounds, 10,10)];
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:27];
        self.titleLabel.numberOfLines = 0;
        self.titleLabel.tag = 1907;
        self.titleLabel.opaque = NO;
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
    self.titleLabel.text = podcast.title;
    NSString *logoString = podcast.smallLogoURL;
    if (!logoString) {
        logoString = podcast.logoURL;
    }
    if (self.imageView.image != nil) {
        // Imageview image is cleaned up in prepareForREuse, so if there's an image, this is just an update
        // Don't show the label if you dont have to;
        self.titleLabel.hidden = YES;
    } else {
        self.titleLabel.hidden = NO;
    }
    if(logoString) {
        NSURL *imageURL = [NSURL URLWithString: logoString];
        //        [cache imageFromCacheWithURL:imageURL
        //                             success:^(UIImage *image) {
        //                                 [UIView transitionWithView:imageView
        //                                                   duration:0.33
        //                                                    options:UIViewAnimationOptionTransitionCrossDissolve
        //                                                 animations:^{
        //                                                     label.hidden = YES;
        //                                                     imageView.image = image;
        //                                                 } completion:^(BOOL finished) {
        //                                                     
        //                                                 }];
        //
        //                             } failure:^{
        //                                 
        //                             }];
        
        [self.imageView setImageWithURL:imageURL
                       placeholderImage:nil options:SDWebImageRetryFailed];
        if (self.imageView.image) {
            self.titleLabel.hidden = YES;
        }
        
        __weak UILabel *weakLabel = self.titleLabel;
        __block PodcastGridCell *blockCell = self;
        [self.imageView addObserverForKeyPath:@"image"                                 
                                         task:^(id obj, NSDictionary *change) {
                                             UIImageView *localView = obj;
                                             
                                             if (localView.image) {
                                                 [weakLabel setHidden:YES];
                                             }
                                             
                                             [blockCell removeAllBlockObservers];
                                         }];
        
    } else {
        
    }
    
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
    


}

-(void)bind:(id<ActsAsPodcast>)podcast
  fadeImage:(BOOL)fadeImage withImageCache:(SVPodcastImageCache *)cache
{

    self.titleLabel.text = podcast.title;
    NSString *logoString = podcast.smallLogoURL;
    if (!logoString) {
        logoString = podcast.logoURL;
    }
    if (self.imageView.image != nil) {
        // Imageview image is cleaned up in prepareForREuse, so if there's an image, this is just an update
        // Don't show the label if you dont have to;
        self.titleLabel.hidden = YES;
    } else {
        self.titleLabel.hidden = NO;
    }
    if(logoString) {
        NSURL *imageURL = [NSURL URLWithString: logoString];
//        [cache imageFromCacheWithURL:imageURL
//                             success:^(UIImage *image) {
//                                 [UIView transitionWithView:imageView
//                                                   duration:0.33
//                                                    options:UIViewAnimationOptionTransitionCrossDissolve
//                                                 animations:^{
//                                                     label.hidden = YES;
//                                                     imageView.image = image;
//                                                 } completion:^(BOOL finished) {
//                                                     
//                                                 }];
//
//                             } failure:^{
//                                 
//                             }];
               
        [self.imageView setImageWithURL:imageURL
                       placeholderImage:nil options:SDWebImageRetryFailed];
        if (self.imageView.image) {
            self.titleLabel.hidden = YES;
        }
        
        __weak UILabel *weakLabel = self.titleLabel;
        __block PodcastGridCell *blockCell = self;
        [self.imageView addObserverForKeyPath:@"image"                                 
                                         task:^(id obj, NSDictionary *change) {
                                             UIImageView *localView = obj;

                                             if (localView.image) {
                                                 [weakLabel setHidden:YES];
                                             }
                                             
                                             [blockCell removeAllBlockObservers];
                                         }];
        
    } else {
        
    }
    
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

}

-(void)prepareForReuse
{
    [super prepareForReuse];

    [imageLoadOp cancel];
    UILabel *countLabel = (UILabel *)[self viewWithTag:1908];
    UIImageView *countOverlay = (UIImageView *)[self viewWithTag:1909];
    countLabel.hidden = YES;
    countOverlay.hidden = YES;
}
@end
