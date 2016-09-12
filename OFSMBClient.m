#import <ObjFW/ObjFW.h>
#import "OFSMBClient.h"
#include "errno.h"
#include <bdsm/bdsm.h>

@interface OFSMBClient()

@property (nonatomic) smb_session *session;
@property (nonatomic) smb_tid *share;
@property (nonatomic) BOOL shareOpened;

@property (nonatomic, readwrite, copy) OFString* connectionHost;
@property (nonatomic, readwrite, copy) OFString* connectionAddress;
@property (nonatomic, readwrite, copy) OFString* userName;
@property (nonatomic, readwrite, copy) OFString* userDomain;
@property (nonatomic, readwrite, copy) OFString* userPasswordHash;

@end

@interface OFSMBAuthenticationFailedException()
@property (nonatomic, copy, readwrite) OFString *domain;
@property (nonatomic, copy, readwrite) OFString *login;
@property (nonatomic, copy, readwrite) OFString *password;
@end

@interface OFSMBErrorException()
@property (nonatomic, readwrite) int errorNumber;
@end

@interface OFSMBItem()

@property (nonatomic, readwrite, copy) OFString* name;
@property (nonatomic, readwrite, copy) OFString* path;
@property (nonatomic, readwrite) uint64_t size;
@property (nonatomic, readwrite) uint64_t diskSize;
@property (nonatomic, readwrite) BOOL isDirectory;
@property (nonatomic, readwrite, copy) OFDate* creationDate;
@property (nonatomic, readwrite, copy) OFDate* lastAccessDate;
@property (nonatomic, readwrite, copy) OFDate* lastWriteDate;
@property (nonatomic, readwrite, copy) OFDate* lastModificationDate;

+ (instancetype)item;

@end

@implementation OFSMBClient{
    smb_session *_session;
    smb_tid _tid;
    BOOL _shareOpened;

    OFString *_connectionHost;
    OFString *_connectionAddress;
    OFString *_userName;
    OFString *_userDomain;
    OFString *_userPasswordHash;

    OFString *_currentShare;

    OFMutableArray<OFString*> *_shares;
}

@synthesize session = _session;
@synthesize shareOpened = _shareOpened;
@synthesize connectionHost = _connectionHost;
@synthesize connectionAddress = _connectionAddress;
@synthesize userDomain = _userDomain;
@synthesize userName = _userName;
@synthesize userPasswordHash = _userPasswordHash;
@dynamic loggedAsGuest;
@dynamic share;
@dynamic shares;
@dynamic currentShare;

+ (void)initialize
{
    if (self != [OFSMBClient class])
        return;

    @autoreleasepool {
        [OFStreamSocket className];
    }
}

+ (instancetype)connectionWithURL:(OFURL *)url
{
#if !__has_feature(objc_arc)
    return [[[self alloc] initWithURL:url] autorelease];
#else
    return [[self alloc] initWithURL:url];
#endif
}

