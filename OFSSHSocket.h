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

typedef OF_ENUM(int, of_ssh_error_t) {
    kSuccess = 0,
    kSocketNoneError = -1,
    kBannerReciveError = -2,
    kBannerSendError = -3,
    kInvalidMac = -4,
    kKexFailure = -5,
    kAllocError = -6,
    kSocketSendError = -7,
    kKeyExchangeFailure = -8,
    kTimeoutError = -9,
    kHostKeyInitError = -10,
    kHostKeySignError = -11,
    kDecryptError = -12,
    kSocketDisconnect = -13,
    kProtoError = -14,
    kPasswordExpired = -15,
    kFileError = -16,
    kMethodNoneError = -17,
    kAuthenticationFailed = -18,
    kPublicKeyUnrecognized = -18,
    kPublicKeyUnverified = -19,
    kChanelOutOfOrderError = -20,
    kChanelFailure = -21,
    kChanelRequestDenied = -22,
    kChanelUnknown = -23,
    kChanelWindowExceeded = -24,
    kChanelPacketExceeded = -25,
    kChanelClosed = -26,
    kChanelEOF = -27,
    kSCPProtocolError = -28,
    kZLibError = -29,
    kSocketTimeoutError = -30,
    kSFTPProtocolError = -31,
    kRequestDenied = -32,
    kMethodNotSupported = -33,
    kInvalError = -34,
    kInvalidPollType = -35,
    kPublicKeyProtocolError = -36,
    kEAgain = -37,
    kBufferTooSmall = -38,
    kBadUseError = -39,
    kCompressError = -40,
    kOutOfBoundary = -41,
    kAgentProtocolError = -42,
    kSocketReciveError = -43,
    kEncryptError = -44,
    kBadSocket = -45,
    kKnownHost = -46,
    kBannerNoneError = -2,
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


@protocol OFSSHSocketDelegate<OFObject>

@optional

- (BOOL)connection:(OFSSHSocket *)connection recivedHostKeyHash:(OFString * _Nullable)hash exception:(OFException * _Nullable)exception;

@end

typedef OF_OPTIONS(unsigned long, of_sftp_access_mode_t) {
    kSFTPRead = 0x00000001, //LIBSSH2_FXF_READ
    kSFTPWrite = 0x00000002, //LIBSSH2_FXF_WRITE
    kSFTPAppend = 0x00000004, //LIBSSH2_FXF_APPEND
    kSFTPCreate = 0x00000008, //LIBSSH2_FXF_CREAT
    kSFTPTruncade = 0x00000010, //LIBSSH2_FXF_TRUNC
    kSFTPExclude = 0x00000020, //LIBSSH2_FXF_EXCL
};

@interface OFSFTPSocket: OFSSHSocket

@end
