// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcast.m instead.

#import "_SVPodcast.h"

const struct SVPodcastAttributes SVPodcastAttributes = {
	.author = @"author",
	.downloadCount = @"downloadCount",
	.downloadPercentage = @"downloadPercentage",
	.downloadsToKeep = @"downloadsToKeep",
	.feedURL = @"feedURL",
	.fullIsizeImageData = @"fullIsizeImageData",
	.gridSizeImageData = @"gridSizeImageData",
	.hidePlayedEpisodes = @"hidePlayedEpisodes",
	.isDownloading = @"isDownloading",
	.isSubscribed = @"isSubscribed",
	.isVideo = @"isVideo",
	.lastSynced = @"lastSynced",
	.lastUpdated = @"lastUpdated",
	.listSizeImageData = @"listSizeImageData",
	.logoURL = @"logoURL",
	.podstoreId = @"podstoreId",
	.shouldNotify = @"shouldNotify",
	.smallLogoURL = @"smallLogoURL",
	.sortNewestFirst = @"sortNewestFirst",
	.subscribedDate = @"subscribedDate",
	.subtitle = @"subtitle",
	.summary = @"summary",
	.thumbLogoURL = @"thumbLogoURL",
	.tinyLogoURL = @"tinyLogoURL",
	.title = @"title",
	.unlistenedSinceSubscribedCount = @"unlistenedSinceSubscribedCount",
	.updating = @"updating",
	.websiteURL = @"websiteURL",
};

const struct SVPodcastRelationships SVPodcastRelationships = {
	.items = @"items",
};

const struct SVPodcastFetchedProperties SVPodcastFetchedProperties = {
};

@implementation SVPodcastID
@end

@implementation _SVPodcast

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Podcast" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Podcast";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Podcast" inManagedObjectContext:moc_];
}

