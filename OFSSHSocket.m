#import <ObjFW/ObjFW.h>
#import "OFSSHSocket.h"
#import "OFUniversalException.h"

#include <libssh2.h>
#include <libssh2_sftp.h>

@interface OFSSHSocket()

@property (nonatomic) LIBSSH2_SESSION* session;

- (of_ssh_auth_options_t)_hostAuthTypes;
- (OFString *)_hostKeyHash;
- (void)_authWithPasswordAtHost:(OFString *)host;
- (void)_authWitnKeyboardInteractiveAtHost:(OFString *)host;
- (void)_authWithPublicKeyAtHost:(OFString *)host;
- (int)_waitSocket;
- (void)_raiseLibSSHException:(OFString * _Nonnull)name description:(OFString * _Nonnull)description;

@end

@implementation OFSSHSocket{
  OFString* _userName;
  OFString* _password;
  OFString* _publicKey;
  OFString* _privateKey;
  of_ssh_auth_options_t _authOptions;
  of_ssh_host_hash_t _hostHashType;
  id<OFSSHSocketDelegate> _delegate;
  BOOL _useCompression;

  LIBSSH2_SESSION* _session;
}

@synthesize userName = _userName;
@synthesize password = _password;
@synthesize session = _session;
@synthesize authOptions = _authOptions;
@synthesize hostHashType = _hostHashType;
@synthesize publicKey = _publicKey;
@synthesize privateKey = _privateKey;
@synthesize delegate = _delegate;
@synthesize useCompression = _useCompression;

+ (void)initialize
{
  if (self != [OFSSHSocket class])
    return;

  int rc;

  if ((rc = libssh2_init(0)) != 0)
    @throw [OFInitializationFailedException exceptionWithClass:[OFSSHSocket class]];
}

+ (void)unload
{
  libssh2_exit();
}

- (instancetype)init
{
  self = [super init];

  self.session = NULL;
  self.userName = nil;
  self.password = nil;
  self.publicKey =nil;
  self.privateKey = nil;
  self.authOptions = 0;
  self.hostHashType = kSHA1Hash;
  self.delegate = nil;
  self.useCompression = NO;

  return self;
}

- (void)dealloc
{
  if (self.session != NULL)
    [self close];

  [_userName release];
  [_password release];
  [_publicKey release];
  [_privateKey release];
  _delegate = nil;

  [super dealloc];
}

- (void)close
{
  if (self.session != NULL) {
      libssh2_session_disconnect(self.session, "");

      libssh2_session_free(self.session);

      self.session = NULL;
    }

  [super close];

}

- (void)connectToHost:(OFString *)host port:(uint16_t)port
{
  if (self.userName == nil)
    [OFException raise:@"Invalid user name" format:@"User name shouldn`t be nil!"];

  if (self.password == nil)
    [OFException raise:@"Invalid password" format:@"Password shouldn`t be nil"];

  [super connectToHost:host port:port];

  self.session = libssh2_session_init_ex(NULL, NULL, NULL, (__bridge void *)self);

  if (self.session == NULL) {
    [super close];

    [OFException raise:@"SSH connection failed" format:@"SSH session not initialized!"];
    }


  libssh2_session_flag(self.session, LIBSSH2_FLAG_COMPRESS, self.useCompression ? 1 : 0);
  libssh2_session_set_blocking(self.session, 0);

  int rc;

  while ((rc = libssh2_session_handshake(self.session, self->_socket)) == LIBSSH2_ERROR_EAGAIN);

  if (rc != 0) {
      id exception;
      @try {
        [self _raiseLibSSHException:@"SSHConnectionFailed" description:[OFString stringWithFormat:@"Cannot connect to SSH host %@:%zu", host, port]];
      } @catch (id e) {
        exception = e;
      }

      libssh2_session_free(self.session);
      [super close];

      @throw exception;
    }

  if (self.delegate != nil) {
      if ([self.delegate respondsToSelector:@selector (connection:recivedHostKeyHash:exception:)]) {
          OFString* hash = nil;
          OFException* exception = nil;

          @autoreleasepool {
            @try {
              hash = [self _hostKeyHash].retain;
            } @catch (OFException* e) {
              exception = e.retain;
            }
          }

          [hash autorelease];
          [exception autorelease];

          if (![self.delegate connection:self recivedHostKeyHash:hash exception:exception]) {
              libssh2_session_free(self.session);

              [super close];

              [OFException raise:@"SSHConnectionFailed" format:@"Cannot connect to %@:%zu! Host key hash not accepted or get error. <Error: %@>", host, port, exception];
            }
        }
    }

  of_ssh_auth_options_t serverAuthOptions = [self _hostAuthTypes];

  if (serverAuthOptions == 0)
    serverAuthOptions = (kPassword | kKeyboardInteractive | kPublicKey);

  if ((serverAuthOptions & self.authOptions) == 0) {
      libssh2_session_free(self.session);
      [super close];

      [OFException raise:@"Authentification method not supported" format:@"No supported authentication methods found!\nServer %@:%zu does not support client allowed authentication methods", host, port];
    }

  @autoreleasepool {
    @try {
      OFString* authHost = [OFString stringWithFormat:@"%@:%zu", host, port];

      if (((serverAuthOptions & self.authOptions) & kPassword) == kPassword)
        [self _authWithPasswordAtHost:authHost];
      else if (((serverAuthOptions & self.authOptions) & kKeyboardInteractive) == kKeyboardInteractive)
        [self _authWitnKeyboardInteractiveAtHost:authHost];
      else if (((serverAuthOptions & self.authOptions) & kPublicKey) == kPublicKey)
        [self _authWithPublicKeyAtHost:authHost];


    }@catch (id e) {
      libssh2_session_free(self.session);
      [super close];

      @throw e;
    }
  }

}

- (OFString *)_hostKeyHash
{
  const char* fingerprint = NULL;

  if ((fingerprint = libssh2_hostkey_hash(self.session, self.hostHashType)) == NULL) {

      [self _raiseLibSSHException:@"GetHostKeyHashError" description:@"Cannot get key hash from host"];
    }

  OFDataArray* fingerprintData = [OFDataArray dataArrayWithItemSize:sizeof (unsigned char) capacity:(self.hostHashType == kMD5Hash) ? 16 : 20];

  [fingerprintData addItems:fingerprint count:(self.hostHashType == kMD5Hash) ? 16 : 20];

  return fingerprintData.stringRepresentation;
}

