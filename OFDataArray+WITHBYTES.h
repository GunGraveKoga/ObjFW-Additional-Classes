#import <ObjFW/OFDataArray.h>

@interface OFDataArray (WITHBYTES)
- (instancetype)initWithBytes:(const void *)bytes length:(size_t)length;
+ (instancetype)dataWithBytes:(const void *)bytes length:(size_t)length;
@end