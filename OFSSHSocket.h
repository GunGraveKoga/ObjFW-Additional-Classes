#import <ObjFW/OFTCPSocket.h>
#import <ObjFW/OFSeekableStream.h>
#import "objfwext_macros.h"

@class OFString;
@class OFArray<ObjectType>;
@class OFDate;
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

@property (nonatomic, null_unspecified, copy)OFString* userName;
@property (nonatomic, null_unspecified, copy)OFString* password;
@property (nonatomic, null_unspecified, copy)OFString* publicKey;
@property (nonatomic, null_unspecified, copy)OFString* privateKey;
@property (nonatomic, nullable, assign)id<OFSSHSocketDelegate> delegate;
@property (nonatomic) of_ssh_auth_options_t authOptions;
@property (nonatomic) of_ssh_host_hash_t hostHashType;
@property (nonatomic) BOOL useCompression;

@end


@protocol OFSSHSocketDelegate<OFObject>

@optional

- (BOOL)connection:(OFSSHSocket * _Nonnull)connection recivedHostKeyHash:(OFString * _Nullable)hash exception:(OFException * _Nullable)exception;

@end

typedef OF_OPTIONS(unsigned long, of_sftp_file_mode_t) {
    kSFTPRead = 0x00000001, //LIBSSH2_FXF_READ
    kSFTPWrite = 0x00000002, //LIBSSH2_FXF_WRITE
    kSFTPAppend = 0x00000004, //LIBSSH2_FXF_APPEND
    kSFTPCreate = 0x00000008, //LIBSSH2_FXF_CREAT
    kSFTPTruncade = 0x00000010, //LIBSSH2_FXF_TRUNC
    kSFTPExclude = 0x00000020, //LIBSSH2_FXF_EXCL
};

#define OF_SFTP_S_IFMT         0170000     /* type of file mask */
#define OF_SFTP_S_IFIFO        0010000     /* named pipe (fifo) */
#define OF_SFTP_S_IFCHR        0020000     /* character special */
#define OF_SFTP_S_IFDIR        0040000     /* directory */
#define OF_SFTP_S_IFBLK        0060000     /* block special */
#define OF_SFTP_S_IFREG        0100000     /* regular */
#define OF_SFTP_S_IFLNK        0120000     /* symbolic link */
#define OF_SFTP_S_IFSOCK       0140000     /* socket */
#define OF_SFTP_S_IRWXU        0000700     /* RWX mask for owner */
#define OF_SFTP_S_IRUSR        0000400     /* R for owner */
#define OF_SFTP_S_IWUSR        0000200     /* W for owner */
#define OF_SFTP_S_IXUSR        0000100     /* X for owner */
#define OF_SFTP_S_IRWXG        0000070     /* RWX mask for group */
#define OF_SFTP_S_IRGRP        0000040     /* R for group */
#define OF_SFTP_S_IWGRP        0000020     /* W for group */
#define OF_SFTP_S_IXGRP        0000010     /* X for group */
#define OF_SFTP_S_IRWXO        0000007     /* RWX mask for other */
#define OF_SFTP_S_IROTH        0000004     /* R for other */
#define OF_SFTP_S_IWOTH        0000002     /* W for other */
#define OF_SFTP_S_IXOTH        0000001     /* X for other */

@interface OFSFTPSocket: OFSSHSocket

- (void)openFile:(OFString * _Nonnull)file mode:(of_sftp_file_mode_t)mode rights:(int)rights;
- (void)openDirectory:(OFString * _Nonnull)path;
- (void)createDirectoryAtPath:(OFString * _Nonnull)path rights:(int)rights;
- (OFArray<OFString*> * _Nonnull)contentOfDirectoryAtPath:(OFString * _Nonnull)path;
- (of_offset_t)sizeOfFileAtPath:(OFString * _Nonnull)path;
- (of_offset_t)sizeOfDirectoryAtPath:(OFString * _Nonnull)path;
- (OFDate * _Nullable)accessTimeOfFileAtPath:(OFString * _Nonnull)path;
- (OFDate * _Nullable)modifiedTimeOfFileAtPath:(OFString * _Nonnull)path;
- (OFDate * _Nullable)accessTimeOfDirectoryAtPath:(OFString * _Nonnull)path;
- (OFDate * _Nullable)modifiedTimeOfDirectoryAtPath:(OFString * _Nonnull)path;

@end
