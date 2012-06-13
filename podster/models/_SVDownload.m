// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SVDownload.m instead.

#import "_SVDownload.h"

const struct SVDownloadAttributes SVDownloadAttributes = {
	.downloadedBytes = @"downloadedBytes",
	.manuallyTriggered = @"manuallyTriggered",
	.position = @"position",
	.progress = @"progress",
	.state = @"state",
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
	if ([key isEqualToString:@"manuallyTriggeredValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"manuallyTriggered"];
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
	if ([key isEqualToString:@"stateValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"state"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}
	if ([key isEqualToString:@"totalBytesValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"totalBytes"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
	}

	return keyPaths;
}




@dynamic downloadedBytes;



- (int32_t)downloadedBytesValue {
	NSNumber *result = [self downloadedBytes];
	return [result intValue];
}

- (void)setDownloadedBytesValue:(int32_t)value_ {
	[self setDownloadedBytes:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveDownloadedBytesValue {
	NSNumber *result = [self primitiveDownloadedBytes];
	return [result intValue];
}

- (void)setPrimitiveDownloadedBytesValue:(int32_t)value_ {
	[self setPrimitiveDownloadedBytes:[NSNumber numberWithInt:value_]];
}





@dynamic manuallyTriggered;



- (BOOL)manuallyTriggeredValue {
	NSNumber *result = [self manuallyTriggered];
	return [result boolValue];
}

- (void)setManuallyTriggeredValue:(BOOL)value_ {
	[self setManuallyTriggered:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveManuallyTriggeredValue {
	NSNumber *result = [self primitiveManuallyTriggered];
	return [result boolValue];
}

- (void)setPrimitiveManuallyTriggeredValue:(BOOL)value_ {
	[self setPrimitiveManuallyTriggered:[NSNumber numberWithBool:value_]];
}





@dynamic position;



- (int32_t)positionValue {
	NSNumber *result = [self position];
	return [result intValue];
}

- (void)setPositionValue:(int32_t)value_ {
	[self setPosition:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitivePositionValue {
	NSNumber *result = [self primitivePosition];
	return [result intValue];
}

- (void)setPrimitivePositionValue:(int32_t)value_ {
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





@dynamic state;



- (int16_t)stateValue {
	NSNumber *result = [self state];
	return [result shortValue];
}

- (void)setStateValue:(int16_t)value_ {
	[self setState:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveStateValue {
	NSNumber *result = [self primitiveState];
	return [result shortValue];
}

- (void)setPrimitiveStateValue:(int16_t)value_ {
	[self setPrimitiveState:[NSNumber numberWithShort:value_]];
}





@dynamic totalBytes;



- (int32_t)totalBytesValue {
	NSNumber *result = [self totalBytes];
	return [result intValue];
}

- (void)setTotalBytesValue:(int32_t)value_ {
	[self setTotalBytes:[NSNumber numberWithInt:value_]];
}

- (int32_t)primitiveTotalBytesValue {
	NSNumber *result = [self primitiveTotalBytes];
	return [result intValue];
}

- (void)setPrimitiveTotalBytesValue:(int32_t)value_ {
	[self setPrimitiveTotalBytes:[NSNumber numberWithInt:value_]];
}





@dynamic entry;

	






@end