- (SVPodcastID*)objectID {
	return (SVPodcastID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"downloadCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"downloadCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"downloadPercentageValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"downloadPercentage"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"downloadsToKeepValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"downloadsToKeep"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"hidePlayedEpisodesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"hidePlayedEpisodes"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"isDownloadingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isDownloading"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"isSubscribedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isSubscribed"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"isVideoValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isVideo"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"podstoreIdValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"podstoreId"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"shouldNotifyValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"shouldNotify"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"sortNewestFirstValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"sortNewestFirst"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"unlistenedSinceSubscribedCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unlistenedSinceSubscribedCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"updatingValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"updating"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic author;






@dynamic downloadCount;



- (int32_t)downloadCountValue {
	NSNumber *result = [self downloadCount];
	return [result intValue];
}

- (void)setDownloadCountValue:(int32_t)value_ {
	[self setDownloadCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveDownloadCountValue {
	NSNumber *result = [self primitiveDownloadCount];
	return [result intValue];
}

- (void)setPrimitiveDownloadCountValue:(int32_t)value_ {
	[self setPrimitiveDownloadCount:[NSNumber numberWithInt:value_]];
}





@dynamic downloadPercentage;



- (float)downloadPercentageValue {
	NSNumber *result = [self downloadPercentage];
	return [result floatValue];
}

- (void)setDownloadPercentageValue:(float)value_ {
	[self setDownloadPercentage:[NSNumber numberWithFloat:value_]];
}

- (float)primitiveDownloadPercentageValue {
	NSNumber *result = [self primitiveDownloadPercentage];
	return [result floatValue];
}

- (void)setPrimitiveDownloadPercentageValue:(float)value_ {
	[self setPrimitiveDownloadPercentage:[NSNumber numberWithFloat:value_]];
}





@dynamic downloadsToKeep;



- (int32_t)downloadsToKeepValue {
	NSNumber *result = [self downloadsToKeep];
	return [result intValue];
}

- (void)setDownloadsToKeepValue:(int32_t)value_ {
	[self setDownloadsToKeep:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveDownloadsToKeepValue {
	NSNumber *result = [self primitiveDownloadsToKeep];
	return [result intValue];
}

- (void)setPrimitiveDownloadsToKeepValue:(int32_t)value_ {
	[self setPrimitiveDownloadsToKeep:[NSNumber numberWithInt:value_]];
}





@dynamic feedURL;






@dynamic fullIsizeImageData;






@dynamic gridSizeImageData;






@dynamic hidePlayedEpisodes;



- (BOOL)hidePlayedEpisodesValue {
	NSNumber *result = [self hidePlayedEpisodes];
	return [result boolValue];
}

- (void)setHidePlayedEpisodesValue:(BOOL)value_ {
	[self setHidePlayedEpisodes:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveHidePlayedEpisodesValue {
	NSNumber *result = [self primitiveHidePlayedEpisodes];
	return [result boolValue];
}

- (void)setPrimitiveHidePlayedEpisodesValue:(BOOL)value_ {
	[self setPrimitiveHidePlayedEpisodes:[NSNumber numberWithBool:value_]];
}





@dynamic isDownloading;



- (BOOL)isDownloadingValue {
	NSNumber *result = [self isDownloading];
	return [result boolValue];
}

- (void)setIsDownloadingValue:(BOOL)value_ {
	[self setIsDownloading:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsDownloadingValue {
	NSNumber *result = [self primitiveIsDownloading];
	return [result boolValue];
}

- (void)setPrimitiveIsDownloadingValue:(BOOL)value_ {
	[self setPrimitiveIsDownloading:[NSNumber numberWithBool:value_]];
}





@dynamic isSubscribed;



- (BOOL)isSubscribedValue {
	NSNumber *result = [self isSubscribed];
	return [result boolValue];
}

- (void)setIsSubscribedValue:(BOOL)value_ {
	[self setIsSubscribed:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsSubscribedValue {
	NSNumber *result = [self primitiveIsSubscribed];
	return [result boolValue];
}

- (void)setPrimitiveIsSubscribedValue:(BOOL)value_ {
	[self setPrimitiveIsSubscribed:[NSNumber numberWithBool:value_]];
}





@dynamic isVideo;



- (BOOL)isVideoValue {
	NSNumber *result = [self isVideo];
	return [result boolValue];
}

- (void)setIsVideoValue:(BOOL)value_ {
	[self setIsVideo:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveIsVideoValue {
	NSNumber *result = [self primitiveIsVideo];
	return [result boolValue];
}

- (void)setPrimitiveIsVideoValue:(BOOL)value_ {
	[self setPrimitiveIsVideo:[NSNumber numberWithBool:value_]];
}





@dynamic lastSynced;






@dynamic lastUpdated;






@dynamic listSizeImageData;






@dynamic logoURL;






@dynamic podstoreId;



- (int32_t)podstoreIdValue {
	NSNumber *result = [self podstoreId];
	return [result intValue];
}

- (void)setPodstoreIdValue:(int32_t)value_ {
	[self setPodstoreId:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitivePodstoreIdValue {
	NSNumber *result = [self primitivePodstoreId];
	return [result intValue];
}

- (void)setPrimitivePodstoreIdValue:(int32_t)value_ {
	[self setPrimitivePodstoreId:[NSNumber numberWithInt:value_]];
}





@dynamic shouldNotify;



- (BOOL)shouldNotifyValue {
	NSNumber *result = [self shouldNotify];
	return [result boolValue];
}

- (void)setShouldNotifyValue:(BOOL)value_ {
	[self setShouldNotify:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveShouldNotifyValue {
	NSNumber *result = [self primitiveShouldNotify];
	return [result boolValue];
}

- (void)setPrimitiveShouldNotifyValue:(BOOL)value_ {
	[self setPrimitiveShouldNotify:[NSNumber numberWithBool:value_]];
}





@dynamic smallLogoURL;






@dynamic sortNewestFirst;



- (BOOL)sortNewestFirstValue {
	NSNumber *result = [self sortNewestFirst];
	return [result boolValue];
}

- (void)setSortNewestFirstValue:(BOOL)value_ {
	[self setSortNewestFirst:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveSortNewestFirstValue {
	NSNumber *result = [self primitiveSortNewestFirst];
	return [result boolValue];
}

- (void)setPrimitiveSortNewestFirstValue:(BOOL)value_ {
	[self setPrimitiveSortNewestFirst:[NSNumber numberWithBool:value_]];
}





@dynamic subscribedDate;






@dynamic subtitle;






@dynamic summary;






@dynamic thumbLogoURL;






@dynamic tinyLogoURL;






@dynamic title;






@dynamic unlistenedSinceSubscribedCount;



- (int32_t)unlistenedSinceSubscribedCountValue {
	NSNumber *result = [self unlistenedSinceSubscribedCount];
	return [result intValue];
}

- (void)setUnlistenedSinceSubscribedCountValue:(int32_t)value_ {
	[self setUnlistenedSinceSubscribedCount:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveUnlistenedSinceSubscribedCountValue {
	NSNumber *result = [self primitiveUnlistenedSinceSubscribedCount];
	return [result intValue];
}

- (void)setPrimitiveUnlistenedSinceSubscribedCountValue:(int32_t)value_ {
	[self setPrimitiveUnlistenedSinceSubscribedCount:[NSNumber numberWithInt:value_]];
}





@dynamic updating;



- (BOOL)updatingValue {
	NSNumber *result = [self updating];
	return [result boolValue];
}

- (void)setUpdatingValue:(BOOL)value_ {
	[self setUpdating:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveUpdatingValue {
	NSNumber *result = [self primitiveUpdating];
	return [result boolValue];
}

- (void)setPrimitiveUpdatingValue:(BOOL)value_ {
	[self setPrimitiveUpdating:[NSNumber numberWithBool:value_]];
}





@dynamic websiteURL;






@dynamic items;

	
- (NSMutableSet*)itemsSet {
	[self willAccessValueForKey:@"items"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"items"];
  
	[self didAccessValueForKey:@"items"];
	return result;
}
	






@end
