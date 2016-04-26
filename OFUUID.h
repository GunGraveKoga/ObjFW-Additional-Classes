#import <ObjFW/OFObject.h>

@class OFString;


@interface OFUUID: OFObject
{
	union {
		uint8_t bytes[16];
		uint64_t words[2];
	} _source;

	OFString* _uuidString;
}

+ (instancetype)uuid;

- (OFString *)stringRepresentation;

@end