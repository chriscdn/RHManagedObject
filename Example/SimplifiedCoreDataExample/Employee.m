//
//  Employee.m
//  SimplifiedCoreDataExample
//
//  Created by Christopher Meyer on 11/29/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Employee.h"

@implementation Employee

+(NSString *)modelName {
	return @"SimplifiedCoreDataExample";
}

-(NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
}

@end