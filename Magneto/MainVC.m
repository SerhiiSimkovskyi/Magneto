//
//  ViewController.m
//  Magneto
//
//  Created by Serhii Simkovskyi on May/26/18.
//  Copyright © 2018 Serhii Simkovskyi. All rights reserved.
//
#import <MapKit/MKAnnotation.h>
#import "MainVC.h"
#import "AppDelegate.h"

@interface MainVC ()
@end

@implementation MainVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.managedObjectContext = ((AppDelegate*)[[UIApplication sharedApplication] delegate]).persistentContainer.viewContext;
    [self.mapView setDelegate:self];

    // if database is empty then create a default set of annotations
    [self addDefaultAnnotations];
    
    // add annotations and segments to the map view
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    [self setupMapOverlays];
    
    // set initial zoom level
    [self actionZoomOut:nil];
}

// ============================================================================
#pragma mark - MKMapViewDelegate
// ============================================================================

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    
    MKPolylineRenderer *polylineRenderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    polylineRenderer.strokeColor = [UIColor redColor];
    polylineRenderer.lineWidth = 0.5;
    return polylineRenderer;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    static NSString *identifier = @"MagnetoPoint";
    if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
        
        MKMarkerAnnotationView* annotationView = (MKMarkerAnnotationView *) (MKMarkerAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKMarkerAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            annotationView.enabled = YES;
            annotationView.clusteringIdentifier = @"pins";
            annotationView.glyphImage = [UIImage imageNamed:@"m.png"]; //here we use a nice image instead of the default pins
        } else {
            annotationView.annotation = annotation;
            annotationView.clusteringIdentifier = @"pins";
        }
        return annotationView;
    }
    return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    if ([view.annotation isKindOfClass:[MKClusterAnnotation class]]) {
        
        //
        // calculate view region that displays all colapsed/clustered annotations
        //
        
        MKClusterAnnotation* cluster = (MKClusterAnnotation*)view.annotation;
        
        // Find mim/max longitude and latitude amoung all collapsed annotations
        BOOL first=true;
        CLLocationDegrees minLatitude=0;
        CLLocationDegrees maxLatitude=0;
        CLLocationDegrees minLongitude=0;
        CLLocationDegrees maxLongitude=0;
        
        for (id<MKAnnotation> memberAnnotation in cluster.memberAnnotations) {
            if (first) {
                minLatitude = memberAnnotation.coordinate.latitude;
                maxLatitude = memberAnnotation.coordinate.latitude;
                minLongitude = memberAnnotation.coordinate.longitude;
                maxLongitude = memberAnnotation.coordinate.longitude;
                first = NO;
            } else {
                if (minLatitude > memberAnnotation.coordinate.latitude)
                    minLatitude = memberAnnotation.coordinate.latitude;
                if (maxLatitude < memberAnnotation.coordinate.latitude)
                    maxLatitude = memberAnnotation.coordinate.latitude;
                if (minLongitude > memberAnnotation.coordinate.longitude)
                    minLongitude = memberAnnotation.coordinate.longitude;
                if (maxLongitude < memberAnnotation.coordinate.longitude)
                    maxLongitude = memberAnnotation.coordinate.longitude;
            }
        }

        // calc deltas. Increase deltas by 20% (otherwise annotation points will be too close to screen edges)
        CLLocationDegrees longitudeDelta = fabs(maxLongitude - minLongitude)*1.2;
        CLLocationDegrees latitudeDelta = fabs(maxLatitude - minLatitude)*1.2;

        // calculate span
        MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
        
        // make and set region based on calculated span
        MKCoordinateRegion viewRegion = MKCoordinateRegionMake(view.annotation.coordinate, span);
        [_mapView setRegion:viewRegion animated:YES];
        
    } else {
        // make region that displays annotation the center with 500m..500m zoom
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(view.annotation.coordinate, 500, 500);
        [_mapView setRegion:viewRegion animated:YES];
    }
}

// Return nil for default MKClusterAnnotation, it is illegal to return a cluster annotation not containing the identical array of member annotations given.
- (MKClusterAnnotation *)mapView:(MKMapView *)mapView clusterAnnotationForMemberAnnotations:(NSArray<id<MKAnnotation>>*)memberAnnotations {
    MKClusterAnnotation *clusterAnnotation = [[MKClusterAnnotation alloc] initWithMemberAnnotations:memberAnnotations];
    return clusterAnnotation;
}