- (of_ssh_auth_options_t)_hostAuthTypes
{
  of_ssh_auth_options_t result;

  char* userauthlist = NULL;

  int rc = 0;

  while (((userauthlist = libssh2_userauth_list(self.session, self.userName.UTF8String, self.userName.UTF8StringLength)) == NULL) && ((rc = libssh2_session_last_errno(self.session)) == LIBSSH2_ERROR_EAGAIN));

  if ((userauthlist == NULL) || rc != 0)
      return 0;

  @autoreleasepool {
    OFString* userAuthList = [OFString stringWithUTF8StringNoCopy:userauthlist freeWhenDone:false];

    OFArray<OFString*>* authList = [userAuthList componentsSeparatedByString:@","];

    for (OFString* authType in authList) {
        authType = authType.stringByDeletingEnclosingWhitespaces;

        if ([authType caseInsensitiveCompare:@"password"] == OF_ORDERED_SAME)
          result |= kPassword;
        else if ([authType caseInsensitiveCompare:@"keyboard-interactive"] == OF_ORDERED_SAME)
          result |= kKeyboardInteractive;
        else if ([authType caseInsensitiveCompare:@"publickey"] == OF_ORDERED_SAME)
          result |= kPublicKey;
        else
          continue;
      }
  }

  return result;
}

- (void)_authWithPasswordAtHost:(OFString *)host
{
  int rc = 0;

  while ((rc = libssh2_userauth_password(self.session, self.userName.UTF8String, self.password.UTF8String)) == LIBSSH2_ERROR_EAGAIN);

  if (rc != 0) {
      char* messageBuffer;
      int messageLen = 0;

      OFString* errorDescription = nil;

      libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

      if (messageLen > 0) {
          errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
        }

      [OFException raise:@"Password Authentication failed" format:@"Authentication by password failed!\n%@: %@", host, errorDescription];
    }
}

- (void)_authWithPublicKeyAtHost:(OFString *)host
{
  if ((self.publicKey == nil) || self.publicKey.length <= 0)
    [OFException raise:@"Empty PublicKey" format:@"PublicKey property of %@ is <%@>", self, self.publicKey];

  if ((self.privateKey == nil) || self.privateKey.length <= 0)
    [OFException raise:@"Empty PrivateKey" format:@"PrivateKey property of %@ is <%@>", self, self.privateKey];

  int rc = 0;

  @autoreleasepool {
    OFDataArray* pubKey = [OFDataArray dataArrayWithContentsOfFile:self.publicKey];
    OFDataArray* priKey = [OFDataArray dataArrayWithContentsOfFile:self.privateKey];

    while ((rc = libssh2_userauth_publickey_frommemory(self.session, self.userName.UTF8String, self.userName.UTF8StringLength,
                                                       (const char *)pubKey.items, (pubKey.itemSize * pubKey.count),
                                                       (const char *)priKey.items, (priKey.itemSize * priKey.count),
                                                       self.password.UTF8String)) == LIBSSH2_ERROR_EAGAIN);

    if (rc != 0) {
        char* messageBuffer;
        int messageLen = 0;

        OFString* errorDescription = nil;

        libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

        if (messageLen > 0) {
            errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
          }

        [OFException raise:@"PublicKey Authentication failed" format:@"Authentication by PublicKey failed!\n%@: %@", host, errorDescription];
      }

  }

}

- (void)_authWitnKeyboardInteractiveAtHost:(OFString *)host
{
  OF_UNRECOGNIZED_SELECTOR
}

- (void)lowlevelWriteBuffer:(const void *)buffer length:(size_t)length
{
  OF_UNRECOGNIZED_SELECTOR
}

- (size_t)lowlevelReadIntoBuffer:(void *)buffer length:(size_t)length
{
  OF_UNRECOGNIZED_SELECTOR
}

- (int)_waitSocket
{
  struct timeval timeout;
  int rc;
  fd_set fd;
  fd_set *writefd = NULL;
  fd_set *readfd = NULL;
  int dir;

  timeout.tv_sec = 10;
  timeout.tv_usec = 0;

  FD_ZERO(&fd);

  FD_SET(self->_socket, &fd);

  dir = libssh2_session_block_directions(self.session);

  if (dir & LIBSSH2_SESSION_BLOCK_INBOUND)
    readfd = &fd;

  if (dir & LIBSSH2_SESSION_BLOCK_OUTBOUND)
    writefd = &fd;

  rc = select(self->_socket + 1, readfd, writefd, NULL, &timeout);

  return rc;

}

- (void)_raiseLibSSHException:(OFString *)name description:(OFString *)description
{
  char* messageBuffer;
  int messageLen = 0;

  OFString* errorDescription = nil;

  libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

  if (messageLen > 0) {
      errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
    }

  [OFException raise:name format:@"%@! (%@)", description, errorDescription];
}

@end

/*
 *
 *
 *  OFSFTPSocket Private interface
 *
 *
 *
*/

@interface OFSFTPSocket()

@property (nonatomic) LIBSSH2_SFTP* sftpSession;
@property (nonatomic) LIBSSH2_SFTP_HANDLE* sftpHandle;
@property (nonatomic) BOOL isFileHandle;
@property (nonatomic, assign) OFDataArray* buffer;
@property (nonatomic) LIBSSH2_SFTP_ATTRIBUTES attributes;
@property (nonatomic, copy, nullable) OFString* currentHandlePath;
@property (nonatomic) of_sftp_file_mode_t currentHandleMode;
@property (nonatomic) int currentHandlePermissions;

- (LIBSSH2_SFTP_HANDLE *)_openHandleAtPath:(OFString * _Nonnull)path flags:(unsigned long)flags mode:(long)mode type:(int)type;
- (void)_closeHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle;
- (void)_shutdown;
- (size_t)_readFromHandle:(LIBSSH2_SFTP_HANDLE *)handle intoBuffer:(char * _Nonnull)buffer length:(size_t)length;
- (size_t)_writeToHandle:(LIBSSH2_SFTP_HANDLE *)handle fromBuffer:(const char * _Nonnull)buffer length:(size_t)length;
- (LIBSSH2_SFTP_ATTRIBUTES)_attrinutesOfHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle;
- (void)_setAttributes:(LIBSSH2_SFTP_ATTRIBUTES)attributes forHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle;
- (of_offset_t)_seekHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle toOffset:(of_offset_t)offset whence:(int)whence;
- (void)_fsyncHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle;

@end

/*
 *
 *
 *   OFSFTPRemoteFSEntry Private interface
 *
 *
 */

@interface OFSFTPRemoteFSEntry()

@property (nonatomic, readwrite) of_offset_t size;
@property (nonatomic, readwrite, nullable, copy) OFDate* lastAccessTime;
@property (nonatomic, readwrite, nullable, copy) OFDate* modifiedTime;
@property (nonatomic, readwrite) BOOL isDirectory;
@property (nonatomic, readwrite) BOOL isSymlink;
@property (nonatomic, readwrite, nonnull, copy) OFString* name;
@property (nonatomic, readwrite, nonnull, copy) OFString* path;
@property (nonatomic, readwrite) unsigned long uid;
@property (nonatomic, readwrite) unsigned long gid;
@property (nonatomic, readwrite) unsigned long permissions;

