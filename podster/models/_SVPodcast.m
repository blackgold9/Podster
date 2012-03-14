// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcast.m instead.

#import "_SVPodcast.h"

const struct SVPodcastAttributes SVPodcastAttributes = {
	.author = @"author",
	.cachingLastModified = @"cachingLastModified",
	.etag = @"etag",
	.feedURL = @"feedURL",
	.hidePlayedEpisodes = @"hidePlayedEpisodes",
	.isSubscribed = @"isSubscribed",
	.lastSynced = @"lastSynced",
	.lastUpdated = @"lastUpdated",
	.logoURL = @"logoURL",
	.nextItemDate = @"nextItemDate",
	.shouldNotify = @"shouldNotify",
	.smallLogoURL = @"smallLogoURL",
	.sortNewestFirst = @"sortNewestFirst",
	.subtitle = @"subtitle",
	.summary = @"summary",
	.thumbLogoURL = @"thumbLogoURL",
	.tinyLogoURL = @"tinyLogoURL",
	.title = @"title",
	.unseenEpsiodeCount = @"unseenEpsiodeCount",
	.urlHash = @"urlHash",
	.websiteURL = @"websiteURL",
};

const struct SVPodcastRelationships SVPodcastRelationships = {
	.items = @"items",
	.subscription = @"subscription",
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
	
	if ([key isEqualToString:@"hidePlayedEpisodesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"hidePlayedEpisodes"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"isSubscribedValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"isSubscribed"];
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
	if ([key isEqualToString:@"unseenEpsiodeCountValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"unseenEpsiodeCount"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic author;






@dynamic cachingLastModified;






@dynamic etag;






@dynamic feedURL;






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





@dynamic lastSynced;






@dynamic lastUpdated;






@dynamic logoURL;






@dynamic nextItemDate;






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





@dynamic subtitle;






@dynamic summary;






@dynamic thumbLogoURL;






@dynamic tinyLogoURL;






@dynamic title;






@dynamic unseenEpsiodeCount;



- (int)unseenEpsiodeCountValue {
	NSNumber *result = [self unseenEpsiodeCount];
	return [result intValue];
}

- (void)setUnseenEpsiodeCountValue:(int)value_ {
	[self setUnseenEpsiodeCount:[NSNumber numberWithInt:value_]];
}

- (int)primitiveUnseenEpsiodeCountValue {
	NSNumber *result = [self primitiveUnseenEpsiodeCount];
	return [result intValue];
}

- (void)setPrimitiveUnseenEpsiodeCountValue:(int)value_ {
	[self setPrimitiveUnseenEpsiodeCount:[NSNumber numberWithInt:value_]];
}





@dynamic urlHash;






@dynamic websiteURL;






@dynamic items;

	
- (NSMutableSet*)itemsSet {
	[self willAccessValueForKey:@"items"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"items"];
  
	[self didAccessValueForKey:@"items"];
	return result;
}
	

@dynamic subscription;

	





@end
