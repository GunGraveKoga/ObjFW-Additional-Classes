#import <ObjFW/ObjFW.h>
#import "OFUUID.h"

#if defined(OF_WINDOWS)
#include <wincrypt.h>
#endif


static uint64_t xorshift128plus(uint64_t *s) {
  /* http://xorshift.di.unimi.it/xorshift128plus.c */
  uint64_t s1 = s[0];
  const uint64_t s0 = s[1];
  s[0] = s0;
  s1 ^= s1 << 23;
  s[1] = s1 ^ s0 ^ (s1 >> 18) ^ (s0 >> 5);
  return s[1] + s0;
}

static uint64_t __uuid_seed[2] = {0};
#ifdef OF_HAVE_THREADS
static of_once_t seedControl = OF_ONCE_INIT;
#endif
static bool __seedInitialized = false;

static OFString *const __uuid_template = @"xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
static OFString *const __uuid_characters = @"0123456789abcdef";

static void __system_random(void) {
#if defined(OF_WINDOWS)
	int res;
  	HCRYPTPROV hCryptProv;

  	res = CryptAcquireContext(&hCryptProv, NULL, NULL, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT);
  	if (!res) {
    	@throw [OFInitializationFailedException exceptionWithClass:[OFUUID class]];
  	}

  	res = CryptGenRandom(hCryptProv, (DWORD) sizeof(__uuid_seed), (PBYTE) __uuid_seed);
  	CryptReleaseContext(hCryptProv, 0);

  	if (!res) {
    	@throw [OFInitializationFailedException exceptionWithClass:[OFUUID class]];
  	}
#else
  	int res;
  	FILE *fp = fopen("/dev/urandom", "rb");

  	if (!fp) {
    	@throw [OFInitializationFailedException exceptionWithClass:[OFUUID class]];
  	}

  	res = fread(__uuid_seed, 1, sizeof(__uuid_seed), fp);
  	fclose(fp);

  	if ( res != sizeof(seed) ) {
    	@throw [OFInitializationFailedException exceptionWithClass:[OFUUID class]];
  	}
#endif
}

static void initSeed(void) {

	do {
		__system_random();

	} while (__uuid_seed[0] == 0 && __uuid_seed[1] == 0);
  	__seedInitialized = true;
}


@implementation OFUUID

+ (void)initialize
{
	if (self == [OFUUID class]) {
#ifdef OF_HAVE_THREADS
    of_once(&seedControl, initSeed);
#else
	if (!__seedInitialized)
		initSeed();
#endif
	}
}

- (instancetype)init
{
	self = [super init];

	_source.words[0] = xorshift128plus(__uuid_seed);
	_source.words[1] = xorshift128plus(__uuid_seed);

	
	int i = 0, n = 0, idx = 0;
	
	of_unichar_t uuid_string[37];
	memset(uuid_string, 0, sizeof(uuid_string));
	size_t length = [__uuid_template length];

	of_unichar_t character;
	for (size_t char_idx = 0; char_idx < length; char_idx++) {

		n = _source.bytes[i >> 1];
		n = (i & 1) ? (n >> 4) : (n & 0xf);

		character = [__uuid_template characterAtIndex:char_idx];

		switch (character) {
			case 'x':
				uuid_string[idx] = [__uuid_characters characterAtIndex:n];
				i++;
				break;
			case 'y':
				uuid_string[idx] = [__uuid_characters characterAtIndex:((n & 0x3) + 8)];
				i++;
				break;
			default:
				uuid_string[idx] = character;
				break;
		}
		idx++;
	}//

	size_t uuid_string_lenght = sizeof(uuid_string)/sizeof(of_unichar_t);
	uuid_string[uuid_string_lenght - 1] = (of_unichar_t)('\0');

	_uuidString = nil;
	@try {
		_uuidString = [[OFString alloc] initWithCharacters:(const of_unichar_t *)uuid_string length:uuid_string_lenght - 1];
	}@catch(id e) {
		[self release];
		@throw [OFInitializationFailedException exceptionWithClass:[OFUUID class]];
	}

	return self;
}

- (void)dealloc
{
	[_uuidString release];
	[super dealloc];
}

+ (instancetype)uuid
{
	return [[[self alloc] init] autorelease];
}

- (OFString *)stringRepresentation
{
	return [OFString stringWithString:_uuidString];
}

- (bool)isEqual:(id)object
{
	OFUUID* uuid;

	if (![object isKindOfClass:[OFUUID class]])
		return false;

	uuid = object;

	return [self->_uuidString isEqual:uuid->_uuidString];
}

- (OFString *)description
{
	return [OFString stringWithFormat:@"<%@ 0x%p %@>", [self className], self, _uuidString];
}


@end