@property (nonatomic) LIBSSH2_SFTP_HANDLE* handle;
@property (nonatomic, assign, readwrite, nullable) OFSFTPSocket* source;

- (void)_fillProperties;
- (instancetype)_initWithPath:(OFString * _Nonnull)path source:(OFSFTPSocket * _Nonnull)source;
+ (OFSFTPRemoteFSEntry * _Nonnull) _entryWithPath:(OFString * _Nonnull)path source:(OFSFTPSocket * _Nonnull)source;

@end

/*
 *
 *
 *  OFSFTPSocket implementation
 *
 *
*/


@implementation OFSFTPSocket{
  LIBSSH2_SFTP* _sftpSession;
  LIBSSH2_SFTP_HANDLE* _sftpHandle;
  BOOL _isFileHandle;
  OFDataArray* _buffer;
  OFString* _currentHandlePath;
  of_sftp_file_mode_t _currentHandleMode;
  int _currentHandlePermissions;
}

@synthesize sftpSession = _sftpSession;
@synthesize sftpHandle = _sftpHandle;
@synthesize isFileHandle = _isFileHandle;
@synthesize buffer = _buffer;
@synthesize currentHandlePath = _currentHandlePath;
@synthesize currentHandleMode = _currentHandleMode;
@synthesize currentHandlePermissions = _currentHandlePermissions;
@dynamic attributes;
@dynamic size;
@dynamic lastAccessTime;
@dynamic modifiedTime;

- (instancetype)init
{
  self = [super init];

  self.sftpHandle = NULL;
  self.sftpHandle = NULL;
  self.isFileHandle = NO;
  self.buffer = nil;
  self.currentHandlePath = nil;
  self.currentHandleMode = 0;
  self.currentHandlePermissions = 0;

  return self;
}

- (void)dealloc
{
  [_currentHandlePath release];

  [self close];

  [super dealloc];
}

- (void)close
{
  if (self.sftpHandle != NULL) {
      [self _closeHandle:self.sftpHandle];
      self.sftpHandle = NULL;
    }

  if (self.sftpSession != NULL) {
      [self _shutdown];
      self.sftpSession = NULL;
    }

  [_buffer release];

  [super close];
}


- (void)_setAttributes:(LIBSSH2_SFTP_ATTRIBUTES)attributes forHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle
{
  int rc = 0;

  do {

      rc = libssh2_sftp_fstat_ex(handle, &attributes, 1);

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else
        [self _raiseLibSSHException:@"SetSFTPHandleAttributesError" description:@"Cannot set SFTP handle attributes"];

    } while (true);
}

- (void)setAttributes:(LIBSSH2_SFTP_ATTRIBUTES)attributes
{
    if (self.sftpHandle == NULL)
        [OFException raise:@"EmptySFTPHandleError" format:@"SFTP handle of %@ is empty!", self];

    [self _setAttributes:attributes forHandle:self.sftpHandle];
}

- (LIBSSH2_SFTP_ATTRIBUTES)_attrinutesOfHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle
{
  LIBSSH2_SFTP_ATTRIBUTES attrs;
  int rc = 0;

  do {
      rc = libssh2_sftp_fstat_ex(handle, &attrs, 0);

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else
        [self _raiseLibSSHException:@"GetSFTPHandleAttributesError" description:@"Cannot get SFTP handle attributes"];

    } while (true);

  return attrs;
}

- (LIBSSH2_SFTP_ATTRIBUTES)attributes
{
    if (self.sftpHandle == NULL)
        [OFException raise:@"EmptySFTPHandleError" format:@"SFTP handle of %@ is empty!", self];

    return [self _attrinutesOfHandle:self.sftpHandle];
}

- (void)connectToHost:(OFString *)host port:(uint16_t)port
{
  [super connectToHost:host port:port];

  int rc = 0;

  do {

      self.sftpSession = libssh2_sftp_init(self.session);

      if ((self.sftpSession == NULL) && ((rc = libssh2_session_last_errno(self.session)) != LIBSSH2_ERROR_EAGAIN)) {
          [self _raiseLibSSHException:@"SFTPConnectionFailed" description:[OFString stringWithFormat:@"Cannot initialize SFTP session for host %@:%zu", host, port]];
        }

      [self _waitSocket];

    } while (self.sftpSession == NULL);

}

- (size_t)_writeToHandle:(LIBSSH2_SFTP_HANDLE *)handle fromBuffer:(const char * _Nonnull)buffer length:(size_t)length
{
  size_t res = 0;
  int rc = 0;
  const char* ptr = buffer;
  size_t bytesToWrite = length;

  do {

      rc = libssh2_sftp_write(handle, ptr, bytesToWrite);

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else if (rc > 0) {
          ptr += rc;
          bytesToWrite -= rc;
          res += rc;
        } else {
          [self _raiseLibSSHException:@"HandleWriteError" description:[OFString stringWithFormat:@"Cannot write %zu bytes in SFTP handle", bytesToWrite]];
        }

    } while (true);


  return res;
}

- (void)lowlevelWriteBuffer:(const void *)buffer length:(size_t)length
{
  if ((self.sftpHandle == NULL) && (!self.isFileHandle)) {
      [OFException raise:@"InvalidHandleError" format:@"Cannot write to %@ handle!", (self.sftpHandle == NULL) ? @"nullable" : ((!self.isFileHandle) ? @"directory" : @"invalid")];
    }

  if (self.buffer == nil)
    self.buffer = [[OFDataArray alloc] initWithItemSize:sizeof(unsigned char)];

  [self.buffer addItems:buffer count:length];

  size_t writed = [self _writeToHandle:self.sftpHandle fromBuffer:(const char *)self.buffer.items length:self.buffer.count];

  if (writed == self.buffer.count)
    [self.buffer removeAllItems];
  else {
      of_range_t bytesToRemove = of_range(0, writed);

      [self.buffer removeItemsInRange:bytesToRemove];
    }

}

- (size_t)_readFromHandle:(LIBSSH2_SFTP_HANDLE *)handle intoBuffer:(char * _Nonnull)buffer length:(size_t)length
{
  size_t res = 0;
  int rc = 0;
  size_t bytesToRead = length;
  char* tmp = (char *)__builtin_alloca(bytesToRead);
  memset(tmp, 0, bytesToRead);
  char* ptr = buffer;

  do {
      rc = libssh2_sftp_read(handle, tmp, bytesToRead);

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else if (rc > 0) {
          memcpy(ptr, tmp, rc);
          ptr += rc;
          bytesToRead -= rc;
          res += rc;

          memset(tmp, 0, bytesToRead);
        } else {
          [self _raiseLibSSHException:@"HandleReadError" description:[OFString stringWithFormat:@"Cannot read %zu bytes from SFTP handle", bytesToRead]];
        }

    } while (true);

  return res;

}

