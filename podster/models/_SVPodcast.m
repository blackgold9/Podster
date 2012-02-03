// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVPodcast.m instead.

#import "_SVPodcast.h"

const struct SVPodcastAttributes SVPodcastAttributes = {
	.feedURL = @"feedURL",
	.lastUpdated = @"lastUpdated",
    .lastSynced = @"lastSynced",
	.logoURL = @"logoURL",
	.smallLogoURL = @"smallLogoURL",
	.subtitle = @"subtitle",
	.summary = @"summary",
	.thumbLogoURL = @"thumbLogoURL",
	.tinyLogoURL = @"tinyLogoURL",
	.title = @"title",
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
	

	return keyPaths;
}




@dynamic feedURL;






@dynamic lastUpdated;

@dynamic lastSynced;






@dynamic logoURL;






@dynamic smallLogoURL;






@dynamic subtitle;






@dynamic summary;






@dynamic thumbLogoURL;






@dynamic tinyLogoURL;






@dynamic title;






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