- (instancetype)initWithURL:(OFURL *)url
{
    self = [super init];

    self.session = NULL;

    if (![url.scheme isEqual:@"smb"]) {
        [self release];

        @throw [OFInvalidArgumentException exception];
    }


#if !__has_feature(obj_arc)
    void *pool = objc_autoreleasePoolPush();
#endif
    of_resolver_result_t **resolveResults = of_resolve_host(url.host, 445, SOCK_STREAM);

    if (resolveResults == NULL) {
        [self release];

#if !__has_feature(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif

        @throw [OFConnectionFailedException exceptionWithHost:url.host port:445 socket:nil];
    }

    of_resolver_result_t **iter;

    self.session = smb_session_new();

    int rc = 0;
    struct sockaddr_in *addr;
    BOOL connected = NO;

    for (iter = resolveResults; *iter != NULL; iter++) {
        of_resolver_result_t *result = *iter;

        if (result->family == AF_INET) {
            addr = (struct sockaddr_in *)result->address;

            rc = smb_session_connect(self.session, [url.host cStringWithEncoding:OF_STRING_ENCODING_ASCII],
#if defined(OF_WINDOWS)
                                                                            addr->sin_addr.S_un.S_addr,
#else
                                                                            addr->sin_addr.s_addr,
#endif
                                                                            SMB_TRANSPORT_TCP);

            if (rc == 0) {
                connected = YES;
                self.connectionHost = url.host;
                OFString *address = nil;

                of_address_to_string_and_port(result->address, result->addressLength, &address, NULL);

                self.connectionAddress = [OFString stringWithFormat:@"%@:%zu", address, 445];

                break;
            }

        }

    }

    if (!connected) {
#if !__has_feature(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif

        [self release];
        if (rc == DSM_ERROR_NETWORK)
            @throw [OFConnectionFailedException exceptionWithHost:url.host port:445 socket:nil errNo:of_socket_errno()];
        else
            @throw [OFSMBErrorException exceptionWithDSMError:rc];

    }

    OFString *domain;
    OFString *login;
    OFString *password;

    OFArray<OFString *> *urlLogin = [url.user componentsSeparatedByString:@"\\"];

    if (urlLogin.count < 2)
        domain = url.host;
    else
        domain = urlLogin[0];

    if (urlLogin.count < 2)
        login = url.user;
    else
        login = urlLogin[1];

    password = url.password;

    smb_session_set_creds(self.session, domain.UTF8String, login.UTF8String, password.UTF8String);

    if ((rc = smb_session_login(self.session)) != 0) {
#if !__has_feature(objc_arc)
        [domain retain];
        [login retain];
        [password retain];

        objc_autoreleasePoolPop(pool);

        [domain autorelease];
        [login autorelease];
        [password autorelease];
#endif
        [self release];

        @throw [OFSMBAuthenticationFailedException exceptionWithDomain:domain login:login password:password];

    }

    smb_share_list shares;
    size_t sharesCount = 0;

    if ((rc = smb_share_get_list(self.session, &shares, &sharesCount)) != 0){
#if !__has_feature(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif
        [self release];

        @throw [OFSMBErrorException exceptionWithDSMError:rc];
    }

    self.userDomain = domain;
    self.userName = login;
    self.userPasswordHash = password.SHA1Hash;

    OFString *share;

    OFArray<OFString*> *urlPathComponents = url.path.pathComponents;
    _shares = [[OFMutableArray alloc] init];
    _currentShare = nil;
    self.shareOpened = NO;
    connected = NO;

    @autoreleasepool {
        for (size_t idx = 0; idx < sharesCount; idx++) {
            share = [OFString stringWithUTF8StringNoCopy:shares[idx] freeWhenDone:true];
            [_shares addObject:share];

            if ((url.path == nil) || (url.path.length <= 0))
                continue;

            if ([urlPathComponents[0] caseInsensitiveCompare:share] == OF_ORDERED_SAME) {
                @try {
                    self.currentShare = share;

                } @catch(...) {

                } @finally {
                    connected = self.shareOpened;
                    break;
                }

            }
        }
    }
    if ((url.path == nil) || (url.path.length <= 0))
        connected = YES;

    if (!connected) {
#if !__has_feature(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif
        if (rc != 0) {

            if (rc == DSM_ERROR_NT)
                rc = (int)smb_session_get_nt_status(self.session);

            [self release];

            @throw [OFSMBErrorException exceptionWithDSMError:rc];
        }

        @throw [OFOpenItemFailedException exceptionWithPath:url.path];

    }

#if !__has_feature(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif

    return self;
}

- (void)dealloc
{
    if (self.session) {
        if (self.shareOpened)
            smb_tree_disconnect(self.session, _tid);

        smb_session_destroy(self.session);
    }

#if !__has_feature(objc_arc)
    [_connectionAddress release];
    [_connectionHost release];
    [_userDomain release];
    [_userName release];
    [_userPasswordHash release];

    [_shares release];
    [_currentShare release];

    [super dealloc];
#endif
}

