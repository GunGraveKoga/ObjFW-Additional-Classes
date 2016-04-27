#import <ObjFW/ObjFW.h>
#import "OFDataArray+WITHBYTES.h"

@implementation OFDataArray (WITHBYTES)
- (instancetype)initWithBytes:(const void *)bytes length:(size_t)length
{
    OFDataArray* array;
    array = [self initWithCapacity:length];
    [array addItems:bytes count:length];

    return array;
}

+ (instancetype)dataWithBytes:(const void *)bytes length:(size_t)length
{
    return [[[self alloc] initWithBytes:bytes length:length] autorelease];
}

@end