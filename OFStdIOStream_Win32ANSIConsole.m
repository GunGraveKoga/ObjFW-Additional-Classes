#import <ObjFW/ObjFW.h>

#if defined(OF_WINDOWS)

#import "OFStdIOStream_Win32ANSIConsole.h"

#ifndef FOREGROUND_MASK
# define FOREGROUND_MASK (FOREGROUND_RED|FOREGROUND_BLUE|FOREGROUND_GREEN|FOREGROUND_INTENSITY)
#endif
#ifndef BACKGROUND_MASK
# define BACKGROUND_MASK (BACKGROUND_RED|BACKGROUND_BLUE|BACKGROUND_GREEN|BACKGROUND_INTENSITY)
#endif

static IMP original_imp = NULL;

static WORD attributes_old[2] = {-1, -1};

static void _w32_ansi_write(OFStream* stream_, HANDLE handle_, const void* buffer_, size_t length_) {

	if (![stream_ isKindOfClass:[OFStdIOStream_Win32Console class]] || handle_ == INVALID_HANDLE_VALUE)
		@throw [OFInvalidArgumentException exception];


	DWORD cm;

	if (!GetConsoleMode(handle_, &cm)) {
		[stream_ writeBuffer:buffer_ length:length_];

		return;
	}

	OFStdIOStream_Win32Console* stream = (OFStdIOStream_Win32Console *)stream_;
	int type = 0;

	if (stream == of_stderr)
		type = 1;


	id exception = nil;

	void* pool = objc_autoreleasePoolPush();

	@try {

		OFString* output = [OFString stringWithUTF8StringNoCopy:(char *)buffer_ freeWhenDone:false];
	
		size_t idx = 0;
		of_range_t escape_range = of_range(idx, length_);
		of_unichar_t ch;
	
		static WORD attribute_old;
	
		WORD attr;
	  	DWORD written, csize;
	  	CONSOLE_CURSOR_INFO cci;
	  	CONSOLE_SCREEN_BUFFER_INFO csbi;
	  	COORD coord;
	
		GetConsoleScreenBufferInfo(handle_, &csbi);
		attr = csbi.wAttributes;
	
		if (attributes_old[type] == (WORD)-1)
			attributes_old[type] = attr;
	
		attribute_old = attr;
	
		while ((escape_range = [output rangeOfString:@"\x1b" options:0 range:escape_range]).location != OF_NOT_FOUND) {
			if (idx != escape_range.location) {
	
				[stream writeBuffer:(buffer_ + idx) length:escape_range.location - idx];
			}
	
			idx = escape_range.location;
	
			int values[6] = {-1, -1, -1, -1, -1, -1};
			int mode;
			int width, height;
	
			size_t value_idx = 0;
			size_t value_cnt = 0;
	
			while ((ch = [output characterAtIndex:++idx]) != '\0') {
				if (ch >= '0' && ch <= '9') {
					if (values[value_cnt] == -1) values[value_cnt] = ch - '0';
					else values[value_cnt] = (values[value_cnt] * 10) + (ch - '0');
					continue;
				}
	
				if (ch == '[')
					continue;
	
				if (ch == ';') {
					if (++value_cnt == 6)
						break;
	
					continue;
				}
	
				if (ch == '>' || ch == '?') {
					mode = ch;
	
					continue;
				}
	
				break;
			}
	
			switch (ch) {
				case 'h':
					if (mode == '?') {
						for (value_idx = 0; value_idx <= value_cnt; value_idx++) {
							switch (values[value_idx]) {
								case 3:
									GetConsoleScreenBufferInfo(handle_, &csbi);
									width = csbi.dwSize.X;
									height = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
									csize = width * (height + 1);
									coord.X = 0;
									coord.Y = csbi.srWindow.Top;
									FillConsoleOutputCharacter(handle_, ' ', csize, coord, &written);
									FillConsoleOutputAttribute(handle_, csbi.wAttributes, csize, coord, &written);
									SetConsoleCursorPosition(handle_, csbi.dwCursorPosition);
									csbi.dwSize.X = 132;
									SetConsoleScreenBufferSize(handle_, csbi.dwSize);
									csbi.srWindow.Right = csbi.srWindow.Left + 131;
									SetConsoleWindowInfo(handle_, TRUE, &csbi.srWindow);
									break;
								case 5:
									attr = ((attr & FOREGROUND_MASK) << 4 |
										(attr & BACKGROUND_MASK) >> 4);
									SetConsoleTextAttribute(handle_, attr);
									break;
								case 9:
									break;
								case 25:
									GetConsoleCursorInfo(handle_, &cci);
									cci.bVisible = TRUE;
									SetConsoleCursorInfo(handle_, &cci);
									break;
								case 47:
									coord.X = 0;
									coord.Y = 0;
									SetConsoleCursorPosition(handle_, coord);
									break;
								default:
									break;
							}
						}
	
					} else if (mode == '>' && values[0] == 5) {
						GetConsoleCursorInfo(handle_, &cci);
						cci.bVisible = FALSE;
						SetConsoleCursorInfo(handle_, &cci);
					}
	
					break;
				case 'l':
					if (mode == '?') {
						for (value_idx = 0; value_idx <= value_cnt; value_idx++) {
							switch (values[value_idx]) {
								case 3:
									GetConsoleScreenBufferInfo(handle_, &csbi);
									width = csbi.dwSize.X;
									height = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
									csize = width * (height + 1);
									coord.X = 0;
									coord.Y = csbi.srWindow.Top;
									FillConsoleOutputCharacter(handle_, ' ', csize, coord, &written);
									FillConsoleOutputAttribute(handle_, csbi.wAttributes, csize, coord, &written);
									SetConsoleCursorPosition(handle_, csbi.dwCursorPosition);
									csbi.srWindow.Right = csbi.srWindow.Left + 79;
									SetConsoleWindowInfo(handle_, TRUE, &csbi.srWindow);
									csbi.dwSize.X = 80;
									SetConsoleScreenBufferSize(handle_, csbi.dwSize);
									break;
								case 5:
									attr = ((attr & FOREGROUND_MASK) << 4 |
										(attr & BACKGROUND_MASK) >> 4);
									SetConsoleTextAttribute(handle_, attr);
									break;
								case 25:
									GetConsoleCursorInfo(handle_, &cci);
									cci.bVisible = FALSE;
									SetConsoleCursorInfo(handle_, &cci);
									break;
								default:
									break;
							}
						}
	
					} else if (mode == '>' && values[0] == 5) {
						GetConsoleCursorInfo(handle_, &cci);
						cci.bVisible = TRUE;
						SetConsoleCursorInfo(handle_, &cci);
					}
	
					break;
				case 'm':
					attr = attribute_old;
					int value;
					for (value_idx = 0; value_idx <= value_cnt; value_idx++) {
						value = values[value_idx];
	
						if (value == -1 || value == 0) attr = attributes_old[type];
						else if (value == 1) attr |= FOREGROUND_INTENSITY;
						else if (value == 4) attr |= FOREGROUND_INTENSITY;
						else if (value == 5) attr |= FOREGROUND_INTENSITY;
						else if (value == 7) attr = ((attr & FOREGROUND_MASK) << 4 | (attr & BACKGROUND_MASK) >> 4);
						else if (value == 10) ;//symbol on
						else if (value == 11) ;//symbol off
						else if (value == 22) attr &= ~FOREGROUND_INTENSITY;
						else if (value == 24) attr &= ~FOREGROUND_INTENSITY;
						else if (value == 25) attr &= ~FOREGROUND_INTENSITY;
						else if (value == 27) attr = ((attr & FOREGROUND_MASK) << 4 | (attr & BACKGROUND_MASK) >> 4);
						else if (value >= 30 && value <= 37) {
							attr = (attr & BACKGROUND_MASK);
	
							if ((value - 30) & 1)
								attr |=FOREGROUND_RED;
							if ((value - 30) & 2)
								attr |= FOREGROUND_GREEN;
							if ((value - 30) & 4)
								attr |= FOREGROUND_BLUE;
						}
						//else if (value == 39)
	            		//attr = (~attr & BACKGROUND_MASK);
	            		else if (value >= 40 && value <= 47) {
	            			attr = (attr & BACKGROUND_MASK);
	            			if ((value - 40) & 1)
	            				attr |= BACKGROUND_RED;
	            			if ((value - 40) & 2)
	            				attr |= BACKGROUND_GREEN;
	            			if ((value - 40) & 4)
	            				attr |= BACKGROUND_BLUE;
	            		}
	            		//else if (value == 49)
	            		//attr = (~attr & FOREGROUND_MASK);
	            		else if (value == 100)
	              			attr = attribute_old;
					}
					SetConsoleTextAttribute(handle_, attr);
					break;
				case 'K':
					GetConsoleScreenBufferInfo(handle_, &csbi);
					coord = csbi.dwCursorPosition;
					switch (values[0]) {
						default:
						case 0:
							csize = csbi.dwSize.X - coord.X;
							break;
						case 1:
							csize = coord.X;
							coord.X = 0;
							break;
						case 2:
							csize = csbi.dwSize.X;
							coord.X = 0;
							break;
					}
					FillConsoleOutputCharacter(handle_, ' ', csize, coord, &written);
					FillConsoleOutputAttribute(handle_, csbi.wAttributes, csize, coord, &written);
					SetConsoleCursorPosition(handle_, csbi.dwCursorPosition);
					break;
				case 'J':
					GetConsoleScreenBufferInfo(handle_, &csbi);
					width = csbi.dwSize.X;
					height = csbi.srWindow.Bottom - csbi.srWindow.Top + 1;
					coord = csbi.dwCursorPosition;
					switch (values[0]) {
						default:
						case 0:
							csize = width * (height - coord.Y) - coord.X;
							coord.X = 0;
							break;
						case 1:
							csize = width * coord.Y + coord.X;
							coord.X = 0;
							coord.Y = csbi.srWindow.Top;
							break;
						case 2:
							csize = width * (height + 1);
							coord.X = 0;
							coord.Y = csbi.srWindow.Top;
							break;
					}
					FillConsoleOutputCharacter(handle_, ' ', csize, coord, &written);
					FillConsoleOutputAttribute(handle_, csbi.wAttributes, csize, coord, &written);
					SetConsoleCursorPosition(handle_, csbi.dwCursorPosition);
					break;
				case 'H':
					GetConsoleScreenBufferInfo(handle_, &csbi);
					coord = csbi.dwCursorPosition;
					if (values[0] != -1) {
						if (values[1] != -1) {
							coord.Y = csbi.srWindow.Top + values[0] - 1;
							coord.X = values[1] - 1;
	
						} else {
							coord.X = values[0] - 1;
						}
	
					} else {
						coord.X = 0;
						coord.Y = csbi.srWindow.Top;
					}
					if (coord.X < csbi.srWindow.Left) coord.X = csbi.srWindow.Left;
					else if (coord.X > csbi.srWindow.Right) coord.X = csbi.srWindow.Right;
	
					if (coord.Y < csbi.srWindow.Top) coord.Y = csbi.srWindow.Top;
					else if (coord.Y > csbi.srWindow.Bottom) coord.Y = csbi.srWindow.Bottom;
	
					SetConsoleCursorPosition(handle_, coord);
					break;
				default:
					break;
			}
	
			
			escape_range.location = idx;
			escape_range.length = length_ - idx;
			idx++;
	
			continue;
	
		}
	
		if (idx != length_) {
			[stream writeBuffer:(buffer_ + idx) length: length_ - idx];
		}


	} @catch (id e) {
		exception = [e retain];
		@throw;

	} @finally {
		objc_autoreleasePoolPop(pool);

		if (exception != nil)
			[exception autorelease];
	}
}


