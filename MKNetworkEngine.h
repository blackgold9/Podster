//
//  MKNetworkEngine.h
//  MKNetworkKit
//
//  Created by Mugunth Kumar (@mugunthkumar) on 11/11/11.
//  Copyright (C) 2011-2020 by Steinlogic

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import <Foundation/Foundation.h>
#import "MKNetworkOperation.h"

/*!
 @header MKNetworkEngine.h
 @abstract   Represents a subclassable Network Engine for your app
 */

/*!
 *  @class MKNetworkEngine
 *  @abstract Represents a subclassable Network Engine for your app
 *  
 *  @discussion
 *	This class is the heart of MKNetworkEngine
 *  You create network operations and enqueue them here
 *  MKNetworkEngine encapsulates a Reachability object that relieves you of managing network connectivity losses
 *  MKNetworkEngine also allows you to provide custom header fields that gets appended automatically to every request
 */
@interface MKNetworkEngine : NSObject

/*!
 *  @abstract Initializes your network engine with a hostname and custom header fields
 *  
 *  @discussion
 *	Creates an engine for a given host name
 *  The default headers you specify here will be appened to every operation created in this engine
 *  The hostname, if not null, initializes a Reachability notifier.
 *  Network reachability notifications are automatically taken care of by MKNetworkEngine
 *  Both parameters are optional
 *  
 */
- (id) initWithHostName:(NSString*) hostName customHeaderFields:(NSDictionary*) headers;

/*!
 *  @abstract Creates a simple GET Operation with a request URL
 *  
 *  @discussion
 *	Creates an operation with the given URL path.
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The HTTP Method is implicitly assumed to be GET
 *  
 */

-(MKNetworkOperation*) operationWithPath:(NSString*) path;

/*!
 *  @abstract Creates a simple GET Operation with a request URL and parameters
 *  
 *  @discussion
 *	Creates an operation with the given URL path.
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The body dictionary in this method gets attached to the URL as query parameters
 *  The HTTP Method is implicitly assumed to be GET
 *  
 */
-(MKNetworkOperation*) operationWithPath:(NSString*) path
                         params:(NSMutableDictionary*) body;

/*!
 *  @abstract Creates a simple GET Operation with a request URL, parameters and HTTP Method
 *  
 *  @discussion
 *	Creates an operation with the given URL path.
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The params dictionary in this method gets attached to the URL as query parameters if the HTTP Method is GET/DELETE
 *  The params dictionary is attached to the body if the HTTP Method is POST/PUT
 *  The HTTP Method is implicitly assumed to be GET
 */
-(MKNetworkOperation*) operationWithPath:(NSString*) path
                         params:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method;

/*!
 *  @abstract Creates a simple GET Operation with a request URL, parameters, HTTP Method and the SSL switch
 *  
 *  @discussion
 *	Creates an operation with the given URL path.
 *  The ssl option when true changes the URL to https.
 *  The ssl option when false changes the URL to http.
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The params dictionary in this method gets attached to the URL as query parameters if the HTTP Method is GET/DELETE
 *  The params dictionary is attached to the body if the HTTP Method is POST/PUT
 *  The previously mentioned methods operationWithPath: and operationWithPath:params: call this internally
 */
-(MKNetworkOperation*) operationWithPath:(NSString*) path
                         params:(NSMutableDictionary*) body
                   httpMethod:(NSString*)method 
                          ssl:(BOOL) useSSL;


/*!
 *  @abstract Creates a simple GET Operation with a request URL
 *  
 *  @discussion
 *	Creates an operation with the given absolute URL.
 *  The hostname of the engine is *NOT* prefixed
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The HTTP method is implicitly assumed to be GET.
 */
-(MKNetworkOperation*) operationWithURLString:(NSString*) urlString;

/*!
 *  @abstract Creates a simple GET Operation with a request URL and parameters
 *  
 *  @discussion
 *	Creates an operation with the given absolute URL.
 *  The hostname of the engine is *NOT* prefixed
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The body dictionary in this method gets attached to the URL as query parameters
 *  The HTTP method is implicitly assumed to be GET.
 */
-(MKNetworkOperation*) operationWithURLString:(NSString*) urlString
                                       params:(NSMutableDictionary*) body;

