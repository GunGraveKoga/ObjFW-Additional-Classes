#import <ObjFW/OFTCPSocket.h>
#import "objfwext_macros.h"

@class OFString;
@protocol OFSSHSocketDelegate;

typedef OF_OPTIONS(int, of_ssh_auth_options_t) {
  kPassword = 1 << 0,
  kKeyboardInteractive = 1 << 1,
  kPublicKey = 1 << 2,
};


typedef OF_ENUM(int, of_ssh_host_hash_t) {
    kMD5Hash = 1,
    kSHA1Hash = 2,
};


@interface OFSSHSocket: OFTCPSocket

@property (nonatomic, copy)OFString* userName;
@property (nonatomic, copy)OFString* password;
@property (nonatomic, copy)OFString* publicKey;
@property (nonatomic, copy)OFString* privateKey;
@property (nonatomic, assign)id<OFSSHSocketDelegate> delegate;
@property (nonatomic) of_ssh_auth_options_t authOptions;
@property (nonatomic) of_ssh_host_hash_t hostHashType;

@end