- (size_t)lowlevelReadIntoBuffer:(void *)buffer length:(size_t)length
{
  if ((self.sftpHandle == NULL) && (!self.isFileHandle)) {
      [OFException raise:@"InvalidHandleError" format:@"Cannot write to %@ handle!", (self.sftpHandle == NULL) ? @"nullable" : ((!self.isFileHandle) ? @"directory" : @"invalid")];
    }

  size_t res = [self _readFromHandle:self.sftpHandle intoBuffer:(char *)buffer length:length];

  return res;
}

- (LIBSSH2_SFTP_HANDLE *)_openHandleAtPath:(OFString * _Nonnull)path flags:(unsigned long)flags mode:(long)mode type:(int)type
{
  LIBSSH2_SFTP_HANDLE* res = NULL;
  int rc = 0;

  do {

      res = libssh2_sftp_open_ex(self.sftpSession, path.UTF8String, path.UTF8StringLength, flags, mode, type);

      if ((res == NULL) && ((rc = libssh2_session_last_errno(self.session)) != LIBSSH2_ERROR_EAGAIN))
        [self _raiseLibSSHException:@"SFTPHandleOpenError" description:[OFString stringWithFormat:@"Cannot open handle for remote %@ at %@", ((type == LIBSSH2_SFTP_OPENFILE) ? @"file" : @"directory"), path]];

      [self _waitSocket];

    } while (res == NULL);

  return res;
}

- (void)_closeHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle
{
  int rc = 0;

  do {

      rc = libssh2_sftp_close_handle(handle);

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else
        [self _raiseLibSSHException:@"CloseSFTPHandleError" description:@"Cannot close SFTP handle"];

    } while (true);
}

- (void)_shutdown
{
  if (self.sftpSession == NULL)
    [OFException raise:@"EmptySFTPSessionError" format:@"SFTP session already closed!"];

  int rc = 0;

  do {

      rc = libssh2_sftp_shutdown(self.sftpSession);

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else
        [self _raiseLibSSHException:@"SFTPSessionClosingError" description:[OFString stringWithFormat:@"Cannot close SFTP session of %@", self]];

    } while (true);
}

- (of_offset_t)_seekHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle toOffset:(of_offset_t)offset whence:(int)whence
{
  LIBSSH2_SFTP_ATTRIBUTES attrs = [self _attrinutesOfHandle:handle];

  if ((attrs.flags & LIBSSH2_SFTP_ATTR_PERMISSIONS) != LIBSSH2_SFTP_ATTR_PERMISSIONS)
    [OFException raise:@"InvalidHandleError" format:@"Cannot check handle type!"];

  if (LIBSSH2_SFTP_S_ISDIR(attrs.permissions))
    [OFException raise:@"InvalidHandleError" format:@"Handle is not a file!"];

  if ((attrs.flags & LIBSSH2_SFTP_ATTR_SIZE) != LIBSSH2_SFTP_ATTR_SIZE)
    [OFException raise:@"InvalidHandleError" format:@"Cannot get size of file associated with handle!"];

  if (offset > attrs.filesize)
    @throw [OFOutOfRangeException exception];


  switch (whence) {
    case SEEK_SET:
      {
        libssh2_sftp_rewind(handle);
        libssh2_sftp_seek64(handle, offset);
      }
      break;
    case SEEK_CUR:
      {
        offset += (of_offset_t)libssh2_sftp_tell64(handle);
        if (offset > attrs.filesize)
          @throw [OFOutOfRangeException exception];

        libssh2_sftp_rewind(handle);
        libssh2_sftp_seek64(handle, offset);
      }
      break;
    case SEEK_END:
      {
        if (offset > 0)
          @throw [OFOutOfRangeException exception];

        offset += (of_offset_t)libssh2_sftp_tell64(handle);
        libssh2_sftp_rewind(handle);
        libssh2_sftp_seek64(handle, offset);
      }
      break;
    default:
      [OFException raise:@"invalidArgument" format:@"Whence should be SEEK_SET, SEEK_CUR or SEEK_END!"];
      break;
    }

  return (of_offset_t)libssh2_sftp_tell64(handle);

}

- (void)openDirectory:(OFString *)path
{

  if ([self.currentHandlePath isEqual:path])
      return;

  if (self.sftpHandle != NULL) {
      [self _closeHandle:self.sftpHandle];

      self.sftpHandle = NULL;
      self.currentHandlePath = nil;
      self.currentHandleMode = 0;
      self.currentHandlePermissions = 0;

      self.isFileHandle = NO;
    }

  self.sftpHandle = [self _openHandleAtPath:path flags:0 mode:0 type:LIBSSH2_SFTP_OPENDIR];

  self.currentHandlePath = path;

}

- (void)openFile:(OFString *)file mode:(of_sftp_file_mode_t)mode rights:(int)rights
{

  if ([self.currentHandlePath isEqual:file] && (self.currentHandleMode == mode) && (self.currentHandlePermissions == rights))
      return;

  if (self.sftpHandle != NULL) {
      if (self.buffer != nil) {
          [self lowlevelWriteBuffer:"" length:0];

        }

      [self _closeHandle:self.sftpHandle];

      self.sftpHandle = NULL;
      self.isFileHandle = NO;
      self.currentHandlePath = nil;
      self.currentHandleMode = 0;
      self.currentHandlePermissions = 0;
    }

  self.sftpHandle = [self _openHandleAtPath:file flags:mode mode:rights type:LIBSSH2_SFTP_OPENFILE];

  self.isFileHandle = YES;
  self.currentHandlePath = file;
  self.currentHandleMode = mode;
  self.currentHandlePermissions = rights;

}

- (void)createDirectoryAtPath:(OFString *)path rights:(int)rights
{
  int rc = 0;

  do {
      rc = libssh2_sftp_mkdir_ex(self.sftpSession, path.UTF8String, path.UTF8StringLength, rights);

      if (rc == 0)
          break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
          [self _waitSocket];
      else
        [self _raiseLibSSHException:@"SFTPCreateDirectoryError" description:[OFString stringWithFormat:@"Cannot create directory at %@", path]];

  } while (true);

}

