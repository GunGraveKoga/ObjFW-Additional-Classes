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

@class OFSFTPSocket;

@interface OFSFTPRemoteFSEntry: OFObject

@property (nonatomic, readonly) of_offset_t size;
@property (nonatomic, readonly, nullable, copy) OFDate* lastAccessTime;
@property (nonatomic, readonly, nullable, copy) OFDate* modifiedTime;
@property (nonatomic, readonly) BOOL isDirectory;
@property (nonatomic, readonly) BOOL isSymlink;
@property (nonatomic, readonly, nonnull, copy) OFString* name;
@property (nonatomic, readonly, nonnull, copy) OFString* path;
@property (nonatomic, readonly) unsigned long uid;
@property (nonatomic, readonly) unsigned long gid;
@property (nonatomic, readonly) unsigned long permissions;

@property (nonatomic) BOOL isOpened;
@property (nonatomic, assign, readonly, nullable) OFSFTPSocket* source;

+ (OFSFTPRemoteFSEntry * _Nonnull)entry;
- (void)open;
- (void)close;
- (void)remove;
- (OFDataArray * _Nonnull)read;
- (void)write:(OFDataArray * _Nonnull)data;
- (void)append:(OFDataArray * _Nonnull)data;
- (void)moveTo:(OFString * _Nonnull)path;
- (void)copyTo:(OFString * _Nonnull)path;

@end

@interface OFSFTPSocket: OFSSHSocket

@property (nonatomic, readonly) of_offset_t size;
@property (nonatomic, readonly, nullable) OFDate* lastAccessTime;
@property (nonatomic, readonly, nullable) OFDate* modifiedTime;

- (OFSFTPRemoteFSEntry * _Nonnull)itemAtPath:(OFString * _Nonnull)path;
- (void)openFile:(OFString * _Nonnull)file mode:(of_sftp_file_mode_t)mode rights:(int)rights;
- (void)openDirectory:(OFString * _Nonnull)path;
- (void)createDirectoryAtPath:(OFString * _Nonnull)path rights:(int)rights;
- (void)createDirectoryAtPath:(OFString * _Nonnull)path rights:(int)rights createParents:(BOOL)createParents;
- (OFArray<OFSFTPRemoteFSEntry*> * _Nonnull)contentOfDirectoryAtPath:(OFString * _Nonnull)path;
- (of_offset_t)sizeOfFileAtPath:(OFString * _Nonnull)path;
- (of_offset_t)sizeOfDirectoryAtPath:(OFString * _Nonnull)path;
- (OFDate * _Nullable)accessTimeOfFileAtPath:(OFString * _Nonnull)path;
- (OFDate * _Nullable)modifiedTimeOfFileAtPath:(OFString * _Nonnull)path;
- (OFDate * _Nullable)accessTimeOfDirectoryAtPath:(OFString * _Nonnull)path;
- (OFDate * _Nullable)modifiedTimeOfDirectoryAtPath:(OFString * _Nonnull)path;
- (BOOL)fileExistsAtPath:(OFString * _Nonnull)path;
- (BOOL)directoryExistsAtPath:(OFString * _Nonnull)path;
- (void)removeDirectoryAtPath:(OFString * _Nonnull)path;
- (void)removeFileAtPath:(OFString * _Nonnull)path;
- (void)remove;
- (void)flush;
- (void)moveItemAtPath:(OFString * _Nonnull)source toDestination:(OFString * _Nonnull)destination;
- (void)copyItemAtPath:(OFString * _Nonnull)source toDestination:(OFString * _Nonnull)destination;
- (void)uploadItemAtLocalPath:(OFString * _Nonnull)localPath toRemoteDestination:(OFString * _Nonnull)destinationPath;
- (void)downloadRemoteItemAtPath:(OFString * _Nonnull)remotePath toLocalPath:(OFString * _Nonnull)localDestination;

@end
