#import <ObjFW/OFObject.h>

@class OFString;
@class OFThread;
@class OFMutex;
@class OFCountedSet;


@interface OFLogger: OFObject

- (void)start;
- (void)stop;

@end
