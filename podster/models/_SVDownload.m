// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVDownload.m instead.

#import "_SVDownload.h"

const struct SVDownloadAttributes SVDownloadAttributes = {
	.downloadedBytes = @"downloadedBytes",
	.filePath = @"filePath",
	.position = @"position",
	.progress = @"progress",
	.totalBytes = @"totalBytes",
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
	if ([key isEqualToString:@"positionValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"position"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"progressValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"progress"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"totalBytesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"totalBytes"];
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





@dynamic filePath;






@dynamic position;



- (int)positionValue {
	NSNumber *result = [self position];
	return [result intValue];
}

- (void)setPositionValue:(int)value_ {
	[self setPosition:[NSNumber numberWithInt:value_]];
}

- (int)primitivePositionValue {
	NSNumber *result = [self primitivePosition];
	return [result intValue];
}

- (void)setPrimitivePositionValue:(int)value_ {
	[self setPrimitivePosition:[NSNumber numberWithInt:value_]];
}





@dynamic progress;



- (float)progressValue {
	NSNumber *result = [self progress];
	return [result floatValue];
}

- (void)setProgressValue:(float)value_ {
	[self setProgress:[NSNumber numberWithFloat:value_]];
}

- (float)primitiveProgressValue {
	NSNumber *result = [self primitiveProgress];
	return [result floatValue];
}

- (void)setPrimitiveProgressValue:(float)value_ {
	[self setPrimitiveProgress:[NSNumber numberWithFloat:value_]];
}





@dynamic totalBytes;



- (int)totalBytesValue {
	NSNumber *result = [self totalBytes];
	return [result intValue];
}

- (void)setTotalBytesValue:(int)value_ {
	[self setTotalBytes:[NSNumber numberWithInt:value_]];
}

- (int)primitiveTotalBytesValue {
	NSNumber *result = [self primitiveTotalBytes];
	return [result intValue];
}

- (void)setPrimitiveTotalBytesValue:(int)value_ {
	[self setPrimitiveTotalBytes:[NSNumber numberWithInt:value_]];
}





@dynamic entry;

	





@end
