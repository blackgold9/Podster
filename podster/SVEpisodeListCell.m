//
//  SVEpisodeListCell.m
//  podster
//
//  Created by Vanterpool, Stephen on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SVEpisodeListCell.h"
#import "SVPodcastEntry.h"
#import "NSString+MW_HTML.h"
@implementation SVEpisodeListCell
@synthesize downloadedIndicator, subtitleLabel, titleLabel, durationLabel,dateLabel, unplayedIndicator;
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

-(void)bind:(SVPodcastEntry *)entry
{
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter){
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setLocale:[NSLocale currentLocale]];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setDoesRelativeDateFormatting:YES];
    }
    self.dateLabel.text = [dateFormatter stringFromDate:entry.datePublished];
    self.titleLabel.text = entry.title;
    self.subtitleLabel.text = [entry.summary stringByConvertingHTMLToPlainText];
    self.durationLabel.text =[NSString formattedStringRepresentationOfSeconds: [entry.duration integerValue]];
    self.downloadedIndicator.hidden = !entry.downloadCompleteValue;
    self.unplayedIndicator.hidden = YES;//entry.playedValue;
}
@end
