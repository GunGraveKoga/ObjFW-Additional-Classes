#import <ObjFW/ObjFW.h>
#import "OFString+libiconv.h"
#import "OFUniversalException.h"
#include <iconv.h>
#include <error.h>
#include <string.h>


OFString *const kOFStringEncodingUTF8 = @"UTF-8";
OFString *const kOFStringEncodingUTF16 = @"UTF−16"; 
OFString *const kOFStringEncodingUTF16BE = @"UTF−16BE"; 
OFString *const kOFStringEncodingUTF16LE = @"UTF−16LE";
OFString *const kOFStringEncodingUTF32 = @"UTF−32";
OFString *const kOFStringEncodingUTF32BE = @"UTF−32BE";
OFString *const kOFStringEncodingUTF32LE = @"UTF−32LE";
OFString *const kOFCStringEncodingNative = @"CHAR";
OFString *const kOFStringEncodingNativeUnicode = @"WCHAR_T";
OFString *const kOFStringEncodingASCII = @"ASCII";

OFString *const kOFStringEncodingISOLatin1 = @"ISO−8859−1"; /* ISO 8859-1 */
OFString *const kOFStringEncodingISOLatin2 = @"ISO−8859−2"; /* ISO 8859-2 */
OFString *const kOFStringEncodingISOLatin3 = @"ISO−8859−3"; /* ISO 8859-3 */
OFString *const kOFStringEncodingISOLatin4 = @"ISO−8859−4"; /* ISO 8859-4 */
OFString *const kOFStringEncodingISOLatinCyrillic = @"ISO−8859−5";  /* ISO 8859-5 */
OFString *const kOFStringEncodingISOLatinArabic = @"ISO−8859−6";    /* ISO 8859-6, =ASMO 708, =DOS CP 708 */
OFString *const kOFStringEncodingISOLatinGreek = @"ISO−8859−7"; /* ISO 8859-7 */
OFString *const kOFStringEncodingISOLatinHebrew = @"ISO−8859−8";    /* ISO 8859-8 */
OFString *const kOFStringEncodingISOLatin5 = @"ISO−8859−9"; /* ISO 8859-9 */
OFString *const kOFStringEncodingISOLatin6 = @"ISO−8859−10";    /* ISO 8859-10 */
OFString *const kOFStringEncodingISOLatin7 = @"ISO−8859−13";    /* ISO 8859-13 */
OFString *const kOFStringEncodingISOLatin8 = @"ISO−8859−14";    /* ISO 8859-14 */
OFString *const kOFStringEncodingISOLatin9 = @"ISO−8859−15";    /* ISO 8859-15 */
OFString *const kOFStringEncodingISOLatin10 = @"ISO−8859−16";   /* ISO 8859-16 */

OFString *const kOFStringEncodingKOI8_R = @"KOI8−R";    /* Russian internet standard */
OFString *const kOFStringEncodingKOI8_U = @"KOI8−U";    /* RFC 2319, Ukrainian */
OFString *const kOFStringEncodingKOI8_RU = @"KOI8−RU";
OFString *const kOFStringEncodingKOI8_T = @"KOI8−T";


