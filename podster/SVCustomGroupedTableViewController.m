//
// Created by svanter on 7/15/12.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "SVCustomGroupedTableViewController.h"
#import "SVInsetLabel.h"


@implementation SVCustomGroupedTableViewController {

}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"background-gradient.jpg"]];
    self.tableView.backgroundView = imageView;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SVInsetLabel *label = [[SVInsetLabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 30)];
    label.font = [UIFont boldSystemFontOfSize:23];
    label.insets = UIEdgeInsetsMake(0, 20, 0, 20);
    label.backgroundColor = [UIColor clearColor];
    label.text = [self tableView:self.tableView
         titleForHeaderInSection:section];
    label.numberOfLines = 0;
    label.textColor = [UIColor whiteColor];
    [label resizeHeightToFitText];

    return label;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {

    SVInsetLabel *label = [[SVInsetLabel alloc] initWithFrame:CGRectMake(0, 10, self.tableView.frame.size.width, 50)];
    label.font = [UIFont systemFontOfSize:13];
    label.insets = UIEdgeInsetsMake(10, 20, 10, 20);
    label.textAlignment = UITextAlignmentCenter;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.text = [self tableView:self.tableView
         titleForFooterInSection:section];
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    [label resizeHeightToFitText];
    return label;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    UIView *footerView = [self tableView:tableView viewForFooterInSection:section];
    return footerView.frame.size.height;
}

@end