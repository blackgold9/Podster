#import "_SVPodcastEntry.h"

@interface SVPodcastEntry : _SVPodcastEntry {}
// Custom logic goes here.
-(NSString *)identifier;
- (void)populateWithDictionary:(NSDictionary *)dict;
- (NSString *)downloadFilePathForBasePath:(NSString *)basePath;

@end
