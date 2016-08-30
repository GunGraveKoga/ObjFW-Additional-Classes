#import <ObjFW/OFFileManager.h>

@class OFString;

typedef enum of_filemanager_search_options_t : int of_filemanager_search_options_t; enum of_filemanager_search_options_t : int {
  OF_CASESENSITIVITY = 1 << 0,
  OF_LIMITED = 1 << 1

};

@interface OFFileManager(Search)

- (OFString *)findItem:(OFString *)item atPath:(OFString *)path options:(of_filemanager_search_options_t)options depth:(size_t)depth;

@end
