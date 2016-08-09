#import <ObjFW/ObjFW.h>
#import "OFDataArray+Search.h"

@implementation OFDataArray(Search)

- (size_t)getItems:(const void *)buffer inRange:(of_range_t)range
{
	if (range.length <= 0)
		@throw [OFInvalidArgumentException exception];

	if (range.location >= self.count)
		@throw [OFOutOfRangeException exception];

	size_t lengt = ((range.location + range.length) > self.count) ? self.count : range.length;

	if (buffer == NULL)
		return lengt * self.itemSize;

	void* p = self.items;

	memcpy((void *)buffer, (p + (range.location * self.itemSize)), (lengt * self.itemSize));

	return lengt * self.itemSize;
}

- (of_range_t)rangeOfData:(OFDataArray *)data
{
	return [self rangeOfData:data options:0];
}

- (of_range_t)rangeOfData:(OFDataArray *)data options:(int)options
{
	of_range_t range = of_range(0, self.count);

	return [self rangeOfData:data options:options range:range];
}

- (of_range_t)rangeOfData:(OFDataArray *)data options:(int)options range:(of_range_t)range
{
	of_range_t result = of_range(OF_NOT_FOUND, 0);


	if ((data == nil) || (self.itemSize != data.itemSize))
		@throw [OFInvalidArgumentException exception];

	if (data.count == 0)
		return of_range(0, 0);

	if ((range.length == 0) || (data.count > range.length))
		return result;

	if ((range.location >= self.count) || ((range.location + range.length) > self.count))
		@throw [OFOutOfRangeException exception];

	size_t idx = 0;
	size_t end = 0;
	
	void* item = NULL;

	bool reverse = ((options & OF_DATA_SEARCH_BACKWARDS) == OF_DATA_SEARCH_BACKWARDS);
	bool anchored = ((options & OF_DATA_SEARCH_ANCHORED) == OF_DATA_SEARCH_ANCHORED);

	if (anchored) {

		if (reverse) {

			idx = ((range.location + range.length) - data.count);

			if ((memcmp([self itemAtIndex:idx], data.firstItem, data.itemSize)) == 0) {

				if ((memcmp((self.items + (idx * self.itemSize)), data.items, (data.count * data.itemSize))) == 0) {
					result = of_range(idx, data.count);
				}
			}

		} else {

			idx = range.location;

			if ((memcmp([self itemAtIndex:idx], data.firstItem, data.itemSize)) == 0) {
				if ((memcmp(self.items + (idx * self.itemSize), data.items, (data.count * data.itemSize))) == 0) {
					result = of_range(idx, data.count);
				}
			}

		}

	} else {

		if (reverse) {

			idx = ((range.location + range.length) - data.count);
			end = range.location;

			do {

				item = [self itemAtIndex:idx];

				if ((memcmp(item, data.firstItem, data.itemSize)) == 0) {
					if ((memcmp(self.items + (idx * self.itemSize), data.items, (data.count * data.itemSize))) == 0) {
						result = of_range(idx, data.count);

						break;
					}
				}

				if (idx == end)
					break;

				idx--;

			} while (idx >= end);

		} else {

			idx = range.location;
			end = (range.location + range.length);
		

			while (idx != end) {

				item = [self itemAtIndex:idx];
			

				if ((memcmp(item, data.firstItem, data.itemSize)) != 0) {
					idx++;
					continue;
				}

				if (data.count <= (end - idx)) {
					if ((memcmp((self.items + (idx * self.itemSize)), data.items, (data.itemSize * data.count))) == 0) {
						result = of_range(idx, data.count);

						break;
					}

					idx++;

					continue;
				}

				break;

			}
		}

	}


	return result;

}

- (OFDataArray *)subDataWithRange:(of_range_t)range
{
	if ((range.location > self.count) || 
		((range.location + range.length) > self.count))
		@throw [OFOutOfRangeException exception];

	OFDataArray* result = [OFDataArray dataArrayWithItemSize:self.itemSize capacity:range.length];

	void* p = (self.items + (range.location * self.itemSize));

	[result addItems:p count:range.length];

	return result;
}

- (OFArray *)componentsSeparatedByData:(OFDataArray *)aSeparator
{
	if (aSeparator == nil || aSeparator.count == 0)
		@throw [OFInvalidArgumentException exception];

	OFMutableArray* result = [OFMutableArray array];

	void* pool = objc_autoreleasePoolPush();

	of_range_t found;
	of_range_t searchRange = of_range(0, self.count);
	size_t idx = 0;
	
	while ((found = [self rangeOfData:aSeparator options:0 range:searchRange]).location != OF_NOT_FOUND) {
		
		of_range_t subDataRange = of_range(searchRange.location, (found.location - searchRange.location));
		
		OFDataArray* component = [self subDataWithRange:subDataRange];

		[result addObject:component];

		idx = (found.location + found.length);

		searchRange = of_range(idx, self.count - idx);

	}

	if (self.count - idx >= 1) {

		OFDataArray* lastComponent = [self subDataWithRange:of_range(idx, self.count - idx)];

		[result addObject:lastComponent];
	}

	objc_autoreleasePoolPop(pool);

	[result makeImmutable];

	return result;
}

@end