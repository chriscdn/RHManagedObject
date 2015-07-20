// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Employee.h instead.

#import <CoreData/CoreData.h>
#import "RHManagedObject.h"

extern const struct EmployeeAttributes {
	__unsafe_unretained NSString *firstName;
	__unsafe_unretained NSString *lastName;
} EmployeeAttributes;

@interface EmployeeID : NSManagedObjectID {}
@end

@interface _Employee : RHManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
@property (nonatomic, readonly, strong) EmployeeID* objectID;

@property (nonatomic, strong) NSString* firstName;

//- (BOOL)validateFirstName:(id*)value_ error:(NSError**)error_;

@property (nonatomic, strong) NSString* lastName;

//- (BOOL)validateLastName:(id*)value_ error:(NSError**)error_;

@end

@interface _Employee (CoreDataGeneratedPrimitiveAccessors)

- (NSString*)primitiveFirstName;
- (void)setPrimitiveFirstName:(NSString*)value;

- (NSString*)primitiveLastName;
- (void)setPrimitiveLastName:(NSString*)value;

@end