OFString *const kOFStringEncodingDOSLatinUS = @"CP437"; /* code page 437 */
OFString *const kOFStringEncodingDOSGreek = @"CP737";   /* code page 737 (formerly code page 437G) */
OFString *const kOFStringEncodingDOSBalticRim = @"CP775";   /* code page 775 */
OFString *const kOFStringEncodingDOSLatin1 = @"CP850";  /* code page 850, "Multilingual" */
OFString *const kOFStringEncodingDOSLatin2 = @"CP852";  /* code page 852, Slavic */
OFString *const kOFStringEncodingDOSMultilingualLatin = @"CP853";   /* code page 853, Multilingual Latin */
OFString *const kOFStringEncodingDOSCyrillic = @"CP855";    /* code page 855, IBM Cyrillic */
OFString *const kOFStringEncodingDOSTurkish = @"CP857"; /* code page 857, IBM Turkish */
OFString *const kOFStringEncodingCP858 = @"CP858";  /* code page 858 */
OFString *const kOFStringEncodingDOSPortuguese = @"CP860";  /* code page 860 */
OFString *const kOFStringEncodingDOSIcelandic = @"CP861";   /* code page 861 */
OFString *const kOFStringEncodingDOSHebrew = @"CP862";  /* code page 862 */
OFString *const kOFStringEncodingDOSCanadianFrench = @"CP863";  /* code page 863 */
OFString *const kOFStringEncodingDOSArabic = @"CP864";  /* code page 864 */
OFString *const kOFStringEncodingDOSNordic = @"CP865";  /* code page 865 */
OFString *const kOFStringEncodingDOSRussian = @"CP866"; /* code page 866 */
OFString *const kOFStringEncodingDOSGreek2 = @"CP869";  /* code page 869, IBM Modern Greek */
OFString *const kOFStringEncodingDOSThai = @"CP874";    /* code page 874, also for Windows */
OFString *const kOFStringEncodingDOSJapanese = @"CP932";    /* code page 932, also for Windows */
OFString *const kOFStringEncodingDOSChineseSimplif = @"CP936";  /* code page 936, also for Windows */
OFString *const kOFStringEncodingDOSKorean = @"CP949";  /* code page 949, also for Windows; Unified Hangul Code */
OFString *const kOFStringEncodingDOSChineseTrad = @"CP950"; /* code page 950, also for Windows */
OFString *const kOFStringEncodingWindowsLatin2 = @"CP1250"; /* code page 1250, Central Europe */
OFString *const kOFStringEncodingWindowsCyrillic = @"CP1251";   /* code page 1251, Slavic Cyrillic */
OFString *const kOFStringEncodingWindowsLatin1 = @"CP1252"; /* ANSI codepage 1252 */
OFString *const kOFStringEncodingWindowsGreek = @"CP1253";  /* code page 1253 */
OFString *const kOFStringEncodingWindowsLatin5 = @"CP1254"; /* code page 1254, Turkish */
OFString *const kOFStringEncodingWindowsHebrew = @"CP1255"; /* code page 1255 */
OFString *const kOFStringEncodingWindowsArabic = @"CP1256"; /* code page 1256 */
OFString *const kOFStringEncodingWindowsBalticRim = @"CP1257";  /* code page 1257 */
OFString *const kOFStringEncodingWindowsVietnamese = @"CP1258"; /* code page 1258 */

OFString *const kOFStringEncodingMacRoman = @"MacRoman";
OFString *const kOFStringEncodingMacCentralEurope = @"MacCentralEurope";
OFString *const kOFStringEncodingMacIceland = @"MacIceland";
OFString *const kOFStringEncodingMacCroatian = @"MacCroatian";
OFString *const kOFStringEncodingMacRomania = @"MacRomania";
OFString *const kOFStringEncodingMacCyrillic = @"MacCyrillic";
OFString *const kOFStringEncodingMacUkraine = @"MacUkraine";
OFString *const kOFStringEncodingMacGreek = @"MacGreek";
OFString *const kOFStringEncodingMacTurkish = @"MacTurkish";
OFString *const kOFStringEncodingMacHebrew = @"MacHebrew";
OFString *const kOFStringEncodingMacArabic = @"MacArabic";
OFString *const kOFStringEncodingMacintosh = @"Macintosh";
OFString *const kOFStringEncodingMacThai = @"MacThai";

OFString *const kOFStringEncodingISO_2022_JP = @"ISO−2022−JP";
OFString *const kOFStringEncodingISO_2022_JP_2 = @"ISO−2022−JP−2";
OFString *const kOFStringEncodingISO_2022_JP_1 = @"ISO−2022−JP−1";
OFString *const kOFStringEncodingISO_2022_CN = @"ISO−2022−CN";
OFString *const kOFStringEncodingISO_2022_CN_EXT = @"ISO−2022−CN−EXT";
OFString *const kOFStringEncodingISO_2022_KR = @"ISO−2022−KR";
OFString *const kOFStringEncodingISO_2022_JP_3 = @"ISO−2022−JP−3";

OFString *const kOFStringEncodingEUC_JP = @"EUC−JP";
OFString *const kOFStringEncodingEUC_CN = @"EUC−CN";
OFString *const kOFStringEncodingEUC_TW = @"EUC−TW";
OFString *const kOFStringEncodingEUC_KR = @"EUC−KR";
OFString *const kOFStringEncodingEUC_JISX0213 = @"EUC−JISX0213";

