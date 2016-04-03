#import <ObjFW/OFObject.h>

@class OFString;
@class OFDictionary;
@class OFNumber;


extern OFString *const OFVendorErrorCode;
extern OFString *const OFVendorErrorString;
extern OFString *const OFErrorDescription;
extern OFString *const OFErrorFileName;
extern OFString *const OFErrorFunction;
extern OFString *const OFErrorLineNumber;

@interface OFError: OFObject
{
	int32_t _errorCode;
	OFString* _errorSource;
	OFDictionary* _userInfo;
}

@property(readonly)int32_t errorCode;
@property(copy, readonly)OFString* errorSource;
@property(copy, readonly)OFDictionary* userInfo;
@property(copy, readonly)OFString* file;
@property(copy, readonly)OFString* function;
@property(copy, readonly)OFNumber* line;

- (instancetype)initWithSource:(OFString *)source code:(int32_t)code userInfo:(OFDictionary *)userInfo;
+ (instancetype)errorWithSource:(OFString *)source code:(int32_t)code userInfo:(OFDictionary *)userInfo;

@end