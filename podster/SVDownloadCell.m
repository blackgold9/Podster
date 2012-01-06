//
//  SVDownloadCell.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVDownloadCell.h"

@implementation SVDownloadCell
@synthesize progressBar, titleLabel;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}



@end
