/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */
#import <ObjFW/ObjFW.h>
#import "OFProcessInfo.h"
#include <math.h>

#if defined(OF_WINDOWS)
  #include <windows.h>
  #ifndef MAXPATHLEN
    #define MAXPATHLEN 8192
  #endif
  #define MAXHOSTNAMELEN 512
#elif defined(OF_MACH_O) || defined(OF_LINUX)
  #include <pthread.h>
#endif

#if defined(OF_LINUX)
#include <sys/param.h>
extern char * program_invocation_name;
#endif


static OFProcessInfo* __procInfo = nil;
static OFDate* __processTimestamp = nil;

@implementation OFProcessInfo

static int OFProcessInfoArgc=0;
#if defined(OF_WINDOWS)
static LPWSTR *OFProcessInfoArgv = NULL;
#else
static const char** OFProcessInfoArgv = NULL;
#endif

OFString* __GetExecutablePath() {
#if defined (OF_WINDOWS)
  static size_t bufferCapacity = MAXPATHLEN;
  of_char16_t buffer[bufferCapacity + 1];
  DWORD bufferSize = GetModuleFileNameW(GetModuleHandle(NULL), buffer, bufferCapacity);

  OFString* fullPath = nil;
  OFAutoreleasePool* pool = [OFAutoreleasePool new];
  fullPath = [OFString stringWithUTF16String:&(buffer[0]) length:(size_t)bufferSize];
  fullPath = [fullPath stringByStandardizingPath];
  
  [fullPath retain];
  [pool drain];

  
  return [fullPath autorelease];
#elif defined(OF_LINUX)
  char result[MAXPATHLEN];
  size_t count = readlink( "/proc/self/exe", result, MAXPATHLEN );

  OFString* fullPath = nil;
  OFAutoreleasePool* pool = [OFAutoreleasePool new];

  if (count > 0 && !(count > MAXPATHLEN)) {
    
    fullPath = [OFString stringWithUTF8String:result length:count];
    fullPath = [fullPath stringByStandardizingPath];

  } else {
    memset(result, 0, MAXPATHLEN);

    if (realpath(program_invocation_name, result) == 0) {
      fullPath = [OFString stringWithUTF8String:program_invocation_name length:strlen(program_invocation_name)];
      fullPath = [fullPath stringByStandardizingPath];
    } else {
      fullPath = [OFString stringWithUTF8String:result length:strlen(count)];
      fullPath = [fullPath stringByStandardizingPath];
    }
  }

  [fullPath retain];
  [pool drain];

  return [fullPath autorelease];

#elif defined(OF_MACH_O)

  char result[MAXPATHLEN];
  size_t size = MAXPATHLEN;

  OFString* fullPath = nil;
  OFAutoreleasePool* pool = [OFAutoreleasePool new];

  if (_NSGetExecutablePath(result, &size) == 0) {
    fullPath = [OFString stringWithUTF8String:result length:size];
    fullPath = [fullPath stringByStandardizingPath];
  } else {
    char *buf = (char*)__builtin_alloca(size);
    fullPath = [OFString stringWithUTF8String:buf length:size];
    fullPath = [fullPath stringByStandardizingPath];
  }

  [fullPath retain];
  [pool drain];

  return [fullPath autorelease];
#else
  #error Unsuported system
#endif
}

uint32_t __processID() {
#if defined(OF_WINDOWS)
  return (uint32_t)GetCurrentProcessId();
#elif defined(OF_LINUX) || defined(OF_MACH_O)
  return (uint32_t)getpid();
#endif

  return 0;
}

uint32_t __threadID() {
#if defined(OF_WINDOWS)
  return (uint32_t)GetCurrentThreadId();
#elif defined(OF_LINUX)
  return (uint32_t)pthread_getthreadid_np();
#elif defined(OF_MACH_O)
  return (uint32_t)pthread_mach_thread_np(pthread_self());;
#endif

  return 0;
}

