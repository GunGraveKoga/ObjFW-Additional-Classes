#import <ObjFW/OFObject.h>
#import <ObjFW/OFException.h>
#import "objfwext_macros.h"

@class OFString;
@class OFConstantString;
@class OFDictionary;


OBJFW_EXTENSION_EXPORT OFString *const kOFSourceFile;
OBJFW_EXTENSION_EXPORT OFString *const kOFSourceFunction;
OBJFW_EXTENSION_EXPORT OFString *const kOFSourceLine;
OBJFW_EXTENSION_EXPORT OFString *const kOFSourceClass;

@interface OFUniversalException: OFException
{
	OFString* _name;
	OFString* _reason;
	OFDictionary* _userInfo;
}

@property(nonatomic, readonly, copy)OFString* name;
@property(nonatomic, readonly, copy)OFString* reason;
@property(nonatomic, readonly, copy)OFDictionary* userInfo;

- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt, ...;
- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args;
- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args userInfo:(OFDictionary *)userInfo;
+ (instancetype)exceptionWithName:(OFString *)name format:(OFConstantString *)frmt, ...;
+ (instancetype)exceptionWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args;
+ (instancetype)exceptionWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args userInfo:(OFDictionary *)userInfo;

@end


@interface OFException(UniversalException)
- (void)raise;
+ (void)raise:(OFString *)name format:(OFConstantString *)frmt, ...;
+ (void)raise:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args;
+ (id)exceptionWithName:(OFString *)name reason:(OFString *)reason userInfo:(OFDictionary *)userInfo;
+ (void)showSourceInfo:(bool)flag;
@end