- (OFArray<OFSFTPRemoteFSEntry*> *)contentOfDirectoryAtPath:(OFString *)path
{
  LIBSSH2_SFTP_HANDLE* dirHandle = NULL;

  if ([path isEqual:self.currentHandlePath])
    dirHandle = self.sftpHandle;
  else {
      dirHandle = [self _openHandleAtPath:path flags:0 mode:0 type:LIBSSH2_SFTP_OPENDIR];
    }

  OFMutableArray<OFSFTPRemoteFSEntry*>* content = [OFMutableArray array];

  char buffer[4096];
  //char longentry[512];
  LIBSSH2_SFTP_ATTRIBUTES attrs;
  int rc = 0;

  @autoreleasepool {
    do {
        memset(buffer, 0, sizeof(buffer));
        //memset(longentry, 0, sizeof(longentry));

        while ((rc = libssh2_sftp_readdir(dirHandle, buffer, sizeof(buffer), &attrs)) == LIBSSH2_ERROR_EAGAIN)
          [self _waitSocket];

        if (rc > 0) {

            OFString* element = [OFString stringWithUTF8String:buffer length:rc];

            if ([element isEqual:@"."] || [element isEqual:@".."])
              continue;

            OFSFTPRemoteFSEntry* entry = [OFSFTPRemoteFSEntry entry];

            entry.name = element;
            entry.path = [@[path, element] componentsJoinedByString:@"/"];

            if (attrs.flags & LIBSSH2_SFTP_ATTR_SIZE)
                entry.size = (of_offset_t)attrs.filesize;


            if (attrs.flags & LIBSSH2_SFTP_ATTR_PERMISSIONS) {
                if (LIBSSH2_SFTP_S_ISDIR(attrs.permissions))
                  entry.isDirectory = YES;

                if (LIBSSH2_SFTP_S_ISLNK(attrs.permissions))
                  entry.isSymlink = YES;

                entry.permissions = attrs.permissions;
              }

            if (attrs.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) {

              of_time_interval_t atm = 0.0;
              of_time_interval_t mtm = 0.0;

              atm += attrs.atime;
              mtm += attrs.mtime;

              if (atm > 0.0)
                entry.lastAccessTime = [OFDate dateWithTimeIntervalSince1970:atm];

              if (mtm > 0.0)
                entry.modifiedTime = [OFDate dateWithTimeIntervalSince1970:mtm];
            }

            if (attrs.flags & LIBSSH2_SFTP_ATTR_UIDGID) {
              entry.gid = attrs.gid;
              entry.uid = attrs.uid;

            }

            entry.source = self;

            [content addObject:entry];

          } else if (rc == 0) {
            break;

          } else if (rc != LIBSSH2_ERROR_EAGAIN) {

            if (![path isEqual:self.currentHandlePath])
              [self _closeHandle:dirHandle];


            [self _raiseLibSSHException:@"DirectoryEnumirationError" description:[OFString stringWithFormat:@"Cannot enumirate conent of directory %@", path]];
          }

      } while (true);

  }

  [content makeImmutable];

  if (![path isEqual:self.currentHandlePath])
    [self _closeHandle:dirHandle];

  return content;
}

- (of_offset_t)sizeOfFileAtPath:(OFString *)path
{
    if ([path isEqual:self.currentHandlePath])
      return self.size;

    LIBSSH2_SFTP_HANDLE* handle = [self _openHandleAtPath:path flags:kSFTPRead mode:0 type:LIBSSH2_SFTP_OPENFILE];

    LIBSSH2_SFTP_ATTRIBUTES attr = [self _attrinutesOfHandle:handle];

    [self _closeHandle:handle];

    if ((attr.flags & LIBSSH2_SFTP_ATTR_SIZE) != LIBSSH2_SFTP_ATTR_SIZE)
      return 0;

    of_offset_t res = 0;

    res += attr.filesize;

    return res;

}

- (of_offset_t)sizeOfDirectoryAtPath:(OFString *)path
{
    if ([path isEqual:self.currentHandlePath])
      return self.size;

    LIBSSH2_SFTP_HANDLE* handle = [self _openHandleAtPath:path flags:0 mode:0 type:LIBSSH2_SFTP_OPENDIR];

    LIBSSH2_SFTP_ATTRIBUTES attr = [self _attrinutesOfHandle:handle];

    [self _closeHandle:handle];

    if ((attr.flags & LIBSSH2_SFTP_ATTR_SIZE) != LIBSSH2_SFTP_ATTR_SIZE)
      return 0;

    of_offset_t res = 0;

    res += attr.filesize;

    return res;
}

- (OFDate * _Nullable)accessTimeOfFileAtPath:(OFString * _Nonnull)path
{
    if ([path isEqual:self.currentHandlePath])
      return self.lastAccessTime;

    LIBSSH2_SFTP_HANDLE* handle = [self _openHandleAtPath:path flags:kSFTPRead mode:0 type:LIBSSH2_SFTP_OPENFILE];

    LIBSSH2_SFTP_ATTRIBUTES attr = [self _attrinutesOfHandle:handle];

    [self _closeHandle:handle];

    if ((attr.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) != LIBSSH2_SFTP_ATTR_ACMODTIME)
      return nil;

    OFDate* result = nil;

    of_time_interval_t timeSince19970 = 0.0;

    timeSince19970 += attr.atime;

    if (timeSince19970 > 0.0)
        result = [OFDate dateWithTimeIntervalSince1970:timeSince19970];


    return result;
}

- (OFDate * _Nullable)modifiedTimeOfFileAtPath:(OFString * _Nonnull)path
{
    if ([path isEqual:self.currentHandlePath])
      return self.modifiedTime;

    LIBSSH2_SFTP_HANDLE* handle = [self _openHandleAtPath:path flags:kSFTPRead mode:0 type:LIBSSH2_SFTP_OPENFILE];

    LIBSSH2_SFTP_ATTRIBUTES attr = [self _attrinutesOfHandle:handle];

    [self _closeHandle:handle];

    if ((attr.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) != LIBSSH2_SFTP_ATTR_ACMODTIME)
      return nil;

    OFDate* result = nil;

    of_time_interval_t timeSince19970 = 0.0;

    timeSince19970 += attr.mtime;

    if (timeSince19970 > 0.0)
        result = [OFDate dateWithTimeIntervalSince1970:timeSince19970];


    return result;
}

