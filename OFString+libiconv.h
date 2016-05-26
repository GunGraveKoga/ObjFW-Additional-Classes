#import <ObjFW/OFObject.h>
#import <ObjFW/OFString.h>
#import "objfwext_macros.h"



OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUTF8;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUTF16;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUTF16BE;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUTF16LE;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUTF32;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUTF32BE;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUTF32LE;
OBJFW_EXTENSION_EXPORT OFString *const kOFCStringEncodingNative;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingNativeUnicode;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingASCII;

/* ISO 8-bit and 7-bit encodings */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin1;	/* ISO 8859-1 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin2;	/* ISO 8859-2 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin3;	/* ISO 8859-3 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin4;	/* ISO 8859-4 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatinCyrillic;	/* ISO 8859-5 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatinArabic;	/* ISO 8859-6, =ASMO 708, =DOS CP 708 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatinGreek;	/* ISO 8859-7 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatinHebrew;	/* ISO 8859-8 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin5;	/* ISO 8859-9 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin6;	/* ISO 8859-10 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin7;	/* ISO 8859-13 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin8;	/* ISO 8859-14 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin9;	/* ISO 8859-15 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISOLatin10;	/* ISO 8859-16 */

OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingKOI8_R;	/* Russian internet standard */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingKOI8_U;	/* RFC 2319, Ukrainian */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingKOI8_RU;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingKOI8_T;

/* MS-DOS & Windows encodings */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSLatinUS;	/* code page 437 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSGreek;	/* code page 737 (formerly code page 437G) */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSBalticRim;	/* code page 775 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSLatin1;	/* code page 850, "Multilingual" */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSLatin2;	/* code page 852, Slavic */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSMultilingualLatin;	/* code page 853, Multilingual Latin */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSCyrillic;	/* code page 855, IBM Cyrillic */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSTurkish;	/* code page 857, IBM Turkish */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingCP858;	/* code page 858 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSPortuguese;	/* code page 860 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSIcelandic;	/* code page 861 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSHebrew;	/* code page 862 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSCanadianFrench;	/* code page 863 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSArabic;	/* code page 864 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSNordic;	/* code page 865 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSRussian;	/* code page 866 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSGreek2;	/* code page 869, IBM Modern Greek */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSThai;	/* code page 874, also for Windows */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSJapanese;	/* code page 932, also for Windows */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSChineseSimplif;	/* code page 936, also for Windows */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSKorean;	/* code page 949, also for Windows; Unified Hangul Code */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingDOSChineseTrad;	/* code page 950, also for Windows */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsLatin2;	/* code page 1250, Central Europe */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsCyrillic;	/* code page 1251, Slavic Cyrillic */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsLatin1;	/* ANSI codepage 1252 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsGreek;	/* code page 1253 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsLatin5;	/* code page 1254, Turkish */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsHebrew;	/* code page 1255 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsArabic;	/* code page 1256 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsBalticRim;	/* code page 1257 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingWindowsVietnamese;	/* code page 1258 */


/* MAC OS collections */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacRoman;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacCentralEurope;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacIceland;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacCroatian;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacRomania;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacCyrillic;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacUkraine;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacGreek;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacTurkish;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacHebrew;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacArabic;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacintosh;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMacThai;

/* Various national standards */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingSHIFT_JIS;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingShift_JISX0213;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingGBK;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingGB18030;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodinHZ;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingGBK;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingGB18030;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingCP1131;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingBIG5;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingBIG5_HKSCS;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingBIG5_HKSCS_2001;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingBIG5_HKSCS_1999;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingJOHAB;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingARMSCII_8;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingGeorgian_Academy;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingGeorgian_PS;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingPT154;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingRK1048;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingTIS_620;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingMuleLao_1;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingCP1133;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingVISCII;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingTCVN;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingHP_ROMAN8;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingNEXTSTEP;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUCS_2;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUCS_2BE;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUCS_2LE;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUCS_4;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUCS_4BE;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUCS_4LE;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUTF7;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingC99;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingJAVA;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUCS_2_INTERNAL;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingUCS_4_INTERNAL;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingCP1125;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingBIG5_2003;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingTDS565;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingATARIST;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingRISCOS_LATIN1;


/* ISO 2022 collections */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISO_2022_JP;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISO_2022_JP_2;	/* RFC 2237*/
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISO_2022_JP_1;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISO_2022_CN;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISO_2022_CN_EXT;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISO_2022_KR;
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingISO_2022_JP_3;	/* JIS X0213*/

/* EUC collections */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingEUC_CN;	/* ISO 646, GB 2312-80 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingEUC_TW;	/* ISO 646, CNS 11643-1992 Planes 1-16 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingEUC_KR;	/* ISO 646, KS C 5601-1987 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingEUC_JP;	/* ISO 646, 1-byte katakana, JIS 208, JIS 212 */
OBJFW_EXTENSION_EXPORT OFString *const kOFStringEncodingEUC_JISX0213;



@interface OFString(libiconv)

+ (instancetype)stringWithBytes:(const void *)CString encoding:(OFString *)encodingName length:(size_t)length;
+ (instancetype)stringWithBytes:(const void *)CString encoding:(OFString *)encodingName;
+ (instancetype)stringWithNativeCString:(const char*)CString;
- (instancetype)initWithBytes:(const void *)CString encoding:(OFString *)encodingName length:(size_t)length;
- (instancetype)initWithBytes:(const void *)CString encoding:(OFString *)encodingName;
- (instancetype)initWithNativeCString:(const char*)CString;
- (const char *)cStringUsingEncoding:(OFString *)encodingName;
- (const char *)cStringNative;

@end