#if defined(OF_WINDOWS)
void __initWin32Process() {
  OFAutoreleasePool* pool = [OFAutoreleasePool new];
  OFString   *entry;
  const char *module="";   //TODO: need to implementation.
  HKEY        handle;
  DWORD       disposition,allowed;
  int         i;

  OFString* applicationName = __GetExecutablePath();
  applicationName = [applicationName lastPathComponent];
  applicationName = [applicationName stringByDeletingPathExtension];

  entry=[@"SYSTEM\\CurrentControlSet\\Services\\Eventlog\\Application\\" stringByAppendingString:applicationName];

  if(RegCreateKeyExW(HKEY_LOCAL_MACHINE,[entry UTF16String],0,NULL, REG_OPTION_NON_VOLATILE,KEY_ALL_ACCESS,NULL,&handle,&disposition))
    of_log(@"Error RegCreateKeyExW");

  if(RegSetValueEx(handle,"EventMessageFile",0,REG_EXPAND_SZ, (LPBYTE)module,strlen(module)+1))
    of_log(@"Error RegSetValueEx");

  allowed=EVENTLOG_ERROR_TYPE|EVENTLOG_WARNING_TYPE|EVENTLOG_INFORMATION_TYPE;

  if(RegSetValueEx(handle,"TypesSupported",0,REG_DWORD, (LPBYTE)&allowed,sizeof(DWORD)))
    of_log(@"Error RegSetValueEx");

  RegCloseKey(handle);

  for(i=1;i<__argc;i++)
   if(strcmp(__argv[i],"-Console")==0){
   // we could check for presence of AttachConsole and use that instead
    AllocConsole();
   }
  [pool release];
}

#endif


+ (void)initialize
{
  if (!of_socket_init())
    @throw [OFInitializationFailedException exceptionWithClass:[self class]];

  if (__procInfo == nil)
    __procInfo = [[OFProcessInfo alloc] init];

}

+ (OFProcessInfo *)processInfo {
  return __procInfo;
}

-init {
  if (__procInfo != nil)
    @throw [OFInitializationFailedException exceptionWithClass:[self class]];


   _environment=nil;
   _arguments =nil;
   _processName=nil;
   __processTimestamp = [OFDate new];

   return self;
}

- (OFString *)processName {
   if(_processName==nil){
    OFAutoreleasePool* pool = [OFAutoreleasePool new];

    _processName = [[__GetExecutablePath() lastPathComponent] stringByDeletingPathExtension];

    [_processName retain];
    [pool drain];

   }

   return [[_processName retain] autorelease];
}

-(void)setProcessName:(OFString *)name {
   [_processName release];
   _processName=[name copy];
}

- (OFString *)processPath
{
  OFAutoreleasePool* pool = [OFAutoreleasePool new];

  OFString* path = [__GetExecutablePath() stringByDeletingLastPathComponent];
  path = [path stringByStandardizingPath];

  [path retain];
  [pool drain];

  return [path autorelease];
}

- (uint32_t)processId
{
  return __processID();
}

- (uint32_t)currentThreadID
{
  return __threadID();
}

- (uint32_t)processIdentifier {
   return __processID();
}

- (OFArray *)arguments {
  if (_arguments == nil) {
      OFMutableArray* argv = [OFMutableArray new];

  #if defined(OF_WINDOWS)
      LPWSTR cmd = GetCommandLineW();
      OFProcessInfoArgv = CommandLineToArgvW(cmd, &OFProcessInfoArgc);


      OFAutoreleasePool* pool = [OFAutoreleasePool new];

      if (OFProcessInfoArgv) {
          for (size_t idx = 0; idx < OFProcessInfoArgc; ++idx) {
              [argv addObject:[OFString stringWithUTF16String:(const of_char16_t *)OFProcessInfoArgv[idx] length:wcslen(OFProcessInfoArgv[idx])]];
            }
        }
      [pool drain];

  #elif defined(OF_MACH_O)
      int *argc_ = _NSGetArgc();
      OFProcessInfoArgc = *argc_;

      char*** argv_ = _NSGetArgv();
      OFProcessInfoArgv = *argv_;

      OFAutoreleasePool* pool = [OFAutoreleasePool new];

      if (OFProcessInfoArgv) {
        for (size_t idx = 0; idx < OFProcessInfoArgc; ++idx) {
          [argv addObject:[OFString stringWithUTF8String:OFProcessInfoArgv[idx] length:strlen(OFProcessInfoArgv[idx])]];
        }
      }
      [pool drain];

  #endif

      [argv makeImmutable];

      _arguments = argv;
    }

  return [_arguments copy];
}

- (OFDictionary *)environment {

  if (_environment == nil) {
      OFMutableDictionary* environment = [OFMutableDictionary new];

    #if defined(OF_WINDOWS)
      of_char16_t* envString = GetEnvironmentStringsW();

      OFAutoreleasePool* pool = [OFAutoreleasePool new];

      of_char16_t* string = envString;

      while (wcslen(string) != 0) {
          OFArray* record = [[OFString stringWithUTF16String:string] componentsSeparatedByString:@"="];
          [environment setObject:[record objectAtIndex:1] forKey:[record objectAtIndex:0]];

          string += wcslen(string)+1;
        }
      [pool drain];
      string = NULL;
      FreeEnvironmentStringsW(envString);
    #endif

      [environment makeImmutable];

      _environment = environment;
    }


  return [_environment copy];
}

