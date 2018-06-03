//
//  ViewController.h
//  Magneto
//
//  Created by Serhii Simkovskyi on May/26/18.
//  Copyright © 2018 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Magneto+CoreDataModel.h"

@interface MainVC : UIViewController <MKMapViewDelegate, NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@property (strong, nonatomic) NSFetchedResultsController<Pin *> *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

