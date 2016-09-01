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

@end

@implementation OFSSHSocket{
  OFString* _userName;
  OFString* _password;
  OFString* _publicKey;
  OFString* _privateKey;
  of_ssh_auth_options_t _authOptions;
  of_ssh_host_hash_t _hostHashType;
  id<OFSSHSocketDelegate> _delegate;

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

  libssh2_session_set_blocking(_session, 0);

  int rc;

  while ((rc = libssh2_session_handshake(self.session, self->_socket)) == kEAgain);

  if (rc != kSuccess) {

      char* messageBuffer;
      int messageLen = 0;

      OFString* errorDescription = nil;

      libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

      if (messageLen > 0) {
          errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
        }

      libssh2_session_free(self.session);
      [super close];

      [OFException raise:@"Failed ssh handshake" format:@"SSH handshake failed for %@:%zu! (Error: %d - %@)", host, port, rc, errorDescription];
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

              @throw exception;
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

      char* messageBuffer;
      int messageLen = 0;

      OFString* errorDescription = nil;

      libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

      if (messageLen > 0) {
          errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
        }

      [OFException raise:@"Invalid host key hash" format:@"Cannot recive host key hash! (%@)", errorDescription];
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

  while (((userauthlist = libssh2_userauth_list(self.session, self.userName.UTF8String, self.userName.UTF8StringLength)) == NULL) && ((rc = libssh2_session_last_errno(self.session)) == kEAgain));

  if ((userauthlist == NULL) || rc != kSuccess)
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

  while ((rc = libssh2_userauth_password(self.session, self.userName.UTF8String, self.password.UTF8String)) == kEAgain);

  if (rc != kSuccess) {
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
                                                       self.password.UTF8String)) == kEAgain);

    if (rc != kSuccess) {
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

@end


@interface OFSFTPSocket()

@property (nonatomic) LIBSSH2_SFTP* sftpSession;
@property (nonatomic) LIBSSH2_SFTP_HANDLE* sftpHandle;
@property (nonatomic) BOOL isFileHandle;
@property (nonatomic, assign) OFDataArray* buffer;

@end


@implementation OFSFTPSocket{
  LIBSSH2_SFTP* _sftpSession;
  LIBSSH2_SFTP_HANDLE* _sftpHandle;
  BOOL _isFileHandle;
  OFDataArray* _buffer;
}

@synthesize sftpSession = _sftpSession;
@synthesize sftpHandle = _sftpHandle;
@synthesize isFileHandle = _isFileHandle;

- (instancetype)init
{
  self = [super init];

  self.sftpHandle = NULL;
  self.sftpHandle = NULL;
  self.isFileHandle = NO;
  self.buffer = nil;

  return self;
}

- (void)dealloc
{

  [self close];

  [super dealloc];
}

- (void)close
{
  if (self.sftpHandle != NULL) {
      libssh2_sftp_close_handle(self.sftpHandle);
      self.sftpHandle = NULL;
    }

  if (self.sftpSession != NULL) {
      libssh2_sftp_shutdown(self.sftpSession);
      self.sftpSession = NULL;
    }

  [_buffer release];

  [super close];
}

- (void)connectToHost:(OFString *)host port:(uint16_t)port
{
  [super connectToHost:host port:port];

  int rc = 0;

  do {

      self.sftpSession = libssh2_sftp_init(self.session);

      if ((self.sftpSession == NULL) && ((rc = libssh2_session_last_errno(self.session)) != kEAgain)) {
          char* messageBuffer;
          int messageLen = 0;

          OFString* errorDescription = nil;

          libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

          if (messageLen > 0) {
              errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
            }

          libssh2_session_free(self.session);
          self.session = NULL;
          [super close];

          [OFException raise:@"SFTP initialization failed" format:@"Unable to init SFTP session!\n%@:%zu: %@", host, port, errorDescription];
        }

      [self _waitSocket];

    } while (self.sftpSession == NULL);

}

- (void)lowlevelWriteBuffer:(const void *)buffer length:(size_t)length
{
  if ((self.sftpHandle == NULL) && (!self.isFileHandle)) {
      [OFException raise:@"SFTP WriteFailed" format:@"Cannot write %zu bytes to %@ SFTP handle!", length, (self.sftpHandle == NULL) ? @"closed" : ((!self.isFileHandle) ? @"directory" : @"")];
    }

  size_t bytesToWrite = 0;
  const char* ptr = NULL;
  int rc = 0;

  if (self.buffer != nil) {
      if (self.buffer.count <= 0) {
          [self.buffer release];
          self.buffer = nil;

        } else {

          [self.buffer addItems:buffer count:length];

          bytesToWrite = self.buffer.count;
          ptr = (const char *)self.buffer.items;

          do {
              rc = libssh2_sftp_write(self.sftpHandle, ptr, bytesToWrite);

              if (rc == kEAgain)
                [self _waitSocket];
              else if (rc == 0)
                break;
              else if (rc > 0) {
                  ptr += rc;
                  bytesToWrite -= rc;

                } else {
                  char* messageBuffer;
                  int messageLen = 0;

                  OFString* errorDescription = nil;

                  libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

                  if (messageLen > 0) {
                      errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
                    }

                  [OFException raise:@"SFTP WriteFailed" format:@"Cannot write %zu bytes to %@ (%@)", bytesToWrite, self, errorDescription];

                }

            } while (true);


          if (bytesToWrite == 0) {
              [self.buffer release];
              self.buffer = nil;

              return;

            } else {
              size_t bytesToRemove = self.buffer.count - bytesToWrite;

              [self.buffer removeItemsInRange:of_range(0, bytesToRemove)];

              return;
            }

        }
    }

  bytesToWrite = length;
  ptr = (const char *)buffer;

  do {
      rc = libssh2_sftp_write(self.sftpHandle, ptr, bytesToWrite);

      if (rc == kEAgain)
        [self _waitSocket];
      else if (rc == 0)
        break;
      else if (rc > 0) {
          ptr += rc;
          bytesToWrite -= rc;

        } else {
          char* messageBuffer;
          int messageLen = 0;

          OFString* errorDescription = nil;

          libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

          if (messageLen > 0) {
              errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
            }

          [OFException raise:@"SFTP WriteFailed" format:@"Cannot write %zu bytes to %@ (%@)", bytesToWrite, self, errorDescription];

        }

    } while (true);


  if (bytesToWrite > 0) {
      self.buffer = [[OFDataArray alloc] initWithItemSize:sizeof(unsigned char) capacity:bytesToWrite];

      [self.buffer addItems:(((unsigned char *)buffer) + (length - bytesToWrite)) count:bytesToWrite];
    }
}

- (size_t)lowlevelReadIntoBuffer:(void *)buffer length:(size_t)length
{
  if ((self.sftpHandle == NULL) && (!self.isFileHandle)) {
      [OFException raise:@"SFTP ReadFailed" format:@"Cannot read %zu bytes from %@ SFTP handle!", length, (self.sftpHandle == NULL) ? @"closed" : ((!self.isFileHandle) ? @"directory" : @"")];
    }

  int rc = 0;
  size_t res = 0;

  do {
      rc = libssh2_sftp_read(self.sftpHandle, (char *)buffer, length);

      if (rc == kEAgain)
        [self _waitSocket];
      else if (rc >= 0)
        break;
      else {
          char* messageBuffer;
          int messageLen = 0;

          OFString* errorDescription = nil;

          libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

          if (messageLen > 0) {
              errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
            }

          [OFException raise:@"SFTP ReadFailed" format:@"Cannot read %zu bytes to %@ (%@)", length, self, errorDescription];
        }

    } while (true);
  of_log(@"lowlevel reading complite (%d)", rc);
  res += rc;
  while (true) {
      OFDataArray* dt = [OFDataArray dataArrayWithCapacity:rc];
      [dt addItems:buffer count:rc];
      of_log(@"%@", dt.stringRepresentation);
      OFString* str = [OFString stringWithUTF16String:buffer];
      of_log(@"str %@", str);
      break;
    }

  return res;
}

- (void)openDirectory:(OFString *)path
{
  if (self.sftpHandle != NULL) {
      libssh2_sftp_close_handle(self.sftpHandle);

      self.sftpHandle = NULL;
    }
  self.isFileHandle = NO;

  int rc = 0;

  do {
      self.sftpHandle = libssh2_sftp_opendir(self.sftpSession, path.UTF8String);

      if ((self.sftpHandle == NULL) && ((rc = libssh2_session_last_errno(self.session)) != kEAgain)) {
          char* messageBuffer;
          int messageLen = 0;

          OFString* errorDescription = nil;

          libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

          if (messageLen > 0) {
              errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
            }

          [OFException raise:@"Directory Open" format:@"Cannot open directory at path %@ (%@)", path, errorDescription];

        }

      [self _waitSocket];

    } while (self.sftpHandle == NULL);

}

- (void)openFile:(OFString *)file mode:(of_sftp_file_mode_t)mode rights:(int)rights
{
  if (self.sftpHandle != NULL) {
      if (self.buffer != nil) {
          [self lowlevelWriteBuffer:"" length:0];

        }

      libssh2_sftp_close_handle(self.sftpHandle);

      self.sftpHandle = NULL;
    }

  self.isFileHandle = YES;

  int rc = 0;

  do {

      self.sftpHandle = libssh2_sftp_open(self.sftpSession, file.UTF8String, mode, rights);

      if ((self.sftpHandle == NULL) && ((rc = libssh2_session_last_errno(self.session)) != kEAgain)) {
          char* messageBuffer;
          int messageLen = 0;

          OFString* errorDescription = nil;

          libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

          if (messageLen > 0) {
              errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
            }

          [OFException raise:@"File Open" format:@"Cannot open file %@ (%@)", file, errorDescription];
        }

      [self _waitSocket];

    } while(self.sftpHandle == NULL);

}

- (void)createDirectoryAtPath:(OFString *)path rights:(int)rights
{
  int rc = 0;

  while ((rc = libssh2_sftp_mkdir_ex(self.sftpSession, path.UTF8String, path.UTF8StringLength, rights)) == kEAgain)
    [self _waitSocket];

  if (rc != kSuccess) {
      char* messageBuffer;
      int messageLen = 0;

      OFString* errorDescription = nil;

      libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

      if (messageLen > 0) {
          errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
        }

      [OFException raise:@"Directory creation failed" format:@"Cannot create directory at path %@ (%@)", path, errorDescription];
    }
}

- (OFArray<OFString*> *)contentOfDirectoryAtPath:(OFString *)path
{
  [self openDirectory:path];

  OFMutableArray<OFString*>* content = [OFMutableArray array];

  char buffer[4096];
  //char longentry[512];
  LIBSSH2_SFTP_ATTRIBUTES attrs;
  int rc = 0;

  @autoreleasepool {
    do {
        memset(buffer, 0, sizeof(buffer));
        //memset(longentry, 0, sizeof(longentry));

        while ((rc = libssh2_sftp_readdir(self.sftpHandle, buffer, sizeof(buffer), &attrs)) == kEAgain)
          [self _waitSocket];

        if (rc > 0) {

            OFString* element = [OFString stringWithUTF8String:buffer length:rc];

            if ([element isEqual:@"."] || [element isEqual:@".."])
              continue;

            [content addObject:element];

          } else if (rc == kSuccess) {
            break;

          } else if (rc != kEAgain) {

            char* messageBuffer;
            int messageLen = 0;

            OFString* errorDescription = nil;

            libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

            if (messageLen > 0) {
                errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
              }

            [OFException raise:@"Directory listing failed" format:@"Cannot list directory at path %@ (%@)", path, errorDescription];
          }

      } while (true);

  }

  [content makeImmutable];

  return content;
}

@end;
