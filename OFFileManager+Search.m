#import <ObjFW/ObjFW.h>
#import "OFFileManager+Search.h"

@implementation OFFileManager(Search)

- (OFString *)findItem:(OFString *)item atPath:(OFString *)path options:(of_filemanager_search_options_t)options depth:(size_t)depth
{
  if (((item == nil) || (item.length <= 0)) || ((path == nil) || (path.length <= 0))) {
      @throw [OFInvalidArgumentException exception];

  }


  __block OFString* searchPath = nil;

  @autoreleasepool {
    OFArray<OFString*>* components = item.pathComponents;

    __block OFString* workDir = path.copy;

    __block size_t idx = 0;

    __block of_array_enumeration_block_t searchBlock;

    searchBlock = ^(id object, size_t index, bool* stop) {
      static bool founded_ = false;
      static size_t limit = 0;

      if ([workDir isEqual:path])
        limit = depth;

      OFFileManager* fm = [OFFileManager defaultManager];

      @autoreleasepool {
        OFString* tmpPath = [OFString pathWithComponents:@[workDir, object]];
        tmpPath = tmpPath.stringByStandardizingPath;
        of_log(@"limit: %zu path: %@", limit, tmpPath);

        of_comparison_result_t tailCompare = ((options & OF_CASESENSITIVITY) == OF_CASESENSITIVITY) ? [tmpPath.lastPathComponent compare:components.lastObject] : [tmpPath.lastPathComponent caseInsensitiveCompare:components.lastObject];

        if ((idx >= (components.count - 1)) && (tailCompare == OF_ORDERED_SAME)) {
          searchPath = tmpPath.copy;

          *stop = true;
          founded_ = true;

          return;

        }

        of_comparison_result_t componentCompare = ((options & OF_CASESENSITIVITY) == OF_CASESENSITIVITY) ? [tmpPath.lastPathComponent compare:components[idx]] : [tmpPath.lastPathComponent caseInsensitiveCompare:components[idx]];

        if (componentCompare == OF_ORDERED_SAME) {
          if ([fm directoryExistsAtPath:tmpPath]) {
              idx++;

              @autoreleasepool {
                [workDir autorelease];

                workDir = tmpPath.copy;

                @try {
                  [[fm contentsOfDirectoryAtPath:workDir] enumerateObjectsUsingBlock:searchBlock];

                } @catch (...) {
                  ;

                } @finally {
                  if (idx != 0) idx--;

                  [workDir autorelease];

                  workDir = tmpPath.stringByDeletingLastPathComponent;

                  [workDir retain];
                }

              }

              *stop = founded_;
              return;

          }

        }

        if ([fm directoryExistsAtPath:tmpPath] && (idx == 0)) {
            @autoreleasepool {
              if ((options & OF_LIMITED) == OF_LIMITED)
                limit--;

              [workDir autorelease];

              workDir = tmpPath.copy;

              @try {
                if (((options & OF_LIMITED) != OF_LIMITED) || (limit > 0))
                  [[fm contentsOfDirectoryAtPath:workDir] enumerateObjectsUsingBlock:searchBlock];

              } @catch (...) {
                ;
              } @finally {
                if ((options & OF_LIMITED) == OF_LIMITED)
                  limit++;

                [workDir autorelease];

                workDir = tmpPath.stringByDeletingLastPathComponent;

                [workDir retain];
              }

            }

        }

        *stop = founded_;
        return;

      }

    };

    OFString* rootPath = path;//.stringByStandardizingPath;
    of_log(@"Root path: %@", rootPath);

    if (![self directoryExistsAtPath:rootPath]) {
        of_log(@"RootPath does not exists");
      @throw [OFInvalidArgumentException exception];
      }

    [[self contentsOfDirectoryAtPath:rootPath] enumerateObjectsUsingBlock:searchBlock];

    if (workDir)
      [workDir autorelease];

  }

  return [searchPath autorelease];
}

@end