- (BOOL)loggedAsGuest
{
    if (self.session != NULL) {
        int rc = smb_session_is_guest(self.session);

        if (rc == 1)
            return YES;
        else
            return NO;
    }

    return NO;
}

- (smb_tid *)share
{
    return &_tid;
}

- (OFArray<OFString*> *)shares
{
    OFArray<OFString*> *shares_ = _shares.copy;

    return [shares_ autorelease];
}

- (void)setCurrentShare:(OFString *)share
{
    if (_currentShare)
        [_currentShare release];

    _currentShare = nil;

    if (self.shareOpened)
        smb_tree_disconnect(self.session, _tid);

    self.shareOpened = NO;

    int rc = 0;

    if (share != nil) {
        if ((rc = smb_tree_connect(self.session, share.UTF8String, self.share)) != 0){

            if (rc == DSM_ERROR_NT)
                rc = (int)smb_session_get_nt_status(self.session);

            @throw [OFSMBErrorException exceptionWithDSMError:rc];
        }
    }

    if (share != nil)
        _currentShare = share.copy;


    self.shareOpened = (share != nil) ? YES : NO;

    return;
}

- (OFString * _Nullable)currentShare
{
    if (_currentShare)
        return _currentShare;

    return nil;
}

- (OFArray<OFSMBItem*> * _Nullable)contentsOfDirectoryAtPath:(OFString *)path
{
    id exception = nil;

#if !__has_feature(objc_arc)
    void* pool = objc_autoreleasePoolPush();
#endif

    OFMutableArray<OFString*>* pathComponents = [OFMutableArray arrayWithArray:path.pathComponents];

    OFString* searchPath = [pathComponents componentsJoinedByString:@"\\"];

    if (![searchPath hasSuffix:@"*"])
        searchPath = [searchPath stringByAppendingString:@"\\*"];

    if (![searchPath hasPrefix:@"\\"])
        searchPath = [searchPath stringByPrependingString:@"\\"];

    smb_stat_list list = smb_find(self.session, _tid, searchPath.UTF8String);
    if (list == NULL)
        return nil;

    size_t elementsCount = smb_stat_list_count(list);

    OFMutableArray<OFSMBItem*>* result = [OFMutableArray arrayWithCapacity:elementsCount];
    searchPath = [searchPath substringWithRange:of_range(0, searchPath.length - 2)];

    @try {
        for (size_t idx = 0; idx < elementsCount; idx++) {
            smb_stat element = smb_stat_list_at(list, idx);

            @autoreleasepool {
                OFString* elementName = [OFString stringWithUTF8String:smb_stat_name(element)];

                if (![elementName isEqual:@"."] && ![elementName isEqual:@".."]) {

                    OFSMBItem* item = [OFSMBItem item];
                    item.name = elementName;
                    item.path = [@[
                                searchPath,
                                elementName
                            ] componentsJoinedByString:@"\\"];
                    item.isDirectory = ((smb_stat_get(element, SMB_STAT_ISDIR)) != 0) ? YES : NO;
                    item.size = smb_stat_get(element, SMB_STAT_SIZE);
                    item.diskSize = smb_stat_get(element, SMB_STAT_ALLOC_SIZE);
                    item.creationDate = [OFDate dateWithTimeIntervalSince1970:smb_stat_get(element, SMB_STAT_CTIME)];
                    item.lastAccessDate = [OFDate dateWithTimeIntervalSince1970:smb_stat_get(element, SMB_STAT_ATIME)];
                    item.lastModificationDate = [OFDate dateWithTimeIntervalSince1970:smb_stat_get(element, SMB_STAT_MTIME)];
                    item.lastWriteDate = [OFDate dateWithTimeIntervalSince1970:smb_stat_get(element, SMB_STAT_WTIME)];

                    [result addObject:item];
                }
            }


        }

    } @catch (id e) {
        exception = [e retain];

    } @finally {
        smb_stat_list_destroy(list);
    }

#if !__has_feature(objc_arc)

    if (!exception)
        [result retain];


    objc_autoreleasePoolPop(pool);
#endif

    if (exception)
        @throw [exception autorelease];

    [result makeImmutable];

    return [result autorelease];
}

