//
//  EditPinVC.h
//  Magneto
//
//  Created by Serhii Simkovskyi on May/29/18.
//  Copyright © 2018 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Magneto+CoreDataModel.h"
#import <CoreLocation/CoreLocation.h>

@interface EditPinVC : UIViewController <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@property (weak, nonatomic) IBOutlet UITextField *editTitle;
@property (weak, nonatomic) IBOutlet UITextField *editSubtitle;
@property (weak, nonatomic) IBOutlet UITextField *editLatitude;
@property (weak, nonatomic) IBOutlet UITextField *editLongitude;
@property (weak, nonatomic) IBOutlet UILabel *labelProgress;

@property (weak, nonatomic) UITextField *activeField; // to keep track of which edit field is active

@property (strong, nonatomic) CLLocationManager* locationManager;

// === INPUT =========================================================
@property (assign, nonatomic) NSInteger pinIndex; // must be passed from master view!
@property (strong, nonatomic) NSFetchedResultsController<Pin *> *fetchedResultsController; // must be passed from master view!
// ===================================================================

@end
