#import <ObjFW/ObjFW.h>
#import "OFDataArray+WITHBYTES.h"

@implementation OFDataArray (WITHBYTES)
- (instancetype)initWithBytes:(const void *)bytes length:(size_t)length
{
    self = [self initWithCapacity:length];
    [self addItems:bytes count:length];

    return self;
}

+ (instancetype)dataWithBytes:(const void *)bytes length:(size_t)length
{
    return [[[self alloc] initWithBytes:bytes length:length] autorelease];
}

@end