- (OFDate * _Nullable)accessTimeOfDirectoryAtPath:(OFString * _Nonnull)path
{
    if ([path isEqual:self.currentHandlePath])
      return self.lastAccessTime;

    LIBSSH2_SFTP_HANDLE* handle = [self _openHandleAtPath:path flags:0 mode:0 type:LIBSSH2_SFTP_OPENDIR];

    LIBSSH2_SFTP_ATTRIBUTES attr = [self _attrinutesOfHandle:handle];

    [self _closeHandle:handle];

    if ((attr.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) != LIBSSH2_SFTP_ATTR_ACMODTIME)
      return nil;

    OFDate* result = nil;

    of_time_interval_t timeSince19970 = 0.0;

    timeSince19970 += attr.atime;

    if (timeSince19970 > 0.0)
        result = [OFDate dateWithTimeIntervalSince1970:timeSince19970];


    return result;
}

- (OFDate * _Nullable)modifiedTimeOfDirectoryAtPath:(OFString * _Nonnull)path
{
    if ([path isEqual:self.currentHandlePath])
      return self.modifiedTime;

    LIBSSH2_SFTP_HANDLE* handle = [self _openHandleAtPath:path flags:0 mode:0 type:LIBSSH2_SFTP_OPENDIR];

    LIBSSH2_SFTP_ATTRIBUTES attr = [self _attrinutesOfHandle:handle];

    [self _closeHandle:handle];

    if ((attr.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) != LIBSSH2_SFTP_ATTR_ACMODTIME)
      return nil;

    OFDate* result = nil;

    of_time_interval_t timeSince19970 = 0.0;

    timeSince19970 += attr.mtime;

    if (timeSince19970 > 0.0)
        result = [OFDate dateWithTimeIntervalSince1970:timeSince19970];


    return result;
}

- (of_offset_t)size
{
  if ((self.sftpHandle == NULL) || (nil == self.currentHandlePath))
    return 0;

  LIBSSH2_SFTP_ATTRIBUTES attr = self.attributes;

  if ((attr.flags & LIBSSH2_SFTP_ATTR_SIZE) != LIBSSH2_SFTP_ATTR_SIZE)
    return 0;

  of_offset_t res = 0;

  res += attr.filesize;

  return res;
}

- (OFDate * _Nullable)lastAccessTime
{
  if ((self.sftpHandle == NULL) || (nil == self.currentHandlePath))
    return nil;

  LIBSSH2_SFTP_ATTRIBUTES attr = self.attributes;

  if ((attr.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) != LIBSSH2_SFTP_ATTR_ACMODTIME)
    return nil;

  OFDate* result = nil;

  of_time_interval_t timeSince19970 = 0.0;

  timeSince19970 += attr.atime;

  if (timeSince19970 > 0.0)
      result = [OFDate dateWithTimeIntervalSince1970:timeSince19970];


  return result;
}

- (OFDate * _Nullable)modifiedTime
{
  if ((self.sftpHandle == NULL) || (nil == self.currentHandlePath))
    return nil;

  LIBSSH2_SFTP_ATTRIBUTES attr = self.attributes;

  if ((attr.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) != LIBSSH2_SFTP_ATTR_ACMODTIME)
    return nil;

  OFDate* result = nil;

  of_time_interval_t timeSince19970 = 0.0;

  timeSince19970 += attr.mtime;

  if (timeSince19970 > 0.0)
      result = [OFDate dateWithTimeIntervalSince1970:timeSince19970];

  return result;
}

- (void)removeDirectoryAtPath:(OFString * _Nonnull)path
{
  if ([path isEqual:self.currentHandlePath])
    [self remove];
  else {
      int rc = 0;

      do {
          rc = libssh2_sftp_rmdir_ex(self.sftpSession, path.UTF8String, path.UTF8StringLength);

          if (rc == 0)
            break;
          else if (rc == LIBSSH2_ERROR_EAGAIN)
            [self _waitSocket];
          else {
              [self _raiseLibSSHException:@"ItemRemoveFailed" description:[OFString stringWithFormat:@"Cannot remove directory at path %@", path]];
            }

        } while (true);
    }
}

- (void)removeFileAtPath:(OFString * _Nonnull)path
{
  if ([path isEqual:self.currentHandlePath])
    [self remove];
  else {
      int rc = 0;

      do {
          rc = libssh2_sftp_unlink_ex(self.sftpSession, path.UTF8String, path.UTF8StringLength);

          if (rc == 0)
            break;
          else if (rc == LIBSSH2_ERROR_EAGAIN)
            [self _waitSocket];
          else {
              [self _raiseLibSSHException:@"ItemRemoveFailed" description:[OFString stringWithFormat:@"Cannot remove file at path %@", path]];
            }

        } while (true);
    }
}

- (void)remove
{
  if (self.sftpSession == NULL)
    [OFException raise:@"Not connected" format:@"No SFTP connection!"];

  if (self.sftpHandle != NULL)
    [self _closeHandle:self.sftpHandle];

  int rc = 0;

  do {

      if (self.isFileHandle) {
          rc = libssh2_sftp_unlink_ex(self.sftpSession, self.currentHandlePath.UTF8String, self.currentHandlePath.UTF8StringLength);
        } else {
          rc = libssh2_sftp_rmdir_ex(self.sftpSession, self.currentHandlePath.UTF8String, self.currentHandlePath.UTF8StringLength);
        }

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else {
          [self _raiseLibSSHException:@"ItemRemoveFailed" description:[OFString stringWithFormat:@"Cannot remove %@ at path %@", (self.isFileHandle ? @"file" : @"directory"), self.currentHandlePath]];
        }

    } while (true);

  self.currentHandlePath = nil;
  self.currentHandleMode = 0;
  self.currentHandlePermissions = 0;
  self.sftpHandle = NULL;

}

- (OFSFTPRemoteFSEntry * _Nonnull)itemAtPath:(OFString * _Nonnull)path
{
  OFSFTPRemoteFSEntry* item;

  @autoreleasepool {
    item = [[OFSFTPRemoteFSEntry alloc] _initWithPath:path source:self];
  }

  return [item autorelease];
}

- (void)_fsyncHandle:(LIBSSH2_SFTP_HANDLE * _Nonnull)handle
{
  int rc = 0;

  do {

      rc = libssh2_sftp_fsync(handle);

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else
        [self _raiseLibSSHException:@"SFTPSyncError" description:@"SFTP fsync failed"];

    } while (true);
}

- (void)flush
{
  if (self.sftpHandle == NULL)
    [OFException raise:@"SFTPHandleError" format:@"SFTP handle of %@ is null!", self];

  [self _fsyncHandle:self.sftpHandle];
}

- (void)moveItemAtPath:(OFString * _Nonnull)source toDestination:(OFString * _Nonnull)destination
{
  if (self.sftpSession == NULL)
    [OFException raise:@"NotConnectedError" format:@"SFTP socket %@ not connected!", self];

  int rc = 0;

  do {

      rc = libssh2_sftp_rename_ex(self.sftpSession, source.UTF8String, source.UTF8StringLength,
                                  destination.UTF8String, destination.UTF8StringLength,
                                  (LIBSSH2_SFTP_RENAME_ATOMIC | LIBSSH2_SFTP_RENAME_NATIVE));

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self _waitSocket];
      else
        [self _raiseLibSSHException:@"SFTPRenameMoveError" description:[OFString stringWithFormat:@"Cannot move/rename %@ ---> %@", source, destination]];

    } while (true);
}

