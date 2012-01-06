//
//  SVDownloadCell.h
//  podster
//
//  Created by Vanterpool, Stephen on 1/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SVDownloadCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UIProgressView *progressBar;
@end
