// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVDownload.m instead.

#import "_SVDownload.h"

const struct SVDownloadAttributes SVDownloadAttributes = {
	.downloadedBytes = @"downloadedBytes",
	.path = @"path",
};

const struct SVDownloadRelationships SVDownloadRelationships = {
	.entry = @"entry",
};

const struct SVDownloadFetchedProperties SVDownloadFetchedProperties = {
};

@implementation SVDownloadID
@end

@implementation _SVDownload

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Download" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Download";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Download" inManagedObjectContext:moc_];
}

- (SVDownloadID*)objectID {
	return (SVDownloadID*)[super objectID];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"downloadedBytesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"downloadedBytes"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic downloadedBytes;



- (int)downloadedBytesValue {
	NSNumber *result = [self downloadedBytes];
	return [result intValue];
}

- (void)setDownloadedBytesValue:(int)value_ {
	[self setDownloadedBytes:[NSNumber numberWithInt:value_]];
}

- (int)primitiveDownloadedBytesValue {
	NSNumber *result = [self primitiveDownloadedBytes];
	return [result intValue];
}

- (void)setPrimitiveDownloadedBytesValue:(int)value_ {
	[self setPrimitiveDownloadedBytes:[NSNumber numberWithInt:value_]];
}





@dynamic path;






@dynamic entry;

	





@end