- (OFSMBItem * _Nullable)itemAtPath:(OFString *)path
{
#if !__has_feature(objc_arc)
    void* pool = objc_autoreleasePoolPush();
#endif

    OFArray<OFString*>* pathComponents = path.pathComponents;

    OFString* searchPath = [pathComponents componentsJoinedByString:@"\\"];

    if (![searchPath hasPrefix:@"\\"])
        searchPath = [searchPath stringByAppendingString:@"\\"];

    smb_stat_list list = smb_find(self.session, _tid, searchPath.UTF8String);
    if (list == NULL) {
#if !__has_extension(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif
        return nil;
    }

    smb_stat itemStat = smb_stat_list_at(list, 0);

    OFSMBItem* item = [OFSMBItem new];


    @try {
        item.name = [OFString stringWithUTF8String:smb_stat_name(itemStat)];
        item.path = searchPath;
        item.isDirectory = ((smb_stat_get(itemStat, SMB_STAT_ISDIR)) != 0) ? YES : NO;
        item.size = smb_stat_get(itemStat, SMB_STAT_SIZE);
        item.diskSize = smb_stat_get(itemStat, SMB_STAT_ALLOC_SIZE);
        item.creationDate = [OFDate dateWithTimeIntervalSince1970:smb_stat_get(itemStat, SMB_STAT_CTIME)];
        item.lastAccessDate = [OFDate dateWithTimeIntervalSince1970:smb_stat_get(itemStat, SMB_STAT_ATIME)];
        item.lastModificationDate = [OFDate dateWithTimeIntervalSince1970:smb_stat_get(itemStat, SMB_STAT_MTIME)];
        item.lastWriteDate = [OFDate dateWithTimeIntervalSince1970:smb_stat_get(itemStat, SMB_STAT_WTIME)];

    }@catch (id e) {
        [item release];

        id exception = [e retain];

#if !__has_extension(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif
        @throw [exception autorelease];
    }@finally {
        smb_stat_list_destroy(list);
    }

#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif

    return item;

}

- (OFSMBItem * _Nullable)_findItem:(OFString *)item atPath:(OFSMBItem *)path depth:(size_t)depth
{
    if (!path.isDirectory)
        return nil;

    if (depth == 0)
        return nil;

    OFSMBItem* searchItem = [self itemAtPath:[@[
                path.path,
                item
            ] componentsJoinedByString:@"\\"]];

    if (searchItem)
        return searchItem;

    searchItem = nil;

    depth--;

    for (OFSMBItem* part in [self contentsOfDirectoryAtPath:path.path]) {
#if OBJFW_DSM_DEBUG
        of_log(@"Search in %@", part.path);
#endif
        searchItem = [self _findItem:item atPath:part depth:depth];

        if (searchItem)
            break;
    }

    return searchItem;
}

- (OFSMBItem * _Nullable)findItem:(OFString *)item atPath:(OFString *)path depth:(size_t)depth
{
    OFSMBItem* result = nil;
#if !__has_feature(objc_arc)
    void* pool = objc_autoreleasePoolPush();
#endif

    OFSMBItem* searchPath = [self itemAtPath:path];

    if (searchPath == nil || !searchPath.isDirectory) {
#if !__has_extension(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif
        @throw [OFInvalidArgumentException exception];
    }

    OFArray<OFString*>* searchItemComponents = item.pathComponents;

    OFString* searchItem = [searchItemComponents componentsJoinedByString:@"\\"];

    if ((result = [self itemAtPath:[@[
            searchPath.path,
            searchItem
         ] componentsJoinedByString:@"\\"]]) == nil) {

        for (OFSMBItem* item in [self contentsOfDirectoryAtPath:searchPath.path]) {
            @autoreleasepool {
#if OBJFW_DSM_DEBUG
                of_log(@"Search in %@", item.path);
#endif
                result = [self _findItem:searchItem atPath:item depth:(depth - 1)];

                if (result)
                    break;
            }
        }
    }

    [result retain];
#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif

    return [result autorelease];
}

