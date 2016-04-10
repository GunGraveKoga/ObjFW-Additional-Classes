#import <ObjFW/OFObject.h>
#import <ObjFW/OFHash.h>
#import <ObjFW/macros.h>


OF_ASSUME_NONNULL_BEGIN

@interface OFMD2Hash: OFObject<OFHash>
{
	uint8_t _state[48];
	uint8_t _cksum[16];
	uint8_t _digest[16];
	uint64_t _bits;

	union {
		uint8_t bytes[16];
		uint32_t words[4];
	} _buffer;

	size_t _bufferLength;
	bool _calculated;
}

- (void)OF_resetState;

@end

OF_ASSUME_NONNULL_END