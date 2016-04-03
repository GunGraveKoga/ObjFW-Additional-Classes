/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <ObjFW/OFObject.h>

@class OFArray;
@class OFDictionary;
@class OFString;


@interface OFProcessInfo : OFObject {
    OFDictionary *_environment;
    OFArray *_arguments;
    OFString *_processName;
}

+ (OFProcessInfo *)processInfo;

- (OFString *)processName;
- (void)setProcessName:(OFString *)name;

- (OFString *)processPath;

- (uint32_t)processId;

- (uint32_t)currentThreadID;

- (uint32_t)processIdentifier;

- (OFArray *)arguments;

- (OFDictionary *)environment;

- (OFString *)globallyUniqueString;

@end

@interface OFSystemInfo (Extended)
+ (uint64_t)physicalMemory;
+ (uint64_t)freePhysicalMemory;
+ (uint64_t)freeVirtualMemory;
+ (uint64_t)virtualMemory;
+ (uint32_t)memoryLoad;
+ (OFString *)operatingSystemVersionString;
+ (OFString *)hostName;
+ (OFString *)DNSHostName;
+ (OFString *)DNSHostNameFullyQualified;
+ (OFString *)DNSdomain;
@end