- (void)copyItemAtPath:(OFString * _Nonnull)source toDestination:(OFString * _Nonnull)destination
{
  OF_UNRECOGNIZED_SELECTOR
}

@end;


/*
 *
 *
 *  OFSFTPRemoteFSEntry implementation
 *
 *
*/

@implementation OFSFTPRemoteFSEntry{
  of_offset_t _size;
  OFDate* _lastAccessTime;
  OFDate* _modifiedTime;
  BOOL _isDirectory;
  BOOL _isSymlink;
  OFString* _name;
  OFString* _path;
  unsigned long _uid;
  unsigned long _gid;
  unsigned long _permissions;
  LIBSSH2_SFTP_HANDLE* _handle;
  OFSFTPSocket* _source;

  BOOL _isOpened;
}

@synthesize size = _size;
@synthesize lastAccessTime = _lastAccessTime;
@synthesize modifiedTime = _modifiedTime;
@synthesize isDirectory = _isDirectory;
@synthesize isSymlink = _isSymlink;
@synthesize name = _name;
@synthesize path = _path;
@synthesize uid =_uid;
@synthesize gid = _gid;
@synthesize permissions = _permissions;
@synthesize handle = _handle;
@synthesize source = _source;
@synthesize isOpened = _isOpened;

+ (OFSFTPRemoteFSEntry * _Nonnull)entry
{
  return [[[self alloc] init] autorelease];
}

- (instancetype)init
{
  self = [super init];

  _lastAccessTime = nil;
  _modifiedTime = nil;
  _name = nil;
  _path = nil;
  _size = 0;
  _isDirectory = NO;
  _isSymlink = NO;
  _uid = 0;
  _gid = 0;
  _permissions = 0;
  _handle = NULL;
  _source = nil;
  _isOpened = NO;

  return self;
}


- (void)dealloc
{
  [self close];

  [_lastAccessTime release];
  [_modifiedTime release];
  [_name release];
  [_path release];

  [super dealloc];
}

- (instancetype)_initWithPath:(OFString * _Nonnull)path source:(OFSFTPSocket * _Nonnull)source
{
  self = [super init];

  _lastAccessTime = nil;
  _modifiedTime = nil;
  _name = nil;
  _path = nil;
  _size = 0;
  _isDirectory = NO;
  _isSymlink = NO;
  _uid = 0;
  _gid = 0;
  _permissions = 0;
  _handle = NULL;
  _source = nil;
  _isOpened = NO;

  @try {
    self.handle = [source _openHandleAtPath:path flags:(kSFTPRead | kSFTPWrite | kSFTPAppend) mode:0 type:LIBSSH2_SFTP_OPENFILE];

  } @catch (...) {
    self.handle = NULL;
  }

  if ( self.handle == NULL) {
      @try {
        self.handle = [source _openHandleAtPath:path flags:0 mode:0 type:LIBSSH2_SFTP_OPENDIR] ;
      } @catch (...) {
        self.handle = NULL;
      }
    }

  if (self.handle == NULL) {
      [self release];

      @throw [OFInitializationFailedException exceptionWithClass:[OFSFTPRemoteFSEntry class]];
    }

  self.source = source;

  self.isOpened = YES;
  self.path = path;
  self.name = path.lastPathComponent;

  [self _fillProperties];

  return self;
}

+ (OFSFTPRemoteFSEntry * _Nonnull) _entryWithPath:(OFString * _Nonnull)path source:(OFSFTPSocket * _Nonnull)source
{
  return [[[self alloc] _initWithPath:path source:source] autorelease];
}

- (void)_fillProperties
{
  LIBSSH2_SFTP_ATTRIBUTES attrs = [self.source _attrinutesOfHandle:self.handle];

  if (attrs.flags & LIBSSH2_SFTP_ATTR_SIZE)
      self.size = (of_offset_t)attrs.filesize;


  if (attrs.flags & LIBSSH2_SFTP_ATTR_PERMISSIONS) {
      if (LIBSSH2_SFTP_S_ISDIR(attrs.permissions))
        self.isDirectory = YES;

      if (LIBSSH2_SFTP_S_ISLNK(attrs.permissions))
        self.isSymlink = YES;

      self.permissions = attrs.permissions;
    }

  if (attrs.flags & LIBSSH2_SFTP_ATTR_ACMODTIME) {

    of_time_interval_t atm = 0.0;
    of_time_interval_t mtm = 0.0;

    atm += attrs.atime;
    mtm += attrs.mtime;

    if (atm > 0.0)
      self.lastAccessTime = [OFDate dateWithTimeIntervalSince1970:atm];

    if (mtm > 0.0)
      self.modifiedTime = [OFDate dateWithTimeIntervalSince1970:mtm];
  }

  if (attrs.flags & LIBSSH2_SFTP_ATTR_UIDGID) {
    self.gid = attrs.gid;
    self.uid = attrs.uid;

  }

}

- (void)open
{
  if (self.isOpened)
    [OFException raise:@"AlreadyOpened" format:@"<%@:%p> already opened!", self.className, self];

  if (self.source == nil)
    [OFException raise:@"InvalidSourceError" format:@"Source of <%@:%p> is nil!", self.className, self];

  if (self.path == nil)
    [OFException raise:@"EmptyPathError" format:@"<%@:%p> has empty path property!", self.className, self];

  @autoreleasepool {
    if (self.isDirectory)
      self.handle = [self.source _openHandleAtPath:self.path flags:0 mode:0 type:LIBSSH2_SFTP_OPENDIR];
    else
      self.handle = [self.source _openHandleAtPath:self.path flags:(kSFTPRead | kSFTPWrite | kSFTPAppend) mode:0 type:LIBSSH2_SFTP_OPENFILE];

    [self _fillProperties];
  }


}

- (void)close
{
  if (!self.isOpened || self.handle == NULL)
    [OFException raise:@"AlreadyClosedError" format:@"<%@:%p> already closed!", self.className, self];

  if (self.source == nil)
    [OFException raise:@"InvalidSourceError" format:@"<%@:%p> has invalid SFTP source!", self.className, self];

  [self.source _closeHandle:self.handle];
}

