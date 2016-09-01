#import <ObjFW/ObjFW.h>
#import "OFSSHSocket.h"
#import "OFUniversalException.h"

#include <libssh2.h>

@interface OFSSHSocket()

@property (nonatomic) LIBSSH2_SESSION* session;

- (of_ssh_auth_options_t)_hostAuthTypes;
- (OFString *)_hostKeyHash;
- (void)_authWithPasswordAtHost:(OFString *)host;
- (void)_authWitnKeyboardInteractiveAtHost:(OFString *)host;
- (void)_authWithPublicKeyAtHost:(OFString *)host;

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

  return [OFString stringWithUTF8StringNoCopy:(char *)fingerprint freeWhenDone:false];
}

- (of_ssh_auth_options_t)_hostAuthTypes
{
  of_ssh_auth_options_t result;

  char* userauthlist = NULL;

  if ((userauthlist = libssh2_userauth_list(self.session, self.userName.UTF8String, self.userName.UTF8StringLength)) == NULL) {
      char* messageBuffer;
      int messageLen = 0;

      OFString* errorDescription = nil;

      libssh2_session_last_error(self.session, &messageBuffer, &messageLen, 1);

      if (messageLen > 0) {
          errorDescription = [OFString stringWithUTF8StringNoCopy:messageBuffer freeWhenDone:true];
        }

      [OFException raise:@"Empty user auth list" format:@"%@ recive empty user auth list (%@)", self, errorDescription];
    }

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

@end
