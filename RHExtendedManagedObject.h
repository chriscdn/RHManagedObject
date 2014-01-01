//
//  RHExtendedManagedObject.h
//  SimplifiedCoreDataExample
//
//  Created by David De Bels on 22/11/13.
//
//

#import "RHManagedObject.h"

@interface RHExtendedManagedObject : RHManagedObject
{
@protected
    
    // Internal boolean to track whether or not to update the additionalData on save
    BOOL _needsUpdate;
    
@private
    
    NSMutableDictionary* _additionalProperties;
}

@property (nonatomic, retain) NSData * additionalData;

-(id)additionalPropertyForKey:(NSString*)key;

-(void)setAdditionalDateProperty:(NSDate*)date forKey:(NSString*)key;
-(void)setAdditionalNumberProperty:(NSNumber*)number forKey:(NSString*)key;
-(void)setAdditionalStringProperty:(NSString*)string forKey:(NSString*)key;

@end