/*!
 *  @abstract Creates a simple Operation with a request URL, parameters and HTTP Method
 *  
 *  @discussion
 *	Creates an operation with the given absolute URL.
 *  The hostname of the engine is *NOT* prefixed
 *  The default headers you specified in your MKNetworkEngine subclass gets added to the headers
 *  The params dictionary in this method gets attached to the URL as query parameters if the HTTP Method is GET/DELETE
 *  The params dictionary is attached to the body if the HTTP Method is POST/PUT
 *	This method can be over-ridden by subclasses to tweak the operation creation mechanism.
 *  You would typically over-ride this method to create a subclass of MKNetworkOperation (if you have one). After you create it, you should call [super prepareHeaders:operation] to attach any custom headers from super class.
 *  @seealso
 *  prepareHeaders:
 */
-(MKNetworkOperation*) operationWithURLString:(NSString*) urlString
                              params:(NSMutableDictionary*) body
                        httpMethod:(NSString*) method;

/*!
 *  @abstract adds the custom default headers
 *  
 *  @discussion
 *	This method adds custom default headers to the factory created MKNetworkOperation.
 *	This method can be over-ridden by subclasses to add more default headers if necessary.
 *  You would typically over-ride this method if you have over-ridden operationWithURLString:params:httpMethod:.
 *  @seealso
 *  operationWithURLString:params:httpMethod:
 */

-(void) prepareHeaders:(MKNetworkOperation*) operation;
/*!
 *  @abstract Handy helper method for fetching images
 *  
 *  @discussion
 *	Creates an operation with the given image URL.
 *  The hostname of the engine is *NOT* prefixed.
 *  The image is returned to the caller via MKNKImageBlock callback block. 
 */
- (MKNetworkOperation*)imageAtURL:(NSURL *)url onCompletion:(MKNKImageBlock) imageFetchedBlock;
/*!
 *  @abstract Enqueues your operation into the shared queue
 *  
 *  @discussion
 *	The operation you created is enqueued to the shared queue. If the response for this operation was previously cached, the cached data will be returned.
 *  @seealso
 *  enqueueOperation:forceReload:
 */
-(void) enqueueOperation:(MKNetworkOperation*) request;

/*!
 *  @abstract Enqueues your operation into the shared queue.
 *  
 *  @discussion
 *	The operation you created is enqueued to the shared queue. 
 *  When forceReload is NO, this method behaves like enqueueOperation:
 *  When forceReload is YES, No cached data will be returned even if cached data is available.
 *  @seealso
 *  enqueueOperation:
 */
-(void) enqueueOperation:(MKNetworkOperation*) operation forceReload:(BOOL) forceReload;

/*!
 * @abstract Manually override the number of conncurrent connections allowed
 * 
 * @discussion
 * Sets the number of concurrent connections to the number supplied.
 * Ordinarliy, the number is dynamically assigned based on connectivity type.
 */
-(void) overrideConcurrentOperations:(NSInteger)concurrentOperations;

/*!
 *  @abstract HostName of the engine
 *  @property readonlyHostName
 *  
 *  @discussion
 *	Returns the host name of the engine
 *  This property is readonly cannot be updated. 
 *  You normally initialize an engine with its hostname using the initWithHostName:customHeaders: method
 */
@property (readonly, strong, nonatomic) NSString *readonlyHostName;

/*!
 *  @abstract Cache Directory Name
 *  
 *  @discussion
 *	This method can be over-ridden by subclasses to provide an alternative cache directory
 *  The default directory (MKNetworkKitCache) within the NSCaches directory will be used otherwise
 *  Overriding this method is optional
 */
-(NSString*) cacheDirectoryName;

/*!
 *  @abstract Cache Directory In Memory Cost
 *  
 *  @discussion
 *	This method can be over-ridden by subclasses to provide an alternative in memory cache size.
 *  By default, MKNetworkKit caches 10 recent requests in memory
 *  The default size is 10
 *  Overriding this method is optional
 */
-(int) cacheMemoryCost;

/*!
 *  @abstract Enable Caching
 *  
 *  @discussion
 *	This method should be called explicitly to enable caching for this engine.
 *  By default, MKNetworkKit doens't cache your requests.
 *  The cacheMemoryCost and cacheDirectoryName will be used when you turn caching on using this method.
 */
-(void) useCache;

/*!
 * @abstract Cancel operations with a specific tag
 *
 * @discussion
 * This method enumerates through all operations in the queue, and cancels any matching the given tag
 */
-(void)cancelAllOperationsWithTag:(NSInteger)tag;
@end