@implementation OFStdIOStream_Win32ANSIConsole

+ (void)load
{
	
	original_imp = [OFStdIOStream_Win32Console replaceInstanceMethod:@selector(writeFormat:arguments:) withImplementation:[OFStdIOStream_Win32ANSIConsole instanceMethodForSelector:@selector(writeFormat:arguments:)] typeEncoding:[OFStdIOStream_Win32ANSIConsole typeEncodingForInstanceSelector:@selector(writeFormat:arguments:)]];
}

- (size_t)writeFormat: (OFConstantString*)format arguments: (va_list)arguments
{
	char *UTF8String;
	int length;

	if (format == nil)
		@throw [OFInvalidArgumentException exception];

	if ((length = of_vasprintf(&UTF8String, [format UTF8String],
	    arguments)) == -1)
		@throw [OFInvalidFormatException exception];

	@try {
		_w32_ansi_write(self, self->_handle, UTF8String, length);

	} @finally {
		free(UTF8String);
	}

	return length;
}

+ (void)unload
{
	[OFStdIOStream_Win32Console replaceInstanceMethod:@selector(writeFormat:arguments:) withImplementation:original_imp typeEncoding:[OFStdIOStream_Win32ANSIConsole typeEncodingForInstanceSelector:@selector(writeFormat:arguments:)]];

	HANDLE handle_ = INVALID_HANDLE_VALUE;

	if (attributes_old[0] != (WORD)-1) {
		handle_ = GetStdHandle(STD_OUTPUT_HANDLE);

		SetConsoleTextAttribute(handle_, attributes_old[0]);

		handle_ = INVALID_HANDLE_VALUE;
	}

	if (attributes_old[1] != (WORD)-1) {
		handle_ = GetStdHandle(STD_ERROR_HANDLE);

		SetConsoleTextAttribute(handle_, attributes_old[1]);

		handle_ = INVALID_HANDLE_VALUE;
	}
}

@end

#endif
