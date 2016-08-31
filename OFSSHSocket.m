#import <ObjFW/ObjFW.h>
#import "OFSSHSocket.h"
#import "OFUniversalException.h"

#include <libssh2.h>

@interface OFSSHSocket()

@end

@implementation OFSSHSocket{
  OFString* _userName;
  OFString* _password;

  LIBSSH2_SESSION* _session;
}

@synthesize userName = _userName;
@synthesize password = _password;

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

- (void)connectToHost:(OFString *)host port:(uint16_t)port
{
  if (self.userName == nil)
    [OFException raise:@"Invalid user name" format:@"User name shouldn`t be nil!"];

  if (self.password == nil)
    [OFException raise:@"Invalid password" format:@"Password shouldn`t be nil"];

  [super connectToHost:host port:port];

  _session = libssh2_session_init();

  if (_session == NULL) {
    [super close];

    [OFException raise:@"SSH connection failed" format:@"SSH session not initialized!"];
    }

  libssh2_session_set_blocking(_session, 1);

  int rc;

  if ((rc = libssh2_session_handshake(_session, _socket)) != 0) {
      libssh2_session_free(_session);
      [super close];

      [OFException raise:@"Failed ssh handshake" format:@"SSH handshake failed for %@:%zu", host, port];
    }



}

@end