- copy
{
    return [self retain];
}

- (void)deleteItemAtPath:(OFString *)path
{
#if !__has_feature(objc_arc)
    void* pool = objc_autoreleasePoolPush();
#endif

    OFSMBItem* item = [self itemAtPath:path];

    if (!item) {
#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif
        @throw [OFRemoveItemFailedException exceptionWithPath:path errNo:ENOENT];
    }

    int rc = 0;

    if (item.isDirectory) {
        rc = smb_directory_rm(self.session, _tid, path.UTF8String);

        if (rc == DSM_ERROR_NT)
            rc = (int)smb_session_get_nt_status(self.session);


        if (rc != 0) {
#if !__has_extension(objc_arc)
            objc_autoreleasePoolPop(pool);
#endif
            @throw [OFSMBErrorException exceptionWithDSMError:rc];
        }

    } else {
        rc = smb_file_rm(self.session, _tid, path.UTF8String);

        if (rc == DSM_ERROR_NT)
            rc = (int)smb_session_get_nt_status(self.session);

        if (rc != 0) {
#if !__has_extension(objc_arc)
            objc_autoreleasePoolPop(pool);
#endif
            @throw [OFSMBErrorException exceptionWithDSMError:rc];
        }
    }

#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif
}

- (void)createDirectoryAtPath:(OFString *)path
{
#if !__has_feature(objc_arc)
    void* pool = objc_autoreleasePoolPush();
#endif

    OFSMBItem* item = [self itemAtPath:path];

    if (item) {
#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif
        @throw [OFCreateDirectoryFailedException exceptionWithPath:path errNo:EEXIST];
    }

    int rc = 0;

    rc = smb_directory_create(self.session, _tid, path.UTF8String);

    if (rc == DSM_ERROR_NT)
        rc = (int)smb_session_get_nt_status(self.session);

    if (rc != 0) {
#if !__has_extension(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif
        @throw [OFSMBErrorException exceptionWithDSMError:rc];
    }

#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif
}

- (void)moveItemAtPath:(OFString *)source toPath:(OFString *)destination
{
#if !__has_feature(objc_arc)
    void* pool = objc_autoreleasePoolPush();
#endif

    OFSMBItem* item = [self itemAtPath:source];

    if (!item) {
#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif
        @throw [OFRemoveItemFailedException exceptionWithPath:source errNo:ENOENT];
    }

    item = [self itemAtPath:destination];

    if (item) {
#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif
        @throw [OFCreateDirectoryFailedException exceptionWithPath:destination errNo:EEXIST];
    }

    int rc = 0;

    rc = smb_file_mv(self.session, _tid, source.UTF8String, destination.UTF8String);

    if (rc == DSM_ERROR_NT)
        rc = (int)smb_session_get_nt_status(self.session);

    if (rc != 0) {
#if !__has_extension(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif
        @throw [OFSMBErrorException exceptionWithDSMError:rc];
    }

#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif
}

- (void)dowloadFileAtPath:(OFString *)path processingBlock:(void(^)(void* buffer, size_t length))processingBlock
{
#if !__has_feature(objc_arc)
  void* pool = objc_autoreleasePoolPush();
#endif

  OFSMBItem* item = [self itemAtPath:path];

  if (item == nil) {
#if !__has_extension(objc_arc)
    objc_autoreleasePoolPop(pool);
#endif
    @throw [OFOpenItemFailedException exceptionWithPath:path errNo:ENOENT];
  }

  size_t bufferSize = 65535;
  char* buffer = (char *)__builtin_alloca(bufferSize);
  void* ptr = NULL;
  size_t bytesToRead = item.size;
  size_t rc = 0;

  smb_fd fileID = 0;

  smb_fopen(self.session, *(self.share), item.path.UTF8String, SMB_MOD_RO, &fileID);

  if (!fileID) {
#if !__has_extension(objc_arc)
    [item retain];

    objc_autoreleasePoolPop(pool);
#endif
    [item autorelease];

    @throw [OFOpenItemFailedException exceptionWithPath:item.path];
  }

  do {
      rc = smb_fread(self.session, fileID, (void *)buffer, bufferSize);

      if (rc == -1) {
#if !__has_extension(objc_arc)
        objc_autoreleasePoolPop(pool);
#endif
        @throw [OFReadFailedException exceptionWithObject:self requestedLength:bufferSize];
      }

      ptr = buffer;
      processingBlock(ptr, rc);
      bytesToRead -= rc;
      ptr = NULL;

    } while (bytesToRead > 0);

  smb_fclose(self.session, fileID);

#if !__has_extension(objc_arc)
  objc_autoreleasePoolPop(pool);
#endif
}

