#import <ObjFW/OFObject.h>

OF_ASSUME_NONNULL_BEGIN

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

@property(nonatomic, readonly)int32_t errorCode;
@property(nonatomic, copy, readonly)OFString* errorSource;
@property(nonatomic, copy, readonly)OFDictionary* userInfo;
@property(nonatomic, copy, readonly)OFString* file;
@property(nonatomic, copy, readonly)OFString* function;
@property(nonatomic, copy, readonly)OFNumber* line;

- (instancetype)initWithSource:(OFString *)source code:(int32_t)code userInfo:(OFDictionary * _Nullable)userInfo;
+ (instancetype)errorWithSource:(OFString *)source code:(int32_t)code userInfo:(OFDictionary * _Nullable)userInfo;

@end


OF_ASSUME_NONNULL_END
