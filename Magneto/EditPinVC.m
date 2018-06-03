//
//  EditPinVC.m
//  Magneto
//
//  Created by Serhii Simkovskyi on May/29/18.
//  Copyright © 2018 Serhii Simkovskyi. All rights reserved.
//

#import "EditPinVC.h"

@interface EditPinVC ()

@end

@implementation EditPinVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // subscribe to keyboard showing/hiding notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    
    if (self.pinIndex < 0) { // Adding new pin
        [self.navigationItem setTitle:@"Add new pin"];
    } else { // Editing existing pin
        [self.navigationItem setTitle:@"Edit pin"];
        Pin *pin = [self.fetchedResultsController objectAtIndexPath:  [NSIndexPath indexPathForRow:self.pinIndex inSection:0]];
        self.editTitle.text = pin.title;
        self.editSubtitle.text = pin.subtitle;
        self.editLatitude.text = [[NSNumber numberWithDouble:pin.lat] stringValue];
        self.editLongitude.text = [[NSNumber numberWithDouble:pin.lon] stringValue];
    }
    self.labelProgress.text = @"";
    self.locationManager = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Actions

- (IBAction)actionCurrentLocation:(id)sender {
    self.labelProgress.text = @"Tracking current location...";
    if (self.locationManager == nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.delegate = self;
    }
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager startUpdatingLocation];
}

- (IBAction)actionSave:(id)sender {
    if (self.pinIndex < 0) { //create new pin
        // calculate order field for new pin
        double order = 10.;
        NSArray<Pin*>* pins = self.fetchedResultsController.fetchedObjects;
        if ([pins count] > 0)
        {
            order = pins[[pins count]-1].order + 10.;
        }
        
        // create new pin object in the context
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        Pin *pin = [[Pin alloc] initWithContext:context];
        pin.title = self.editTitle.text;
        pin.subtitle = self.editSubtitle.text;
        pin.lat = [self.editLatitude.text doubleValue];
        pin.lon = [self.editLongitude.text doubleValue];
        pin.order = order;
    } else { // edit existing pin
        Pin *pin = [self.fetchedResultsController objectAtIndexPath:  [NSIndexPath indexPathForRow:self.pinIndex inSection:0]];
        pin.title = self.editTitle.text;
        pin.subtitle = self.editSubtitle.text;
        pin.lat = [self.editLatitude.text doubleValue];
        pin.lon = [self.editLongitude.text doubleValue];
    }
    
    // Save the context.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)textFieldDidBeginEditing:(UITextField *)sender {
    self.activeField = sender;
}

- (IBAction)textFieldDidEndEditing:(UITextField *)sender {
    self.activeField = nil;
}

- (IBAction)returnPressed:(UITextField *)sender {
    [self resignFirstResponder];
}


#pragma mark - Keyboard notifications

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)notification {
    NSDictionary* info = [notification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    // add the height of the keyboard to the scroll view’s content inset so that
    // the scroll view has enough padding at the bottom to scroll the very bottom
    // text field up above the keyboard.
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    // As the final step, I check to see if the active text field is visible and
    // scroll the field into view if it is not.
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, self.activeField.frame.origin) ) {
        [self.scrollView scrollRectToVisible:self.activeField.frame animated:YES];
    }
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation* currentLocation = [locations objectAtIndex:0];
    [self.locationManager stopUpdatingLocation];
    self.editLatitude.text = [[NSNumber numberWithDouble:currentLocation.coordinate.latitude] stringValue];
    self.editLongitude.text = [[NSNumber numberWithDouble:currentLocation.coordinate.longitude] stringValue];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error)
     {
         if (!(error))
         {
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             self.labelProgress.text = [NSString stringWithFormat:@"Current Location Detected: \n\n%@",placemark];
         }
         else
         {
             self.labelProgress.text = [NSString stringWithFormat:@"Geocode failed with error %@", error];
         }
     }];
}

@end
