//
//  RHExtendedManagedObject.m
//  SimplifiedCoreDataExample
//
//  Created by David De Bels on 22/11/13.
//
//

#import "RHExtendedManagedObject.h"

static NSString* kRHRuntimePropertiesKey = @"kRHRuntimePropertiesKey";


@interface RHExtendedManagedObject ()

@property (nonatomic, readonly) NSMutableDictionary* additionalProperties;

@end


@implementation RHExtendedManagedObject

@dynamic additionalData;

#pragma mark - Get or set additional properties

-(NSMutableDictionary*)additionalProperties
{
    if (!_additionalProperties)
    {
        _additionalProperties = [self readAdditionalData];
        
        if (!_additionalProperties)
            _additionalProperties = [[NSMutableDictionary alloc] init];
    }
    
    return _additionalProperties;
}

-(void)setAdditionalDateProperty:(NSDate*)date forKey:(NSString*)key
{
    if (date == nil || [date isKindOfClass:[NSDate class]])
        [self setAdditionalValue:date forKey:key];
}

-(void)setAdditionalNumberProperty:(NSNumber*)number forKey:(NSString*)key
{
    if (number == nil || [number isKindOfClass:[NSNumber class]])
        [self setAdditionalValue:number forKey:key];
}

-(void)setAdditionalStringProperty:(NSString*)string forKey:(NSString*)key
{
    if (string == nil || [string isKindOfClass:[NSString class]])
        [self setAdditionalValue:string forKey:key];
}

-(void)setAdditionalValue:(id)value forKey:(NSString*)key
{
    if (!key)
        return;
    
    if (value)
        [self.additionalProperties setObject:value forKey:key];
    else
        [self.additionalProperties removeObjectForKey:key];
    
    _needsUpdate = YES;
}

-(id)additionalPropertyForKey:(NSString*)key
{
    return [self.additionalProperties objectForKey:key];
}

-(void)willSave
{
    [super willSave];
    [self writeAdditionalData];
}



#pragma mark - Read or write the additionalData

-(NSMutableDictionary*)readAdditionalData
{
    if ([self respondsToSelector:@selector(additionalData)])
    {
        NSDictionary* dataDictionary = nil;
        
        NSData* data = [self performSelector:@selector(additionalData)];
        if (data)
        {
            NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
            dataDictionary = [unarchiver decodeObjectForKey:kRHRuntimePropertiesKey];
            [unarchiver finishDecoding];
        }
        
        return [dataDictionary mutableCopy];
    }
    
    return nil;
}

-(void)writeAdditionalData
{
    if (_needsUpdate && [self respondsToSelector:@selector(setAdditionalData:)])
    {
        NSMutableData* data = [[NSMutableData alloc] init];
        NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:self.additionalProperties forKey:kRHRuntimePropertiesKey];
        [archiver finishEncoding];
        
        [self performSelector:@selector(setAdditionalData:) withObject:data];
        _needsUpdate = NO;
    }
}

@end
