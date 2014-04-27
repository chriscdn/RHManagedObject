//
//  EmployeeEntity.h
//  SimplifiedCoreDataExample
//
//  Created by Christopher Meyer on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "RHManagedObject.h"

@interface EmployeeEntity : RHManagedObject

@property (nonatomic, strong) NSString * firstName;
@property (nonatomic, strong) NSString * lastName;

@end
