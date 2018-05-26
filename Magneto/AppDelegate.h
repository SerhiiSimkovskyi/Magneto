//
//  AppDelegate.h
//  Magneto
//
//  Created by Serhii Simkovskyi on May/26/18.
//  Copyright © 2018 Serhii Simkovskyi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

