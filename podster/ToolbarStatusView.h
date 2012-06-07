//
//  ToolbarStatusView.h
//  podster
//
//  Created by Vanterpool, Stephen on 6/3/12.
//  Copyright (c) 2012 Amazon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ToolbarStatusView : UIView
- (id)initWithFrame:(CGRect)frame title:(NSString *)title subTitle:(NSString *)subTitle showing:(BOOL)showing animating:(BOOL)animating;

- (void)setTitle:(NSString *)title andSubTitle:(NSString *)subTitle;

- (void)setShowing:(BOOL)showing;

- (BOOL)isShowing;

- (void)setAnimating:(BOOL)animating;

- (BOOL)isAnimating;


@end
