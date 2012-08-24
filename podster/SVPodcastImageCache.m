//
//  SVPodcastImageCache.m
//  podster
//
//  Created by Vanterpool, Stephen on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastImageCache.h"
@implementation SVPodcastImageCache {
    dispatch_queue_t workQueue;
    CGSize size;
    NSMutableDictionary *requests;
}
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

-(id)initWithImageURLs:(NSArray *)urls andSize:(CGSize)expectedSize
{
    self = [super init];
    if (self) {
        size = expectedSize;
        workQueue = dispatch_queue_create("com.vantertech.podster.image", NULL);
       
//        dispatch_async(workQueue, ^{
//            LOG_GENERAL(2, @"%@", urls);
//            NSArray *firstTwenty = [urls subarrayWithRange:NSMakeRange(0, MIN(20, urls.count))];
//            for(NSURL *url in firstTwenty) {
//                AFImageRequestOperation *imageLoadOp = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:url]
//                                                                                            imageProcessingBlock:^UIImage *(UIImage *returnedImage) {
//                                                                                                return AFImageByScalingAndCroppingImageToSize(returnedImage, size);
//                                                                                            } 
//                                                                                                       cacheName:nil 
//                                                                                                         success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//                                                                                                             [self setObject:image forKey:url];                                                                                                            
//                                                                                                             [requests removeObjectForKey:url];                                                                                             
//                                                                                                         } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
//                                                                                                             [requests removeObjectForKey:url];                                                                                                   
//                                                                                                         }];
//                [requests setObject:imageLoadOp
//                             forKey:url];            
//                [[SVPodcatcherClient sharedInstance] enqueueHTTPRequestOperation:imageLoadOp];            
//            }        
//        });
    }
    
    return self;
}

-(void)imageFromCacheWithURL:(NSURL *)url 
                     success:(SVImageRequestSuccessCallback)success 
                     failure:(void (^)(void))failure
{
    dispatch_async(workQueue, ^{
        UIImage *image = [self objectForKey:[url absoluteString] ];
        if (image) {
            dispatch_async(dispatch_get_main_queue(), ^{
                success(image);        
                NSLog(@"Returned cachedImage");
            });
        } else {
            AFImageRequestOperation *imageLoadOp = [AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:url]
                                                                                        imageProcessingBlock:^UIImage *(UIImage *returnedImage) {
                                                                                            return AFImageByScalingAndCroppingImageToSize(returnedImage, size);
                                                                                        } 
                                                                                                   cacheName:nil 
                                                                                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                                                                                         [self setObject:image forKey:[[request URL] absoluteString] ];   
                                                                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                             success(image);
                                                                                                             NSLog(@"FetchedImage");
                                                                                                         });
                                                                                                     } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                                                                                         dispatch_async(dispatch_get_main_queue(), ^{                                                                                                                                                                                                              failure();
                                                                                                         });                                                                                                     
                                                                                                     }];
            
            [[SVPodcatcherClient sharedInstance] enqueueHTTPRequestOperation:imageLoadOp];
        }
    });
}
@end
