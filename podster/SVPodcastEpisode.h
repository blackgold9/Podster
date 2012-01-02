//
//  Created by svanter on 1/1/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface SVPodcastEpisode : NSObject
@property (strong) NSString *title;
@property (strong) NSString *summary;
@property (strong) NSString *sanitizedSummary;
@property (strong) NSString *imageURLString;
@property (assign) NSInteger positionInSeconds;
@property (strong) NSString *mediaURL;
@end