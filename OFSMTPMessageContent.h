#import <ObjFW/OFObject.h>
#import "objfwext_macros.h"

@class OFString;
@class OFDictionary;
@class OFMutableDictionary;


OBJFW_EXTENSION_EXPORT OFString *const kOFContentDispositionKey;
OBJFW_EXTENSION_EXPORT OFString *const kOFContentTypeKey;
OBJFW_EXTENSION_EXPORT OFString *const kOFMessageKey;
OBJFW_EXTENSION_EXPORT OFString *const kOFContentTransferEncodingKey;


@interface OFSMTPMessageContent: OFObject
{
	OFMutableDictionary* _content;
}

@property(retain)OFString* contentDisposition;
@property(retain)OFString* contentType;
@property(retain)OFString* message;
@property(retain)OFString* contentTransferEncoding;

- (instancetype)initWithDictionary:(OFDictionary *)dict;
+ (instancetype)content;
+ (instancetype)contentWithDictionary:(OFDictionary *)dict;

@end