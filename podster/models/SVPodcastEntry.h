#import "_SVPodcastEntry.h"

@interface SVPodcastEntry : _SVPodcastEntry {}
// Custom logic goes here.
-(NSString *)identifier;

- (NSString *)downloadFilePathForBasePath:(NSString *)basePath;

@end
