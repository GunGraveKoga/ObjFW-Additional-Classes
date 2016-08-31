#import <ObjFW/OFTCPSocket.h>

@class OFString;



@interface OFSSHSocket: OFTCPSocket

@property (nonatomic, copy)OFString* userName;
@property (nonatomic, copy)OFString* password;

@end