OFString *const kOFStringEncodingCP1131 = @"CP1131";
OFString *const kOFStringEncodingSHIFT_JIS = @"SHIFT_JIS";
OFString *const kOFStringEncodingHZ = @"HZ";
OFString *const kOFStringEncodingGBK = @"GBK";
OFString *const kOFStringEncodingGB18030 = @"GB18030";
OFString *const kOFStringEncodingBIG5 = @"BIG5";
OFString *const kOFStringEncodingBIG5_HKSCS = @"BIG5−HKSCS";
OFString *const kOFStringEncodingBIG5_HKSCS_2001 = @"BIG5−HKSCS:2001";
OFString *const kOFStringEncodingBIG5_HKSCS_1999 = @"BIG5−HKSCS:1999";
OFString *const kOFStringEncodingJOHAB = @"JOHAB";
OFString *const kOFStringEncodingARMSCII_8 = @"ARMSCII−8";
OFString *const kOFStringEncodingGeorgian_Academy = @"Georgian−Academy";
OFString *const kOFStringEncodingGeorgian_PS = @"Georgian−PS";
OFString *const kOFStringEncodingPT154 = @"PT154";
OFString *const kOFStringEncodingRK1048 = @"RK1048";
OFString *const kOFStringEncodingTIS_620 = @"TIS−620";
OFString *const kOFStringEncodingMuleLao_1 = @"MuleLao−1";
OFString *const kOFStringEncodingCP1133 = @"CP1133";
OFString *const kOFStringEncodingVISCII = @"VISCII";
OFString *const kOFStringEncodingTCVN = @"TCVN";
OFString *const kOFStringEncodingHP_ROMAN8 = @"HP−ROMAN8";
OFString *const kOFStringEncodingNEXTSTEP = @"NEXTSTEP";
OFString *const kOFStringEncodingUCS_2 = @"UCS−2";
OFString *const kOFStringEncodingUCS_2BE = @"UCS−2BE";
OFString *const kOFStringEncodingUCS_2LE = @"UCS−2LE";
OFString *const kOFStringEncodingUCS_4 = @"UCS−4";
OFString *const kOFStringEncodingUCS_4BE = @"UCS−4BE";
OFString *const kOFStringEncodingUCS_4LE = @"UCS−4LE";
OFString *const kOFStringEncodingUTF7 = @"UTF−7";
OFString *const kOFStringEncodingC99 = @"C99";
OFString *const kOFtringEncodingJAVAS = @"JAVA";
OFString *const kOFStringEncodingUCS_2_INTERNAL = @"UCS−2−INTERNAL";
OFString *const kOFStringEncodingUCS_4_INTERNAL = @"UCS−4−INTERNAL";
OFString *const kOFStringEncodingCP1125 = @"CP1125";
OFString *const kOFStringEncodingShift_JISX0213 = @"Shift_JISX0213";
OFString *const kOFStringEncodingBIG5_2003 = @"BIG5−2003";
OFString *const kOFStringEncodingTDS565 = @"TDS565";
OFString *const kOFStringEncodingATARIST = @"ATARIST";
OFString *const kOFStringEncodingRISCOS_LATIN1 = @"RISCOS−LATIN1";


size_t __string_length(const char *string) {
    size_t length = 0;

    while (*string++ != 0)
        length++;

    return length;
}

size_t __string_length_for_encoding(const char* string, OFString* encoding) {
    return 0;
}


@implementation OFString(libiconv)

+ (instancetype)stringWithBytes:(const void *)CString encoding:(OFString *)encodingName length:(size_t)length
{
    return [[[self alloc] initWithBytes:CString encoding:encodingName length:length] autorelease];
}

+ (instancetype)stringWithBytes:(const void *)CString encoding:(OFString *)encodingName
{
    return [[[self alloc] initWithBytes:CString encoding:encodingName] autorelease];
}

+ (instancetype)stringWithNativeCString:(const char*)CString
{
    return [[[self alloc] initWithNativeCString:(const void *)CString] autorelease];
}


- (instancetype)initWithBytes:(const void *)CString encoding:(OFString *)encodingName
{
    size_t length = __string_length(CString);

    return [self initWithBytes:CString encoding:encodingName length:length];
}

- (instancetype)initWithNativeCString:(const char*)CString
{
    return [self initWithBytes:(const void *)CString encoding:kOFCStringEncodingNative];
}

