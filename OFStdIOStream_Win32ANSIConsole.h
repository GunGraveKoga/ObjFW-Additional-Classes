#import <ObjFW/OFObject.h>
#import <ObjFW/OFStdIOStream.h>

#if defined(OF_WINDOWS)

#import <ObjFW/OFStdIOStream_Win32Console.h>


@interface OFStdIOStream_Win32ANSIConsole: OFStdIOStream_Win32Console
{

}


@end
#endif