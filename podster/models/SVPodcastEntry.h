#import "_SVPodcastEntry.h"

@interface SVPodcastEntry : _SVPodcastEntry {}
// Custom logic goes here.
- (void)populateWithDictionary:(NSDictionary *)dict;
- (NSString *)localFilePath;

@end
