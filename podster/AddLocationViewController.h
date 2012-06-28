//
//  AddLocationViewController.h
//  podster
//
//  Created by Stephen Vanterpool on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface AddLocationViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, UITextFieldDelegate>
@property(weak, nonatomic) IBOutlet MKMapView *mapView;
@property(weak, nonatomic) IBOutlet UIButton *addButton;

- (IBAction)addButtonTapped:(id)sender;

@property(weak, nonatomic) IBOutlet UITextField *nameTextField;
@property(weak, nonatomic) IBOutlet UILabel *nameLabel;

- (IBAction)textValueChanged:(id)sender;

@end
