#import <ObjFW/ObjFW.h>
#import "OFError.h"

OFString *const OFVendorErrorCode = @"OFVendorErrorCode";
OFString *const OFVendorErrorString = @"OFVendorErrorString";
OFString *const OFErrorDescription = @"OFErrorDescription";
OFString *const OFErrorFileName = @"OFErrorFileName";
OFString *const OFErrorFunction = @"OFErrorFunction";
OFString *const OFErrorLineNumber = @"OFErrorLineNumber";

@interface OFError()

@property(nonatomic, readwrite)int32_t errorCode;
@property(nonatomic, copy, readwrite)OFString* errorSource;
@property(nonatomic, copy, readwrite)OFDictionary* userInfo;

@end

@implementation OFError{
    int32_t _errorCode;
    OFString* _errorSource;
    OFDictionary* _userInfo;
}

@synthesize errorCode = _errorCode;
@synthesize errorSource = _errorSource;
@synthesize userInfo = _userInfo;
@dynamic file;
@dynamic function;
@dynamic line;

- (instancetype)initWithSource:(OFString *)source code:(int32_t)code userInfo:(OFDictionary *)userInfo
{
	self = [super init];

	self.errorCode = code;
	self.errorSource = source;
	self.userInfo = userInfo;

	return self;
}

+ (instancetype)errorWithSource:(OFString *)source code:(int32_t)code userInfo:(OFDictionary *)userInfo
{
	return [[[self alloc] initWithSource:source code:code userInfo:userInfo] autorelease];
}

- (OFString *)file
{
	OFString* _file = [self.userInfo objectForKey:OFErrorFileName];

	if (_file != nil) {
		_file = [_file copy];
		return [_file autorelease];
	}

	return _file;
}

- (OFString *)function
{
	OFString* _function = [self.userInfo objectForKey:OFErrorFunction];

	if (_function != nil) {
		_function = [_function copy];
		return [_function autorelease];
	}

	return _function;
}

- (OFNumber *)line
{
	OFNumber* _line = [self.userInfo objectForKey:OFErrorLineNumber];

	if (_line != nil) {
		_line = [_line copy];
		return [_line autorelease];
	}

	return _line;
}

- (OFString *)description
{
	if (_userInfo != nil) {
		OFNumber* vendorErrNo = [self.userInfo objectForKey:OFVendorErrorCode];
		OFString* vendorDescrition = [self.userInfo objectForKey:OFVendorErrorString];
		OFString* internalDescription = [self.userInfo objectForKey:OFErrorDescription];

		if (vendorErrNo != nil) {
			if (vendorDescrition != nil) {
				return [OFString stringWithFormat:@"%@ %@: %@", self.errorSource, vendorErrNo, vendorDescrition];
			} else {
				if (internalDescription != nil)
					return [OFString stringWithFormat:@"%@ %@: %@", self.errorSource, vendorErrNo, internalDescription];
				else
					return [OFString stringWithFormat:@"%@ %@", self.errorSource, vendorErrNo];
			}

		} else {
			if (vendorDescrition) {
				return [OFString stringWithFormat:@"%@ %d: %@", self.errorSource, self.errorCode, vendorDescrition];
			} else if (internalDescription) {
				return [OFString stringWithFormat:@"%@ %d: %@", self.errorSource, self.errorCode, internalDescription];
			}
		}
	}

	return [OFString stringWithFormat:@"%@ %d", self.errorSource, self.errorCode];
}

@end
