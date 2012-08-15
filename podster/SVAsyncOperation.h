//
//  SVAsyncOperation.h
//  Today
//
//  Created by Stephen Vanterpool on 8/13/12.
//
//

#import <Foundation/Foundation.h>
@class SVAsyncOperation;
typedef void (^SVAsyncOperationCompletionCallback)(void);
typedef void (^SVAsyncOperationWorkBlock)(SVAsyncOperation *, SVAsyncOperationCompletionCallback);

@interface SVAsyncOperation : NSOperation
@property (nonatomic, copy) SVAsyncOperationWorkBlock work;

- (id)initWithWorkBlock:(SVAsyncOperationWorkBlock)work;

+ (id)objectWithWorkBlock:(SVAsyncOperationWorkBlock)work;

@end
