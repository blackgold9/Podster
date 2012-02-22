//
//  SVPodcastImageCache.h
//  podster
//
//  Created by Vanterpool, Stephen on 2/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef void (^SVImageRequestSuccessCallback)(UIImage*);
@interface SVPodcastImageCache : NSCache
-(id)initWithImageURLs:(NSArray *)urls andSize:(CGSize)expectedSize;
-(void)imageFromCacheWithURL:(NSURL *)url 
                     success:(SVImageRequestSuccessCallback)success 
                     failure:(void (^)(void))failure;
@end