- (instancetype)initWithBytes:(const void *)CString encoding:(OFString *)encodingName length:(size_t)length
{
	void* pool = objc_autoreleasePoolPush();

    OFString* encoding = [[encodingName retain] autorelease];

	if ([encoding isEqual:kOFStringEncodingUTF8]) {
		objc_autoreleasePoolPop(pool);

		return [self initWithUTF8String:(const char *)CString length:length];

	} else if ([encoding isEqual:kOFStringEncodingUTF16]) {
        objc_autoreleasePoolPop(pool);

        return [self initWithUTF16String:(const of_char16_t *)CString length:length];

    } else if ([encoding isEqual:kOFStringEncodingUTF16BE]) {
        objc_autoreleasePoolPop(pool);

        return [self initWithUTF16String:(const of_char16_t *)CString length:length byteOrder:OF_BYTE_ORDER_BIG_ENDIAN ];

    } else if ([encoding isEqual:kOFStringEncodingUTF16LE]) {
        objc_autoreleasePoolPop(pool);

        return [self initWithUTF16String:(const of_char16_t *)CString length:length byteOrder:OF_BYTE_ORDER_LITTLE_ENDIAN ];

    } else if ([encoding isEqual:kOFStringEncodingUTF32]) {
        objc_autoreleasePoolPop(pool);

        return [self initWithUTF32String:(const of_char32_t *)CString length:length];

    } else if ([encoding isEqual:kOFStringEncodingUTF32BE]) {
        objc_autoreleasePoolPop(pool);

        return [self initWithUTF32String:(const of_char32_t *)CString length:length byteOrder:OF_BYTE_ORDER_BIG_ENDIAN ];

    } else if ([encoding isEqual:kOFStringEncodingUTF32LE]) {
        objc_autoreleasePoolPop(pool);

        return [self initWithUTF32String:(const of_char32_t *)CString length:length byteOrder:OF_BYTE_ORDER_LITTLE_ENDIAN ];
        
    }


    iconv_t conv_desc;
    conv_desc = iconv_open([kOFStringEncodingUTF8 UTF8String], [encoding UTF8String]);

    if ((int) conv_desc == -1) {
        objc_autoreleasePoolPop(pool);
        iconv_close(conv_desc);

        if (errno == EINVAL) {
            [self release];
            @throw [OFInvalidEncodingException exception];
        } else {
            [self release];
            [OFException raise:@"ICONV Exception" format:@"%s", strerror(errno)];
        }
    }

    size_t conv_value;
    size_t utf8_string_length;
    size_t utf8_string_lenngth_start;
    size_t c_string_length;
    size_t c_string_length_start;
    char* utf8_buf;
    char* utf8_buf_start;
    char* c_str_buf;

    c_string_length = length;

    if (!c_string_length) {
        objc_autoreleasePoolPop(pool);
        [self release];
        iconv_close(conv_desc);
        @throw [OFInitializationFailedException exceptionWithClass:[OFString class]];
    }

    utf8_string_length = (c_string_length * 4) + 1;
    utf8_buf = (char *)__builtin_alloca(utf8_string_length);

    if (utf8_buf == NULL) {
        objc_autoreleasePoolPop(pool);
        iconv_close(conv_desc);
        [self release];
        @throw [OFOutOfMemoryException exceptionWithRequestedSize:(utf8_string_length * sizeof(char))];
    }
    
    utf8_buf_start = utf8_buf;
    utf8_string_lenngth_start = utf8_string_length;
    c_string_length_start = c_string_length;
    c_str_buf = (char*)CString;

    conv_value = iconv(conv_desc, &c_str_buf, &c_string_length, &utf8_buf, &utf8_string_length);

    if (conv_value == (size_t) -1) {
        objc_autoreleasePoolPop(pool);
        iconv_close(conv_desc);
        [self release];
    
        switch (errno) {
            case EILSEQ:
                [OFException raise:@"ICONV Exception" format:@"Invalid multibyte sequence."];
                break;
            case EINVAL:
                [OFException raise:@"ICONV Exception" format:@"Incomplete multibyte sequence."];
                break;
            case E2BIG:
                [OFException raise:@"ICONV Exception" format:@"No more room."];
                break;
            default:
                [OFException raise:@"ICONV Exception" format:@"%s", strerror(errno)];
                break;
        }

    }

    size_t converted_string_length = (utf8_string_lenngth_start - utf8_string_length);

    utf8_buf_start[converted_string_length] = '\0';

    objc_autoreleasePoolPop(pool);
    iconv_close(conv_desc);

    return [self initWithUTF8String:utf8_buf_start length:converted_string_length];

}

- (const char *)cStringNative
{
    return [self cStringUsingEncoding:kOFCStringEncodingNative];
}