- (OFString *)globallyUniqueString {
  static OFString* globallyUniqueString = nil;
  if (globallyUniqueString == nil) {
      globallyUniqueString = [OFString stringWithFormat:@"%@_%d_%d_%d_%d", [OFSystemInfo hostName], [self processIdentifier], 0, 0, floor([__processTimestamp timeIntervalSince1970])];
    }

  return [[globallyUniqueString retain] autorelease];
}

@end

@implementation  OFSystemInfo (Extended)
+ (uint64_t)physicalMemory
{
#if defined (OF_WINDOWS)
  MEMORYSTATUSEX memStatus;
  memStatus.dwLength = sizeof(MEMORYSTATUSEX);

  GlobalMemoryStatusEx(&memStatus);

  return (uint64_t)memStatus.ullTotalPhys;
#endif
   return 0;
}

+ (uint64_t)freePhysicalMemory
{
#if defined (OF_WINDOWS)
  MEMORYSTATUSEX memStatus;
  memStatus.dwLength = sizeof(MEMORYSTATUSEX);

  GlobalMemoryStatusEx(&memStatus);

  return (uint64_t)memStatus.ullAvailPhys;
#endif
   return 0;
}

+ (uint64_t)freeVirtualMemory
{
#if defined (OF_WINDOWS)
  MEMORYSTATUSEX memStatus;
  memStatus.dwLength = sizeof(MEMORYSTATUSEX);

  GlobalMemoryStatusEx(&memStatus);

  return (uint64_t)memStatus.ullAvailVirtual;
#endif
   return 0;
}

+ (uint64_t)virtualMemory
{
#if defined (OF_WINDOWS)
  MEMORYSTATUSEX memStatus;
  memStatus.dwLength = sizeof(MEMORYSTATUSEX);

  GlobalMemoryStatusEx(&memStatus);

  return (uint64_t)memStatus.ullTotalVirtual;
#endif
   return 0;
}

+ (uint32_t)memoryLoad
{
#if defined (OF_WINDOWS)
  MEMORYSTATUSEX memStatus;
  memStatus.dwLength = sizeof(MEMORYSTATUSEX);

  GlobalMemoryStatusEx(&memStatus);

  return (uint32_t)memStatus.dwMemoryLoad;
#endif
   return 0;
}

