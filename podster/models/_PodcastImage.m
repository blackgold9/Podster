// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to PodcastImage.m instead.

#import "_PodcastImage.h"

const struct PodcastImageAttributes PodcastImageAttributes = {
	.imageData = @"imageData",
};

const struct PodcastImageRelationships PodcastImageRelationships = {
};

const struct PodcastImageFetchedProperties PodcastImageFetchedProperties = {
};

@implementation PodcastImageID
@end

@implementation _PodcastImage

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"PodcastImage" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"PodcastImage";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"PodcastImage" inManagedObjectContext:moc_];
}

- (PodcastImageID*)objectID {
	return (PodcastImageID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic imageData;











@end
