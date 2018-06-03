//
//  PinsListVC.h
//  Magneto
//
//  Created by Serhii Simkovskyi on May/29/18.
//  Copyright © 2018 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Magneto+CoreDataModel.h"

@class EditPinVC;

@interface PinsListVC : UITableViewController <NSFetchedResultsControllerDelegate>

@property (strong, nonatomic) EditPinVC *editPinVC;
@property (strong, nonatomic) NSFetchedResultsController<Pin *> *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
