#import <ObjFW/OFObject.h>
#import <ObjFW/OFException.h>

@class OFString;
@class OFConstantString;
@class OFDictionary;

#ifdef __cplusplus
#define EXCEPTION_CONSTANT_EXPORT extern "C"
#else
#define EXCEPTION_CONSTANT_EXPORT extern
#endif

EXCEPTION_CONSTANT_EXPORT OFString *const kSourceFile;
EXCEPTION_CONSTANT_EXPORT OFString *const kSourceFunction;
EXCEPTION_CONSTANT_EXPORT OFString *const kSourceLine;
EXCEPTION_CONSTANT_EXPORT OFString *const kSourceClass;

@interface OFUniversalException: OFException
{
	OFString* _name;
	OFString* _reason;
	OFDictionary* _userInfo;
}

@property(readonly, copy)OFString* name;
@property(readonly, copy)OFString* reason;
@property(readonly, copy)OFDictionary* userInfo;

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