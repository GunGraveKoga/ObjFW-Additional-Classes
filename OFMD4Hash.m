/*
 * Copyright (c) 2008, 2009, 2010, 2011, 2012, 2013, 2014, 2015, 2016
 *   Jonathan Schleifer <js@heap.zone>
 *
 * All rights reserved.
 *
 * This file is part of ObjFW. It may be distributed under the terms of the
 * Q Public License 1.0, which can be found in the file LICENSE.QPL included in
 * the packaging of this file.
 *
 * Alternatively, it may be distributed under the terms of the GNU General
 * Public License, either version 2 or 3, which can be found in the file
 * LICENSE.GPLv2 or LICENSE.GPLv3 respectively included in the packaging of this
 * file.
 */

#import <ObjFW/ObjFW.h>
#import "OFMD4Hash.h"

#define F(a, b, c) (((a) & (b)) | (~(a) & (c)))
#define G(a, b, c) (((a) & (b)) | ((a) & (c)) | ((b) & (c)))
#define H(a, b, c) ((a) ^ (b) ^ (c))


static const uint8_t wordOrder[] = {
	0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15,
	0, 4, 8, 12, 1, 5, 9, 13, 2, 6, 10, 14, 3, 7, 11, 15,
	0, 8, 4, 12, 2, 10, 6, 14, 1, 9, 5, 13, 3, 11, 7, 15
};
static const uint8_t rotateBits[] = {
	3, 7, 11, 19,
	3, 5, 9, 13,
	3, 9, 11, 15
};

static OF_INLINE void
byteSwapVectorIfBE(uint32_t *vector, uint8_t length)
{
#ifdef OF_BIG_ENDIAN
	for (uint8_t i = 0; i < length; i++)
		vector[i] = OF_BSWAP32(vector[i]);
#endif
}

static void
processBlock(uint32_t *state, uint32_t *buffer)
{
	uint32_t new[4];
	uint8_t i = 0;

	new[0] = state[0];
	new[1] = state[1];
	new[2] = state[2];
	new[3] = state[3];

	byteSwapVectorIfBE(buffer, 16);

#define LOOP_BODY(f)							      \
	{								      \
		uint32_t tmp = new[3];					      \
		tmp = new[3];						      \
		new[0] += f(new[1], new[2], new[3]) +			      \
		    buffer[wordOrder[i]] + MAGIC_NUM;			      \
		new[3] = new[2];					      \
		new[2] = new[1];					      \
		new[1] = OF_ROL(new[0], rotateBits[(i % 4) + (i / 16) * 4]); \
		new[0] = tmp;\
	}
	uint32_t MAGIC_NUM = 0x0;
	for (; i < 16; i++)
		LOOP_BODY(F)

	MAGIC_NUM = 0x5A827999;
	for (; i < 32; i++)
		LOOP_BODY(G)

	MAGIC_NUM = 0x6ED9EBA1;
	for (; i < 48; i++)
		LOOP_BODY(H)

#undef LOOP_BODY

	state[0] += new[0];
	state[1] += new[1];
	state[2] += new[2];
	state[3] += new[3];
}

@implementation OFMD4Hash
@synthesize calculated = _calculated;

+ (size_t)digestSize
{
	return 16;
}

+ (size_t)blockSize
{
	return 64;
}

+ (instancetype)hash
{
	return [[[self alloc] init] autorelease];
}

- init
{
	self = [super init];

	[self OF_resetState];

	return self;
}

- (void)OF_resetState
{
	_state[0] = 0x67452301;
	_state[1] = 0xEFCDAB89;
	_state[2] = 0x98BADCFE;
	_state[3] = 0x10325476;
}

- (void)updateWithBuffer: (const void*)buffer_
		  length: (size_t)length
{
	const uint8_t *buffer = buffer_;

	if (_calculated)
		@throw [OFHashAlreadyCalculatedException
		    exceptionWithHash: self];

	_bits += (length * 8);

	while (length > 0) {
		size_t min = 64 - _bufferLength;

		if (min > length)
			min = length;

		memcpy(_buffer.bytes + _bufferLength, buffer, min);
		_bufferLength += min;

		buffer += min;
		length -= min;

		if (_bufferLength == 64) {
			processBlock(_state, _buffer.words);
			_bufferLength = 0;
		}
	}
}

- (const uint8_t*)digest
{
	if (_calculated)
		return (const uint8_t*)_state;

	_buffer.bytes[_bufferLength] = 0x80;
	memset(_buffer.bytes + _bufferLength + 1, 0, 64 - _bufferLength - 1);

	if (_bufferLength >= 56) {
		processBlock(_state, _buffer.words);
		memset(_buffer.bytes, 0, 64);
	}

	_buffer.words[14] = OF_BSWAP32_IF_BE((uint32_t)(_bits & 0xFFFFFFFF));
	_buffer.words[15] = OF_BSWAP32_IF_BE((uint32_t)(_bits >> 32));

	processBlock(_state, _buffer.words);
	memset(&_buffer, 0, sizeof(_buffer));
	byteSwapVectorIfBE(_state, 4);
	_calculated = true;

	return (const uint8_t*)_state;
}

- (void)reset
{
	[self OF_resetState];
	_bits = 0;
	memset(&_buffer, 0, sizeof(_buffer));
	_bufferLength = 0;
	_calculated = false;
}
@end
