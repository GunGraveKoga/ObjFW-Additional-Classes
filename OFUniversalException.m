#import <ObjFW/ObjFW.h>
#import "OFUniversalException.h"

OFString *const kSourceFile = @"SourceFile";
OFString *const kSourceFunction = @"SourceFunction";
OFString *const kSourceLine = @"SourceLine";
OFString *const kSourceClass = @"SourceClass";

@interface OFUniversalException()

@property(readwrite, copy)OFString* name;
@property(readwrite, copy)OFString* reason;
@property(readwrite, copy)OFDictionary* userInfo;

@end

static bool __show_source_exception_info = false;

@implementation OFUniversalException

@synthesize name = _name;
@synthesize reason = _reason;
@synthesize userInfo = _userInfo;

- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt, ...
{
	OFUniversalException* exception;
	va_list ap;
	va_start(ap, frmt);
	exception = [self initWithName:name format:frmt arguments:ap];
	va_end(ap);

	return exception;
}

- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args
{
	return [self initWithName:name format:frmt arguments:args userInfo:nil];
}

- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args userInfo:(OFDictionary *)userInfo;
{
	self = [super init];

	void* pool = objc_autoreleasePoolPush();

	self.name = name;

	self.reason = [OFString stringWithFormat:frmt arguments:args];

	self.userInfo = userInfo;

	objc_autoreleasePoolPop(pool);

	return self;

}


+ (instancetype)exceptionWithName:(OFString *)name format:(OFConstantString *)frmt, ...
{
	OFUniversalException* exception;
	va_list ap;
	va_start(ap, frmt);
	exception = [[self alloc] initWithName:name format:frmt arguments:ap];
	va_end(ap);

	return [exception autorelease];
}

+ (instancetype)exceptionWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args
{
	return [[[self alloc] initWithFormat:frmt arguments:args] autorelease];
}

+ (instancetype)exceptionWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args userInfo:(OFDictionary *)userInfo
{
	return [[[self alloc] initWithName:name format:frmt arguments:args userInfo:userInfo] autorelease];
}

- (OFString*)description
{
	if (!__show_source_exception_info)
		return [OFString stringWithFormat:@"%@", self.reason];
	else {
		OFMutableString* descriptionString = [OFMutableString string];

		void* pool = objc_autoreleasePoolPush();

		if (self.userInfo != nil) {
			if (self.userInfo[kSourceClass])
				[descriptionString appendFormat:@"<Class %@> ", self.userInfo[kSourceClass]];

			if (self.userInfo[kSourceFile])
				[descriptionString appendFormat:@"%@", self.userInfo[kSourceFile]];

			if (self.userInfo[kSourceFunction])
				[descriptionString appendFormat:@"::%@", self.userInfo[kSourceFunction]]; 

			if (self.userInfo[kSourceLine])
				[descriptionString appendFormat:@"[%@]", self.userInfo[kSourceFunction]];
		}

		if ([descriptionString length] > 0)
			[descriptionString appendFormat:@" "];

		[descriptionString appendFormat:@"%@", self.reason];

		objc_autoreleasePoolPop(pool);

		[descriptionString makeImmutable];

		return descriptionString;

	}
}

- (void)dealloc
{
	[_name release];
	[_reason release];
	[_userInfo release];

	[super dealloc];
}

@end

@implementation OFException(UniversalException)

- (void)raise
{
	@throw self;
}

+ (void)raise:(OFString *)name format:(OFConstantString *)frmt, ...
{
	OFUniversalException* exception;

	va_list ap;
	va_start(ap, frmt);
	exception = [OFUniversalException exceptionWithName:name format:frmt arguments:ap];
	va_end(ap);

	@throw exception;
}

+ (void)raise:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args
{
	@throw [OFUniversalException exceptionWithName:name format:frmt arguments:args];
}

+ (id)exceptionWithName:(OFString *)name reason:(OFString *)reason userInfo:(OFDictionary *)userInfo
{
	return [OFUniversalException exceptionWithName:name reason:reason userInfo:userInfo];
}

+ (void)showSourceInfo:(bool)flag
{
	__show_source_exception_info = flag;
}

@end