+ (OFString *)operatingSystemVersionString {
#if defined(OF_WINDOWS)
	OSVERSIONINFOEXW osVersion;
	SYSTEM_INFO sysInfo;
	OFString* servicePack;

	osVersion.dwOSVersionInfoSize=sizeof(OSVERSIONINFOEXW);
	GetVersionExW((OSVERSIONINFOW *)&osVersion);
	GetSystemInfo(&sysInfo);

	OFAutoreleasePool* pool = [OFAutoreleasePool new];

  OFMutableString* fullSystemName = [OFMutableString stringWithUTF8String:"Windows"];

	if (osVersion.dwMajorVersion == 10) {
	    if (osVersion.wProductType == VER_NT_WORKSTATION) {
		switch (osVersion.dwMinorVersion) {
		  case 0:
		    [fullSystemName appendString:@" 10"];
		    break;
		   default:
		    [fullSystemName appendString:@" NT"];
		    break;
		  }
	      } else if (osVersion.wProductType != VER_NT_WORKSTATION) {
		switch (osVersion.dwMinorVersion) {
		  case 0:
		    [fullSystemName appendString:@" Server 2016"];
		    break;
		   default:
		    [fullSystemName appendString:@" NT"];
		    break;
		  }
	      }

	  } else if (osVersion.dwMajorVersion == 6) {
	    if (osVersion.wProductType == VER_NT_WORKSTATION) {
		switch (osVersion.dwMinorVersion) {
		  case 3:
		    [fullSystemName appendString:@" 8.1"];
		    break;
		  case 2:
		    [fullSystemName appendString:@" 8"];
		    break;
		  case 1:
		    [fullSystemName appendString:@" 7"];
		    break;
		  case 0:
		    [fullSystemName appendString:@" Vista"];
		    break;
		  default:
		    [fullSystemName appendString:@" NT"];
		    break;
		  }
	      } else if (osVersion.wProductType != VER_NT_WORKSTATION) {
		switch (osVersion.dwMinorVersion) {
		  case 3:
		    [fullSystemName appendString:@" Server 2012 R2"];
		    break;
		  case 2:
		    [fullSystemName appendString:@" Server 2012"];
		    break;
		  case 1:
		    [fullSystemName appendString:@" Server 2008 R2"];
		    break;
		  case 0:
		    [fullSystemName appendString:@" Server 2008"];
		    break;
		  default:
		    [fullSystemName appendString:@" NT"];
		    break;
		  }
	      }

	  } else if (osVersion.dwMajorVersion == 5) {
	    switch (osVersion.dwMinorVersion) {
	      case 2:
		if (GetSystemMetrics(SM_SERVERR2) != 0)
		  [fullSystemName appendString:@" Server 203 R2"];
		else if (osVersion.wSuiteMask & VER_SUITE_WH_SERVER)
		  [fullSystemName appendString:@" Home Server"];
		else if (GetSystemMetrics(SM_SERVERR2) == 0)
		  [fullSystemName appendString:@" Server 2003"];
		else if ((osVersion.wProductType == VER_NT_WORKSTATION) && (sysInfo.wProcessorArchitecture==PROCESSOR_ARCHITECTURE_AMD64))
		  [fullSystemName appendString:@" XP Professional x64 Edition"];
		else
		  [fullSystemName appendString:@" NT"];

		break;
	      case 1:
		[fullSystemName appendString:@" XP"];
		if (GetSystemMetrics(SM_MEDIACENTER) != 0)
		  [fullSystemName appendString:@" Media Center Edition"];
		else if (GetSystemMetrics(SM_STARTER) != 0)
		  [fullSystemName appendString:@" Starter Edition"];
		else if (GetSystemMetrics(SM_TABLETPC) != 0)
		  [fullSystemName appendString:@" Tablet PC Edition"];

		break;
	      case 0:
		[fullSystemName appendString:@" 2000"];
		break;
	      default:
		[fullSystemName appendString:@" NT"];
		break;
	      }

	  } else {
	    [fullSystemName appendString:@" NT"];
	  }

	servicePack = [OFString stringWithUTF16String:(const of_char16_t *)osVersion.szCSDVersion];

	if ([servicePack length] > 0)
	  [fullSystemName appendFormat:@" %@", servicePack];

  [fullSystemName retain];
	[pool release];

	[fullSystemName makeImmutable];

	return [fullSystemName autorelease];
#else
    OF_UNRECOGNIZED_SELECTOR
#endif
}

+ (OFString *)hostName {
#if defined(OF_WINDOWS)
  DWORD length = MAX_COMPUTERNAME_LENGTH;
  of_char16_t name[length +1];

  if (!GetComputerNameExW(ComputerNameNetBIOS, (LPWSTR)name, &length)) {
      return [OFString stringWithUTF8String:"LOCALHOST"];
    }

  return [OFString stringWithUTF16String:name length:length];
#endif
}

+ (OFString *)DNSHostName
{
#if defined(OF_WINDOWS)
  DWORD length = MAXHOSTNAMELEN;
  of_char16_t name[length +1];

  if (!GetComputerNameExW(ComputerNameDnsHostname, (LPWSTR)name, &length)) {
      return [OFString stringWithUTF8String:"localhost"];
    }

  return [OFString stringWithUTF16String:name length:length];
#endif
}

+ (OFString *)DNSHostNameFullyQualified
{
#if defined(OF_WINDOWS)
  DWORD length = MAXHOSTNAMELEN;
  of_char16_t name[length +1];

  if (!GetComputerNameExW(ComputerNameDnsFullyQualified, (LPWSTR)name, &length)) {
      return [OFString stringWithUTF8String:"localhost.localdomain"];
    }

  return [OFString stringWithUTF16String:name length:length];
#endif
}

+ (OFString *)DNSdomain
{
#if defined(OF_WINDOWS)
  DWORD length = MAXHOSTNAMELEN;
  of_char16_t name[length +1];

  if (!GetComputerNameExW(ComputerNameDnsDomain, (LPWSTR)name, &length)) {
      return [OFString stringWithUTF8String:"localdomain"];
    }

  OFString* domain = [[OFString alloc] initWithUTF16String:name length:length];

  if ([domain length] <= 0) {
      [domain release];
      return @"(nil)";
    }

  return [domain autorelease];
#endif
}
@end

