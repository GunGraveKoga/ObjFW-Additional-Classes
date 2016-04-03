#import <ObjFW/ObjFW.h>
#import "OFUniversalException.h"

@implementation OFUniversalException

- (instancetype)initWithName:(OFString *)name message:(OFString *)message
{
	self = [super init];

	_name = [name copy];
	_message = [message copy];

	return self;
}

- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt, ...
{
	self = [super init];

	_name = [name copy];

	va_list ap;
	va_start(ap, frmt);
	_message = [[OFString alloc] initWithFormat:frmt arguments:ap];
	va_end(ap);

	return self;
}

- (instancetype)initWithName:(OFString *)name format:(OFConstantString *)frmt arguments:(va_list)args
{
	self = [super init];

	_name = name;

	_message = [[OFString alloc] initWithFormat:frmt arguments:args];

	return self;

}

+ (instancetype)exceptionWithName:(OFString *)name message:(OFString *)message
{
	return [[[self alloc] initWithName:name message:message] autorelease];
}

+ (instancetype)exceptionWithName:(OFString *)name format:(OFConstantString *)frmt, ...
{
	va_list ap;
	va_start(ap, frmt);
	OFUniversalException* result = [[self alloc] initWithName:name format:frmt arguments:ap];
	va_end(ap);

	return [result autorelease];
}

- (OFString*)description
{
	if ([_name containsString:@"exception"] || [_name containsString:@"Exception"])
		return [OFString stringWithFormat:@"%@ occurred! %@", _name, _message];
	else
		return [OFString stringWithFormat:@"%@ exception occurred! %@", _name, _message];
}

@end