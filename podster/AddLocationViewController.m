//
//  AddLocationViewController.m
//  podster
//
//  Created by Stephen Vanterpool on 6/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AddLocationViewController.h"

@interface AddLocationViewController ()

@end

@implementation AddLocationViewController {
    BOOL hasLocation;
    CLLocationManager *locationManager;

}
@synthesize nameTextField;
@synthesize nameLabel;
@synthesize mapView;
@synthesize addButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    hasLocation = NO;
    locationManager = [[CLLocationManager alloc] init];
    locationManager.purpose = NSLocalizedString(@"We use your location to enable smart sync to function when you change locations.", @"We use your location to enable smart sync to function when you change locations.");

    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
    self.nameTextField.returnKeyType = UIReturnKeyDone;
    self.nameTextField.delegate = self;
    self.navigationItem.title = @"Add a Location";
    // Do any additional setup after loading the view.
}

- (void)viewDidUnload {
    [self setMapView:nil];
    [self setAddButton:nil];
    [self setNameTextField:nil];
    [self setNameLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (IBAction)cancelTapped:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter]
            addObserver:self
               selector:@selector(textValueChanged:)
                   name:UITextFieldTextDidChangeNotification
                 object:self.nameTextField];
}


- (void)viewWillDisappear:(BOOL)animated {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextFieldTextDidChangeNotification object:self.nameTextField];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (IBAction)addButtonTapped:(id)sender {

    [locationManager startMonitoringForRegion:[[CLRegion alloc] initCircularRegionWithCenter:self.mapView.userLocation.coordinate radius:500 identifier:self.nameTextField.text]];
    [self dismissModalViewControllerAnimated:YES];
}

- (void)textValueChanged:(NSNotification *)notification {
    hasLocation |= self.mapView.userLocationVisible;

    self.navigationItem.rightBarButtonItem.enabled = self.nameTextField.text.length > 1 && hasLocation;
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView {

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    hasLocation |= self.mapView.userLocationVisible;
    if (self.nameTextField.text.length > 1 && hasLocation) {
        [locationManager startMonitoringForRegion:[[CLRegion alloc] initCircularRegionWithCenter:self.mapView.userLocation.coordinate radius:500 identifier:self.nameTextField.text]];
        [self dismissModalViewControllerAnimated:YES];
        return YES;
    } else {
        return NO;
    }
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    hasLocation = YES;
    self.navigationItem.rightBarButtonItem.enabled = self.nameTextField.text.length > 1 && hasLocation;
}


@end