- (const char *)cStringUsingEncoding:(OFString *)encodingName
{
    void* pool = objc_autoreleasePoolPush();

    OFString* encoding = [[encodingName retain] autorelease];

    if ([encoding isEqual:kOFStringEncodingUTF8]) {
        objc_autoreleasePoolPop(pool);

        return [self UTF8String];

    } else if ([encoding isEqual:kOFStringEncodingUTF16]) {
        objc_autoreleasePoolPop(pool);

        return (const char *)[self UTF16String];

    } else if ([encoding isEqual:kOFStringEncodingUTF16BE]) {
        objc_autoreleasePoolPop(pool);

        return (const char *)[self UTF16StringWithByteOrder:OF_BYTE_ORDER_BIG_ENDIAN ];

    } else if ([encoding isEqual:kOFStringEncodingUTF16LE]) {
        objc_autoreleasePoolPop(pool);

        return (const char *)[self UTF16StringWithByteOrder:OF_BYTE_ORDER_LITTLE_ENDIAN ];

    } else if ([encoding isEqual:kOFStringEncodingUTF32]) {
        objc_autoreleasePoolPop(pool);

        return (const char *)[self UTF32String];

    } else if ([encoding isEqual:kOFStringEncodingUTF32BE]) {
        objc_autoreleasePoolPop(pool);

        return (const char *)[self  UTF32StringWithByteOrder:OF_BYTE_ORDER_BIG_ENDIAN ];

    } else if ([encoding isEqual:kOFStringEncodingUTF32LE]) {
        objc_autoreleasePoolPop(pool);

        return (const char *)[self  UTF32StringWithByteOrder:OF_BYTE_ORDER_LITTLE_ENDIAN ];
        
    }


    iconv_t conv_desc;
    conv_desc = iconv_open([encoding UTF8String], [kOFStringEncodingUTF8 UTF8String]);

    if ((int) conv_desc == -1) {
        objc_autoreleasePoolPop(pool);
        iconv_close(conv_desc);

        if (errno == EINVAL) {
            @throw [OFInvalidEncodingException exception];
        } else {
            [OFException raise:@"ICONV Exception" format:@"%s", strerror(errno)];
        }
    }

    size_t conv_value;
    size_t utf8_string_length;
    size_t utf8_string_lenngth_start;
    size_t c_string_length;
    size_t c_string_length_start;
    char* utf8_buf;
    char* utf8_buf_start;
    char* c_str_buf;
    char* c_str_buf_start;

    utf8_string_length = [self UTF8StringLength];

    if (!utf8_string_length) {
        objc_autoreleasePoolPop(pool);
        iconv_close(conv_desc);

        [OFException raise:@"ICONV Exception" format:@"Empty UTF-8 string."];
    }

    c_string_length = (utf8_string_length * 2) + 1;
    c_str_buf = (char *)__builtin_alloca(c_string_length);

    if (c_str_buf == NULL) {
        objc_autoreleasePoolPop(pool);
        iconv_close(conv_desc);
        @throw [OFOutOfMemoryException exceptionWithRequestedSize:(c_string_length * sizeof(char))];
    }
    
    c_str_buf_start = c_str_buf;
    c_string_length_start = c_string_length;
    utf8_string_lenngth_start = utf8_string_length;
    utf8_buf = (char*)[self UTF8String];
    utf8_buf_start = utf8_buf;

    conv_value = iconv(conv_desc, &utf8_buf, &utf8_string_length, &c_str_buf, &c_string_length);

    if (conv_value == (size_t) -1) {
        objc_autoreleasePoolPop(pool);
        iconv_close(conv_desc);
    
        switch (errno) {
            case EILSEQ:
                [OFException raise:@"ICONV Exception" format:@"Invalid multibyte sequence."];
                break;
            case EINVAL:
                [OFException raise:@"ICONV Exception" format:@"Incomplete multibyte sequence."];
                break;
            case E2BIG:
                [OFException raise:@"ICONV Exception" format:@"No more room."];
                break;
            default:
                [OFException raise:@"ICONV Exception" format:@"%s", strerror(errno)];
                break;
        }

    }

    size_t converted_string_length = (c_string_length_start - c_string_length);

    c_str_buf_start[converted_string_length] = '\0';

    char* result = (char *)calloc(converted_string_length, sizeof(char));

    if (result == NULL) {
        objc_autoreleasePoolPop(pool);
        iconv_close(conv_desc);
        @throw [OFOutOfMemoryException exceptionWithRequestedSize:(converted_string_length * sizeof(char))];
    }

    memcpy(result, c_str_buf_start, converted_string_length);

    if ((result == NULL) || strlen(result) == 0) {
        objc_autoreleasePoolPop(pool);
        [OFException raise:@"ICONV Exception" format:@"%s", strerror(errno)];
    }

    objc_autoreleasePoolPop(pool);
    iconv_close(conv_desc);

    return result;
}

@end
