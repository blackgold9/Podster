//
// Created by svanter on 7/11/12.
//
// To change the template use AppCode | Preferences | File Templates.
//

#import <UIKit/UIKit.h>
@protocol CoreDataController <NSObject>
@property (nonatomic, retain) NSManagedObjectContext *context;
@end