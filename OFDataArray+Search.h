#import <ObjFW/OFDataArray.h>

@class OFArray;

enum {
    OF_DATA_SEARCH_BACKWARDS = 1,
    OF_DATA_SEARCH_ANCHORED  = 2
};

@interface OFDataArray (Search)

- (size_t)getItems:(const void *)buffer inRange:(of_range_t)range;
- (of_range_t)rangeOfData:(OFDataArray *)data options:(int)options range:(of_range_t)range;
- (of_range_t)rangeOfData:(OFDataArray *)data options:(int)options;
- (of_range_t)rangeOfData:(OFDataArray *)data;
- (OFDataArray *)subDataWithRange:(of_range_t)range;
- (OFArray *)componentsSeparatedByData:(OFDataArray *)aSeparator;

@end