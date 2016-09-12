#import <ObjFW/OFObject.h>
#import <ObjFW/OFException.h>
#import <ObjFW/OFSeekableStream.h>

#ifndef __BSDM_SMB_DEFS_H_
//-----------------------------------------------------------------------------/
// File access rights (used when smb_open() files)
//-----------------------------------------------------------------------------/
/// Flag for smb_file_open. Request right for reading
#define SMB_MOD_READ            (1 << 0)
/// Flag for smb_file_open. Request right for writing
#define SMB_MOD_WRITE           (1 << 1)
/// Flag for smb_file_open. Request right for appending
#define SMB_MOD_APPEND          (1 << 2)
/// Flag for smb_file_open. Request right for extended read (?)
#define SMB_MOD_READ_EXT        (1 << 3)
/// Flag for smb_file_open. Request right for extended write (?)
#define SMB_MOD_WRITE_EXT       (1 << 4)
/// Flag for smb_file_open. Request right for execution (?)
#define SMB_MOD_EXEC            (1 << 5)
/// Flag for smb_file_open. Request right for child removal (?)
#define SMB_MOD_RMCHILD         (1 << 6)
/// Flag for smb_file_open. Request right for reading file attributes
#define SMB_MOD_READ_ATTR       (1 << 7)
/// Flag for smb_file_open. Request right for writing file attributes
#define SMB_MOD_WRITE_ATTR      (1 << 8)
/// Flag for smb_file_open. Request right for removing file
#define SMB_MOD_RM              (1 << 16)
/// Flag for smb_file_open. Request right for reading ACL
#define SMB_MOD_READ_CTL        (1 << 17)
/// Flag for smb_file_open. Request right for writing ACL
#define SMB_MOD_WRITE_DAC       (1 << 18)
/// Flag for smb_file_open. Request right for changing owner
#define SMB_MOD_CHOWN           (1 << 19)
/// Flag for smb_file_open. (??)
#define SMB_MOD_SYNC            (1 << 20)
/// Flag for smb_file_open. (??)
#define SMB_MOD_SYS             (1 << 24)
/// Flag for smb_file_open. (??)
#define SMB_MOD_MAX_ALLOWED     (1 << 25)
/// Flag for smb_file_open. Request all generic rights (??)
#define SMB_MOD_GENERIC_ALL     (1 << 28)
/// Flag for smb_file_open. Request generic exec right (??)
#define SMB_MOD_GENERIC_EXEC    (1 << 29)
/// Flag for smb_file_open. Request generic read right (??)
#define SMB_MOD_GENERIC_READ    (1 << 30)
/// Flag for smb_file_open. Request generic write right (??)
#define SMB_MOD_GENERIC_WRITE   (1 << 31)
/**
 * @brief Flag for smb_file_open. Default R/W mode
 * @details A few flags OR'ed
 */
#define SMB_MOD_RW              (SMB_MOD_READ | SMB_MOD_WRITE | SMB_MOD_APPEND \
                                | SMB_MOD_READ_EXT | SMB_MOD_WRITE_EXT \
                                | SMB_MOD_READ_ATTR | SMB_MOD_WRITE_ATTR \
                                | SMB_MOD_READ_CTL )
/**
 * @brief Flag for smb_file_open. Default R/O mode
 * @details A few flags OR'ed
 */
#define SMB_MOD_RO              (SMB_MOD_READ | SMB_MOD_READ_EXT \
                                | SMB_MOD_READ_ATTR | SMB_MOD_READ_CTL )


#endif


@class OFString;
@class OFURL;
@class OFArray<ObjectType>;
@class OFSMBItem;
@class OFDate;

OF_ASSUME_NONNULL_BEGIN

@interface OFSMBClient: OFObject<OFObject, OFCopying>

@property (nonatomic, readonly) BOOL loggedAsGuest;
@property (nonatomic, readonly, copy) OFString* connectionHost;
@property (nonatomic, readonly, copy) OFString* connectionAddress;
@property (nonatomic, readonly, copy) OFString* userName;
@property (nonatomic, readonly, copy) OFString* userDomain;
@property (nonatomic, readonly, copy) OFString* userPasswordHash;
@property (nonatomic, copy, nullable) OFString* currentShare;

@property (nonatomic, readonly, copy) OFArray<OFString*>* shares;

- (instancetype)initWithURL:(OFURL *)url;
+ (instancetype)connectionWithURL:(OFURL *)url;

- (OFArray<OFSMBItem*> * _Nullable)contentsOfDirectoryAtPath:(OFString *)path;
- (OFSMBItem * _Nullable)itemAtPath:(OFString *)path;
- (void)deleteItemAtPath:(OFString *)path;
- (void)createDirectoryAtPath:(OFString *)path;
- (void)moveItemAtPath:(OFString *)source toPath:(OFString *)destination;
- (OFSMBItem * _Nullable)findItem:(OFString *)item atPath:(OFString *)path depth:(size_t)depth;
- (void)dowloadFileAtPath:(OFString *)path processingBlock:(void(^)(void* buffer, size_t length))processingBlock;

@end

@interface OFSMBItem: OFObject

@property (nonatomic, readonly, copy) OFString* name;
@property (nonatomic, readonly, copy) OFString* path;
@property (nonatomic, readonly) uint64_t size;
@property (nonatomic, readonly) uint64_t diskSize;
@property (nonatomic, readonly) BOOL isDirectory;
@property (nonatomic, readonly, copy) OFDate* creationDate;
@property (nonatomic, readonly, copy) OFDate* lastAccessDate;
@property (nonatomic, readonly, copy) OFDate* lastWriteDate;
@property (nonatomic, readonly, copy) OFDate* lastModificationDate;

@end

@interface OFSMBAuthenticationFailedException: OFException

@property (nonatomic, copy, readonly) OFString *domain;
@property (nonatomic, copy, readonly) OFString *login;
@property (nonatomic, copy, readonly) OFString *password;

- (instancetype)initWithDomain:(OFString *)domain login:(OFString *)login password:(OFString *)password;
+ (instancetype)exceptionWithDomain:(OFString *)domain login:(OFString *)login password:(OFString *)password;

@end


@interface OFSMBErrorException: OFException

@property (nonatomic, readonly) int errorNumber;

- (instancetype)initWithDSMError:(int)errorNumber;
+ (instancetype)exceptionWithDSMError:(int)errorNumber;

@end

OF_ASSUME_NONNULL_END