@end

@implementation OFSMBAuthenticationFailedException{
    OFString *_domain;
    OFString *_login;
    OFString *_password;

}

@synthesize domain = _domain;
@synthesize login = _login;
@synthesize password = _password;

- (instancetype)initWithDomain:(OFString *)domain login:(OFString *)login password:(OFString *)password
{
    self = [super init];

    self.domain = domain;
    self.login = login;
    self.password = password;

    return self;
}

+ (instancetype)exceptionWithDomain:(OFString *)domain login:(OFString *)login password:(OFString *)password
{
#if !__has_feature(objc_arc)
    return [[[self alloc] initWithDomain:domain login:login password:password] autorelease];
#else
    return [[self alloc] initWithDomain:domain login:login password:password];
#endif
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"Ivalid username %@\%@ or password %@", self.domain, self.login, self.password.SHA1Hash];
}

@end


@implementation OFSMBErrorException{
    int _errorNumber;
}

@synthesize errorNumber = _errorNumber;

- (instancetype)initWithDSMError:(int)errorNumber
{
    self = [super init];

    self.errorNumber = errorNumber;

    return self;
}

+ (instancetype)exceptionWithDSMError:(int)errorNumber
{
#if !__has_feature(objc_arc)
    return [[[self alloc] initWithDSMError:errorNumber] autorelease];
#else
    return [[self alloc] initWithDSMError:errorNumber];
#endif
}

- (OFString *)description
{
    OFMutableString* res = [OFMutableString stringWithFormat:@"LibDSM error 0x%08x", self.errorNumber];

    switch(self.errorNumber) {
    case DSM_SUCCESS:
        [res appendUTF8String:" (Success)."];
        break;
    default:
        [res appendUTF8String:" (Unknown)."];
        break;
    }

    [res makeImmutable];
    return res;
}

@end

@implementation OFSMBItem{
    OFString *_name;
    OFString *_path;
    uint64_t _size;
    uint64_t _diskSize;
    BOOL _isDirectory;
    OFDate *_creationDate;
    OFDate *_lastAccessDate;
    OFDate *_lastWriteDate;
    OFDate *_lastModificationDate;

}

@synthesize name = _name;
@synthesize path = _path;
@synthesize size = _size;
@synthesize diskSize = _diskSize;
@synthesize isDirectory = _isDirectory;
@synthesize creationDate = _creationDate;
@synthesize lastAccessDate = _lastAccessDate;
@synthesize lastWriteDate = _lastWriteDate;
@synthesize lastModificationDate = _lastModificationDate;

+ (instancetype)item
{
#if !__has_feature(objc_arc)
    return [[[self alloc] init] autorelease];
#else
    return [[self alloc] init];
#endif
}

- (void)dealloc
{
#if !__has_feature(objc_arc)
    [_name release];
    [_path release];
    [_creationDate release];
    [_lastAccessDate release];
    [_lastModificationDate release];
    [_lastWriteDate release];

    [super dealloc];
#endif
}

- (OFString *)description
{
    return [OFString stringWithFormat:@"%@: %@ (%@)", (self.isDirectory ? @"Directory" : @"File"), self.name, self.path];
}

@end

