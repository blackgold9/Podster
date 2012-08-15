//
//  SVAsyncOperation.m
//  Today
//
//  Created by Stephen Vanterpool on 8/13/12.
//
//

#import "SVAsyncOperation.h"
@interface SVAsyncOperation()
@property (nonatomic, assign) BOOL executing;
@property (nonatomic, assign) BOOL finished;
@end

@implementation SVAsyncOperation

- (id)initWithWorkBlock:(SVAsyncOperationWorkBlock)work {
    self = [super init];
    if (self) {
        self.work = work;
    }

    return self;
}

+ (id)objectWithWorkBlock:(SVAsyncOperationWorkBlock)work {
    return [[SVAsyncOperation alloc] initWithWorkBlock:work];
}


- (void)start
{
    if (!self.work) {
        [NSException raise:NSInvalidArgumentException format:@"No work block was specified"];
    }
    __weak __typeof(self) weakSelf = self;

    [self willChangeValueForKey:@"isExecuting"];
    weakSelf.executing = YES;
    [self didChangeValueForKey:@"isExecuting"];

    [self willChangeValueForKey:@"isFinished"];
    weakSelf.finished = NO;
    [self didChangeValueForKey:@"isFinished"];

    self.work(weakSelf, ^{
        // Specify the callback that should happen when work is done
        [self willChangeValueForKey:@"isExecuting"];
        weakSelf.executing = NO;
        [self didChangeValueForKey:@"isExecuting"];

        [self willChangeValueForKey:@"isFinished"];
        weakSelf.finished = YES;
        [self didChangeValueForKey:@"isFinished"];

    });
}

- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isExecuting {
    return self.executing;
}

- (BOOL)isFinished {
    return  self.finished;
}


@end
