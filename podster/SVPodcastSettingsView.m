//
//  SVPodcastSettingsView.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVPodcastSettingsView.h"
#import "JMTabView.h"
@implementation SVPodcastSettingsView
@synthesize sortTabBar;
@synthesize hidePlayedEpsodesSwitch;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        JMTabView *tabView = [[JMTabView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [tabView addTabItemWithTitle:@"Newest First" icon:nil];
        [tabView addTabItemWithTitle:@"Oldest First" icon:nil];
        [tabView setSelectedIndex:0];
        [self addSubview:tabView];
        self.clipsToBounds = YES;
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
          }
    return self;
}

-(void)layoutSubviews
{
    self.sortTabBar.frame =  CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