// ============================================================================
#pragma mark - Actions
// ============================================================================

- (IBAction)actionZoomOut:(id)sender {
    
    // Setup center point: London, UK
    CLLocationCoordinate2D zoomCenter;
    zoomCenter.latitude = 51.509865;
    zoomCenter.longitude= -0.118092;
    
    // Create maximum available span
    CLLocationDegrees longitudeDelta = 360;
    CLLocationDegrees latitudeDelta = 180;
    MKCoordinateSpan span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta);
    
    // Create and set region to be displayed
    MKCoordinateRegion viewRegion = MKCoordinateRegionMake(zoomCenter, span);
    [_mapView setRegion:viewRegion animated:YES];
}

- (IBAction)actionExport:(id)sender {
    
    BOOL isSuccessful = true;
    NSString* errorMessage = @"";
    
    // create file path
    NSString *path;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"TMP"];

    // CREATE DIR IF needed
    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSError *error;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:&error])
        {
            isSuccessful = false;
            errorMessage = [NSString stringWithFormat:@"Error creating directory: %@", error];
        }
    }
    if (!isSuccessful) return;
    
    // add filename to the path
    path = [path stringByAppendingPathComponent:@"magneto.xml"];
    
    // DELETE FILE IF ANY
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) // File  exists
    {
        NSError *error;
        
        if (![[NSFileManager defaultManager] removeItemAtPath:path error:&error])    //Delete it
        {
            isSuccessful = false;
            errorMessage = [NSString stringWithFormat:@"Error deleting file (%@): %@", @"magneto.xml", error];
        }
    }
    if (!isSuccessful) return;

    // CREATE NEW FILE
    if (![[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil])
    {
        isSuccessful = false;
        errorMessage = [NSString stringWithFormat:@"Error creating file: %@", @"magneto.xml"];
    }
    
    if (!isSuccessful) return;
    
    NSFileHandle* file = [NSFileHandle fileHandleForWritingAtPath:path];
    
    // <XML>
    [file writeData: [@"<xml>\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    // export pins
    NSArray<Pin*> *pins = [self.fetchedResultsController fetchedObjects];
    for (Pin *pin in pins) {
        NSString* s = [NSString stringWithFormat:@"<pin><title>%@</title><subtitle>%@</subtitle><lat>%f</lat><lon>%f</lon></pin>",
                       pin.title, pin.subtitle, pin.lat, pin.lon];
        [file writeData: [s dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    // </XML>
    [file writeData: [@"</xml>\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [file closeFile];
    
    // === Share file ==================================
    NSURL* url = [NSURL fileURLWithPath:path];
    NSArray *items = @[url];
    
    // build an activity view controller
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    
    // and present it
    
    // for iPad: make the presentation a Popover
    controller.modalPresentationStyle = UIModalPresentationPopover;
    [self presentViewController:controller animated:YES completion:nil];
    
    UIPopoverPresentationController *popController = [controller popoverPresentationController];
    popController.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    // access the completion handler
    controller.completionWithItemsHandler = ^(NSString *activityType,
                                              BOOL completed,
                                              NSArray *returnedItems,
                                              NSError *error){
        // cleanup tmp folder
        // ..
        
        // react to the completion
        if (completed) {
            // user shared an item
            NSLog(@"We used activity type%@", activityType);
        } else {
            // user cancelled
            NSLog(@"We didn't want to share anything after all.");
        }
        
        if (error) {
            NSLog(@"An Error occured: %@, %@", error.localizedDescription, error.localizedFailureReason);
        }
    };
}

// ============================================================================
#pragma mark - Map Overlay from Core Data
// ============================================================================

- (CLLocationCoordinate2D) makeCoordinateWithLat: (double) latitude lon:(double) longitude {
    CLLocationCoordinate2D c;
    c.latitude = latitude;
    c.longitude = longitude;
    return c;
}

- (void) setupMapOverlays {
    
    NSArray<Pin*> *pins = [self.fetchedResultsController fetchedObjects];
    NSInteger count = [pins count];
    
    // Add points
    for (Pin *pin in pins) {
        MKPointAnnotation *point = [[MKPointAnnotation alloc] init];
        point.coordinate = [self makeCoordinateWithLat:pin.lat lon:pin.lon];
        point.title = pin.title;
        point.subtitle = pin.subtitle;
        [self.mapView addAnnotation:point];
    }
    
    // add segments
    for (NSInteger ix=0; ix<count; ix++) {
        for (NSInteger iy=ix+1; iy<count; iy++) {
            CLLocationCoordinate2D segment[2];
            segment[0] = [self makeCoordinateWithLat:pins[ix].lat lon:pins[ix].lon];
            segment[1] = [self makeCoordinateWithLat:pins[iy].lat lon:pins[iy].lon];
            MKPolyline *polyLine = [MKPolyline polylineWithCoordinates:segment count:2];
            [self.mapView addOverlay:polyLine];
        }
    }
}

// ============================================================================
#pragma mark - Core data utils
// ============================================================================

- (void)addDefaultAnnotations {

    // only create default Annotations if the list is empty
    if ([[self.fetchedResultsController fetchedObjects] count] > 0)
        return;
    
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    
    double order = 10.;
    
    Pin *aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Odessa, Ukraine";
    aPin.subtitle = @"";
    aPin.lat = 46.469391;
    aPin.lon = 30.740883;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"New York, USA";
    aPin.subtitle = @"";
    aPin.lat = 40.730610;
    aPin.lon = -73.935242;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"San Francisco, USA";
    aPin.subtitle = @"";
    aPin.lat = 37.773972;
    aPin.lon = -122.431297;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Taj Mahal, India";
    aPin.subtitle = @"";
    aPin.lat = 27.173891;
    aPin.lon = 78.042068;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Great Wall of China, China";
    aPin.subtitle = @"";
    aPin.lat = 40.431908;
    aPin.lon =  116.570374;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"London, UK";
    aPin.subtitle = @"";
    aPin.lat = 51.509865;
    aPin.lon = -0.1180921;
    aPin.order = order;
    order += 10.;
    
    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Oxford, UK";
    aPin.subtitle = @"";
    aPin.lat = 51.752022;
    aPin.lon = -1.257677;
    aPin.order = order;
    order += 10.;
    
    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Cardiff, UK";
    aPin.subtitle = @"";
    aPin.lat = 51.481583;
    aPin.lon = -3.179090;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Berlin, Germany";
    aPin.subtitle = @"";
    aPin.lat = 52.520008;
    aPin.lon = 13.404954;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Rome, Italy";
    aPin.subtitle = @"";
    aPin.lat = 41.902782;
    aPin.lon = 12.496366;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Tokyo, Japan";
    aPin.subtitle = @"";
    aPin.lat = 35.652832;
    aPin.lon = 139.839478;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Auckland, New Zealand";
    aPin.subtitle = @"";
    aPin.lat = -36.848461;
    aPin.lon = 174.763336;
    aPin.order = order;
    order += 10.;
    
    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Christchurch, New Zealand";
    aPin.subtitle = @"";
    aPin.lat = -43.525650;
    aPin.lon = 172.639847;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Wellington, New Zealand";
    aPin.subtitle = @"";
    aPin.lat = -41.28664;
    aPin.lon = 174.77557;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Cape Town, South Africa";
    aPin.subtitle = @"";
    aPin.lat = -33.918861;
    aPin.lon = 18.423300;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Saquarema, State of Rio de Janeiro, Brazil";
    aPin.subtitle = @"";
    aPin.lat = -22.932398;
    aPin.lon = -42.486675;
    aPin.order = order;
    order += 10.;

    aPin = [[Pin alloc] initWithContext:context];
    aPin.title = @"Anchorage, AK, USA";
    aPin.subtitle = @"";
    aPin.lat = 61.217381;
    aPin.lon = -149.863129;
    aPin.order = order;
    order += 10.;
    
    // save context
    NSError *error = nil;
    if(![context save:&error]){
        NSLog(@"Unresolved error: %@, %@", error, [error userInfo]);
        abort();
    }
}

// ============================================================================
#pragma mark - Fetched results controller
// ============================================================================

- (NSFetchedResultsController<Pin *> *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest<Pin *> *fetchRequest = Pin.fetchRequest;
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20]; //???
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    
    [fetchRequest setSortDescriptors:@[sortDescriptor]];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController<Pin *> *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Magneto"];
    aFetchedResultsController.delegate = self;
    
    NSError *error = nil;
    if (![aFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        abort();
    }
    
    _fetchedResultsController = aFetchedResultsController;
    return _fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    [self setupMapOverlays];
}


@end