- (void)remove
{
  [self close];

  int rc = 0;

  do {

      if (self.isDirectory && !self.isSymlink)
        rc = libssh2_sftp_rmdir_ex(self.source.sftpSession, self.path.UTF8String, self.path.UTF8StringLength);
      else
        rc = libssh2_sftp_unlink_ex(self.source.sftpSession, self.path.UTF8String, self.path.UTF8StringLength);

      if (rc == 0)
        break;
      else if (rc == LIBSSH2_ERROR_EAGAIN)
        [self.source _waitSocket];
      else
        [self.source _raiseLibSSHException:@"RemoveItemError" description:[OFString stringWithFormat:@"Cannot remove %@ at path %@", (self.isDirectory ? @"directory" : (self.isSymlink ? @"symlink" : @"file")), self.path]];

    } while (true);
}

- (OFDataArray * _Nonnull)read
{
  if (!self.isOpened || self.handle == NULL)
    [OFException raise:@"AlreadyClosedError" format:@"<%@:%p> already closed!", self.className, self];

  if (self.source == nil)
    [OFException raise:@"InvalidSourceError" format:@"<%@:%p> has invalid SFTP source!", self.className, self];

  if (self.size <= 0)
    [OFException raise:@"InvalidItemSize" format:@"<%@:%p> has invalid size %lld", self.className, self, self.size];

  if (self.isDirectory)
    [OFException raise:@"InvalidHandleError" format:@"<%@:%p> is directory! Can read from files only!", self.className, self];

  OFDataArray* data = [OFDataArray dataArrayWithItemSize:sizeof(unsigned char) capacity:self.size];

  size_t bytesToRead = self.size;
  size_t rc = 0;

  char* buffer = (char *)__builtin_alloca(512);

  do {

      memset(buffer, 0, 512);

      rc = [self.source _readFromHandle:self.handle intoBuffer:buffer length:512];

      [data addItems:buffer count:rc];

      bytesToRead -= rc;

    } while (bytesToRead > 0);


  return data;

}

- (void)write:(OFDataArray * _Nonnull)data
{
  if (!self.isOpened || self.handle == NULL)
    [OFException raise:@"AlreadyClosedError" format:@"<%@:%p> already closed!", self.className, self];

  if (self.source == nil)
    [OFException raise:@"InvalidSourceError" format:@"<%@:%p> has invalid SFTP source!", self.className, self];

  if (self.isDirectory)
    [OFException raise:@"InvalidHandleError" format:@"<%@:%p> is directory! Can read from files only!", self.className, self];

  size_t bytesToWrite = (data.itemSize * data.count);
  size_t rc = 0;
  const char* ptr = (const char *)data.items;

  do {

      rc = [self.source _writeToHandle:self.handle fromBuffer:ptr length:512];

      bytesToWrite -= rc;
      ptr += rc;

    } while (bytesToWrite > 0);

  [self.source _fsyncHandle:self.handle];

  @autoreleasepool {
    [self _fillProperties];
  }
}

- (void)append:(OFDataArray * _Nonnull)data
{
  if (!self.isOpened || self.handle == NULL)
    [OFException raise:@"AlreadyClosedError" format:@"<%@:%p> already closed!", self.className, self];

  if (self.source == nil)
    [OFException raise:@"InvalidSourceError" format:@"<%@:%p> has invalid SFTP source!", self.className, self];

  [self.source _seekHandle:self.handle toOffset:0 whence:SEEK_END];

  [self write:data];
}

- (void)moveTo:(OFString * _Nonnull)path
{
  if (self.source == nil)
    [OFException raise:@"InvalidSourceError" format:@"<%@:%p> has invalid SFTP source!", self.className, self];

  if (self.path == nil)
    [OFException raise:@"EmptyPathError" format:@"<%@:%p> has empty path property!", self.className, self];

  if (self.isOpened || self.handle != NULL)
    [self close];

  [self.source moveItemAtPath:self.path toDestination:path];

  self.path = path;
  self.name = path.lastPathComponent;

  [self open];


}

- (void)copyTo:(OFString * _Nonnull)path
{
  OF_UNRECOGNIZED_SELECTOR
}

- (OFString *)description
{
  OFMutableString* description = [OFMutableString string];

  if (self.isSymlink) [description appendUTF8String:"l"];
  else if (self.isDirectory) [description appendUTF8String:"d"];
  else [description appendUTF8String:"-"];

  //User (Owner)
  if ((self.permissions & OF_SFTP_S_IRWXU) == OF_SFTP_S_IRWXU)
    [description appendUTF8String:"rwx"];
  else {
      if ((self.permissions & OF_SFTP_S_IRUSR) == OF_SFTP_S_IRUSR) [description appendUTF8String:"r"];
      else [description appendUTF8String:"-"];

      if ((self.permissions & OF_SFTP_S_IWUSR) == OF_SFTP_S_IWUSR) [description appendUTF8String:"w"];
      else [description appendUTF8String:"-"];

      if ((self.permissions * OF_SFTP_S_IXUSR) == OF_SFTP_S_IXUSR) [description appendUTF8String:"x"];
      else [description appendUTF8String:"-"];
    }

  //Group
  if ((self.permissions & OF_SFTP_S_IRWXG) == OF_SFTP_S_IRWXG)
    [description appendUTF8String:"rwx"];
  else {
      if ((self.permissions & OF_SFTP_S_IRGRP) == OF_SFTP_S_IRGRP) [description appendUTF8String:"r"];
      else [description appendUTF8String:"-"];

      if ((self.permissions & OF_SFTP_S_IWGRP) == OF_SFTP_S_IWGRP) [description appendUTF8String:"w"];
      else [description appendUTF8String:"-"];

      if ((self.permissions * OF_SFTP_S_IXGRP) == OF_SFTP_S_IXGRP) [description appendUTF8String:"x"];
      else [description appendUTF8String:"-"];
    }

  //Others
  if ((self.permissions & OF_SFTP_S_IRWXO) == OF_SFTP_S_IRWXO)
    [description appendUTF8String:"rwx"];
  else {
      if ((self.permissions & OF_SFTP_S_IROTH) == OF_SFTP_S_IROTH) [description appendUTF8String:"r"];
      else [description appendUTF8String:"-"];

      if ((self.permissions & OF_SFTP_S_IWOTH) == OF_SFTP_S_IWOTH) [description appendUTF8String:"w"];
      else [description appendUTF8String:"-"];

      if ((self.permissions * OF_SFTP_S_IXOTH) == OF_SFTP_S_IXOTH) [description appendUTF8String:"x"];
      else [description appendUTF8String:"-"];
    }

  [description appendFormat:@" %4ld %4ld", self.uid, self.gid];
  [description appendFormat:@" %8" @PRIu64 @"", self.size];
  [description appendFormat:@" %@", self.name];

  [description makeImmutable];

  return description;
}

@end
