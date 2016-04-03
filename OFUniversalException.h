#import <ObjFW/OFObject.h>
#import <ObjFW/OFException.h>

@class OFString;
@class OFConstantString;

@interface OFUniversalException: OFException
{
	OFString* _name;
	OFString* _message;
}

- (instancetype)initWithName:(OFString *)name message:(OFString *)message;
- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt, ...;
- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args;
+ (instancetype)exceptionWithName:(OFString *)name message:(OFString *)message;
+ (instancetype)exceptionWithName:(OFString *)name format:(OFConstantString *)frmt, ...;

@end