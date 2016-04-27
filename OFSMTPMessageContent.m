#import <ObjFW/ObjFW.h>
#import "OFSMTPMessageContent.h"

OFString *const kOFContentDispositionKey = @"kOFContentDispositionKey";
OFString *const kOFContentTypeKey = @"kOFContentTypeKey";
OFString *const kOFMessageKey = @"kOFMessageKey";
OFString *const kOFContentTransferEncodingKey = @"kOFContentTransferEncodingKey";


@implementation OFSMTPMessageContent

@dynamic contentDisposition;
@dynamic contentType;
@dynamic message;
@dynamic contentTransferEncoding;

- (instancetype)init
{
	self = [super init];

	_content = [OFMutableDictionary new];

	return self;
}

- (instancetype)initWithDictionary:(OFDictionary *)dict
{
	self = [super init];

	_content = [[OFMutableDictionary alloc] initWithDictionary:dict];

	return self;
}

+ (instancetype)content
{
	return [[[self alloc] init] autorelease];
}

+ (instancetype)contentWithDictionary:(OFDictionary *)dict
{
	return [[[self alloc] initWithDictionary:dict] autorelease];
}

- (OFString *)contentDisposition
{
	return _content[kOFContentDispositionKey];
}

- (OFString *)contentType
{
	return _content[kOFContentTypeKey];
}

- (OFString *)message
{
	return _content[kOFMessageKey];
}

- (OFString *)contentTransferEncoding
{
	return _content[kOFContentTransferEncodingKey];
}

- (void)setContentDisposition:(OFString *)contentDisposition
{
	_content[kOFContentDispositionKey] = contentDisposition;
}

- (void)setContentType:(OFString *)contentType
{
	_content[kOFContentTypeKey] = contentType;
}

- (void)setMessage:(OFString *)message
{
	_content[kOFMessageKey] = message;
}

- (void)setContentTransferEncoding:(OFString *)contentTransferEncoding
{
	_content[kOFContentTransferEncodingKey] = contentTransferEncoding;
}

- (void)dealloc
{
	[_content release];
	[super dealloc];
}

@end