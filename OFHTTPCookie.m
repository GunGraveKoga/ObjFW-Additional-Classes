#import <ObjFW/ObjFW.h>
#import "OFHTTPCookie.h"



OFString * const OFHTTPCookieComment = @"OFHTTPCookieComment";
OFString * const OFHTTPCookieCommentURL = @"OFHTTPCookieCommentURL";
OFString * const OFHTTPCookieDiscard = @"OFHTTPCookieDiscard";
OFString * const OFHTTPCookieDomain = @"OFHTTPCookieDomain";
OFString * const OFHTTPCookieExpires = @"OFHTTPCookieExpires";
OFString * const OFHTTPCookieMaximumAge = @"OFHTTPCookieMaximumAge";
OFString * const OFHTTPCookieName = @"OFHTTPCookieName";
OFString * const OFHTTPCookieOriginURL = @"OFHTTPCookieOriginURL";
OFString * const OFHTTPCookiePath = @"OFHTTPCookiePath";
OFString * const OFHTTPCookiePort = @"OFHTTPCookiePort";
OFString * const OFHTTPCookieSecure = @"OFHTTPCookieSecure";
OFString * const OFHTTPCookieHTTPOnly = @"OFHTTPCookieHTTPOnly";
OFString * const OFHTTPCookieValue = @"OFHTTPCookieValue";
OFString * const OFHTTPCookieVersion = @"OFHTTPCookieVersion";

#define MAX_COOKIE_LINE 5000
#define MAX_COOKIE_LINE_TXT "4999"


#define MAX_NAME 1024
#define MAX_NAME_TXT "1023"

#define ISBLANK(x) ((((unsigned char)x) == ' ') || (((unsigned char)x) == '\t'))

#ifdef DEBUG
#define EbrDebugLog(fmt, ...)
#else
#define EbrDebugLog(fmt, ...)
#endif

static const char *abday[7] = {
  "Sun","Mon","Tue","Wed","Thu","Fri","Sat"
};
static const char *abmon[12] = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
};

bool cstr_raw_equal(const char* a, const char* b) {
    return strcasecmp(a, b) == 0;
}

void parseCookies(const char* lineptr, id dict) {
	char name[MAX_NAME], what[MAX_COOKIE_LINE];
    char dayOfWeek[4], monthOfYear[4], timeZone[4] = {0};
    int year, month, day, hour, minut, second = 0;


    const char* ptr = lineptr;
    const char* nextptr = strchr(ptr, ';');

    do {
        name[0] = what[0] = '\0';
        if (sscanf(ptr, "%" MAX_NAME_TXT "[^;\r\n =]=%" MAX_COOKIE_LINE_TXT "[^;\r\n]", name, what) > 0) {
            const char* endOfName = ptr + strlen(name);
            while (*endOfName && ISBLANK(*endOfName))
                ++endOfName;

            bool sep = *endOfName == '=';

            size_t whatLen = strlen(what);
            while (whatLen && ISBLANK(what[whatLen - 1])) {
                what[--whatLen] = 0;
            }
            char* whatptr = what;
            while (ISBLANK(*whatptr))
                ++whatptr;

            bool done = false;
            if (whatLen == 0) {
                done = true;
                if (cstr_raw_equal(name, "secure"))
                    dict[OFHTTPCookieSecure] = @YES;
                else if (cstr_raw_equal(name, "httponly"))
                    dict[OFHTTPCookieHTTPOnly] = @YES;
                else if (sep)
                    done = false;
            }

            if (done) {
            } else if ([dict count] == 0) {
                dict[OFHTTPCookieName] = @(name);
                dict[OFHTTPCookieValue] = @(whatptr);
            } else if (cstr_raw_equal("domain", name)) {

                if (whatptr[0] == '.')
                    ++whatptr;


                dict[OFHTTPCookieDomain] = @(whatptr);
            } else if (cstr_raw_equal("path", name)) {
                dict[OFHTTPCookiePath] = @(whatptr);
            } else if (cstr_raw_equal("version", name)) {
                dict[OFHTTPCookieVersion] = @(whatptr);
            } else if (cstr_raw_equal("max-age", name)) {
                dict[OFHTTPCookieMaximumAge] = @(whatptr);
            } else if (cstr_raw_equal("comment", name)) {
                dict[OFHTTPCookieComment] = @(whatptr);
            } else if (cstr_raw_equal("commenturl", name)) {
                dict[OFHTTPCookieCommentURL] = @(whatptr);
            } else if (cstr_raw_equal("originalurl", name)) {
                dict[OFHTTPCookieOriginURL] = @(whatptr);
            } else if (cstr_raw_equal("port", name)) {
                dict[OFHTTPCookiePort] = @(whatptr);
            } else if (cstr_raw_equal("discard", name)) {
                dict[OFHTTPCookieDiscard] = @YES;
            } else if (cstr_raw_equal("expires", name)) {
                int res = sscanf(whatptr, "%3s, %d-%3s-%d %d:%d:%d %3s", dayOfWeek, &day, monthOfYear, &year, &hour, &minut, &second, timeZone);
                BOOL isDayOfWeekValid = NO;
                BOOL isMonthOfYearValid = NO;
                switch (res) {
                    case 0:
                    case EOF:
                        @throw [OFInvalidFormatException exception];
                    default:
                        switch (res) {
                            case 8:
                                for (size_t idx = 0; idx < sizeof(abday); ++idx) {
                                    if ((strcmp(abday[idx], dayOfWeek)) == 0) {
                                        isDayOfWeekValid = YES;
                                        break;
                                    }
                                }
                                if (isDayOfWeekValid) {
                                    for (size_t idx = 0; idx < sizeof(abmon); ++idx) {
                                        if ((strcmp(abmon[idx], monthOfYear)) == 0) {
                                            isMonthOfYearValid = YES;
                                            month = idx + 1;
                                            break;
                                        }
                                    }
                                    if (isMonthOfYearValid) {
                                        [dict setObject:[OFDate dateWithDateString:
                                            [OFString stringWithFormat:
                                                @"%02d %02d %04d %02d:%02d:%02d", 
                                                day, month, year, hour, minut, second] 
                                            format:@"%d %m %Y %H:%M:%S"] 
                                        forKey:OFHTTPCookieExpires];

                                    }else
                                        @throw [OFInvalidArgumentException exception];

                                } else
                                    @throw [OFInvalidArgumentException exception];
                                break;
                            default:
                                @throw [OFInvalidFormatException exception];
                        }
                }
            } else {
                EbrDebugLog("Unrecognized cookie name: %s", name);
            }


            if (!nextptr || !*nextptr) {
                nextptr = 0;
                continue;
            }

            
            ptr = nextptr + 1;
            while (ISBLANK(*ptr))
                ++ptr;

            nextptr = strchr(ptr, ';');
            if (!nextptr && *ptr) {
                
                nextptr = strchr(ptr, '\0');
            }
        }
    } while (nextptr);
	
}

@interface OFHTTPCookie()
{
    
    OFDictionary OF_GENERIC(OFString *,id) *_properties;
}

+ (OFArray *) _parseField: (OFString *)field forHeader: (OFString *)header andURL: (OFURL *)url;
- (BOOL) _isValidProperty: (OFString *)prop;

@end

@implementation OFHTTPCookie

@dynamic comment;
@dynamic commentURL;
@dynamic domain;
@dynamic expiresDate;
@dynamic HTTPOnly;
@dynamic secure;
@dynamic sessionOnly;
@dynamic name;
@dynamic path;
@dynamic portList;
@dynamic properties;
@dynamic value;
@dynamic version;

+ (OFArray *) _parseField: (OFString *)field forHeader: (OFString *)header andURL: (OFURL *)url
{
    int version;
    OFString *defaultPath, *defaultDomain;
    OFMutableArray *a;

    void* _pool = objc_autoreleasePoolPush();

    if ([header isEqual: @"Set-Cookie"])
        version = 0;
    else if ([header isEqual: @"Set-Cookie2"])
        version = 1;
    else
        return nil;

    a = [OFMutableArray array];

    

    defaultDomain = [url host];
    defaultPath = [url path];
    if ([[url string] hasSuffix: @"/"] == NO)
        defaultPath = [defaultPath stringByDeletingLastPathComponent];

    OFArray* cookieArray = nil;
    @try {
        cookieArray = (OFArray *)([field componentsSeparatedByString:@","]);
    } @catch (OFException* e) {
        
    }

    if (cookieArray == nil)
        cookieArray = @[field];


    for (OFString* cookieString in cookieArray) {
        OFHTTPCookie *cookie = nil;
        OFMutableDictionary *dict = [OFMutableDictionary dictionary];
        
        @try {
            parseCookies([cookieString UTF8String], dict);
        }@catch(id e) {
            objc_autoreleasePoolPop(_pool);
            @throw e;
        }
        
        if ([dict count] == 0) {
            objc_autoreleasePoolPop(_pool);
            @throw [OFInvalidArgumentException exception];
        }

        if (dict[OFHTTPCookieExpires] == nil) {
            if (dict[OFHTTPCookieMaximumAge] == nil) {
                dict[OFHTTPCookieDiscard] = @YES;
            } else
                dict[OFHTTPCookieExpires] = [OFDate dateWithTimeIntervalSinceNow:(of_time_interval_t)[dict[OFHTTPCookieExpires] doubleValue]];
        }

        if (dict[OFHTTPCookiePath] == nil)
            dict[OFHTTPCookiePath] = defaultPath;
        if (dict[OFHTTPCookieDomain] == nil)
            dict[OFHTTPCookieDomain] = defaultDomain;


        if (dict[OFHTTPCookieVersion] == nil)
            dict[OFHTTPCookieVersion] = [OFString stringWithFormat:@"%d", version];

        [dict makeImmutable];
        cookie = [OFHTTPCookie cookieWithProperties: dict];
        
        [a addObject:cookie];
    }
    
    [a retain];
    objc_autoreleasePoolPop(_pool);
    [a makeImmutable];
    
    return [a autorelease];

}

+ (instancetype) cookieWithProperties: (OFDictionary *)properties
{
    return [[[self alloc] initWithProperties:properties] autorelease];
}

+ (OFArray *) cookiesWithResponseHeaderFields: (OFDictionary *)headerFields forURL:(OFURL *)url
{
    OFMutableArray* a = [OFMutableArray new];


    void* _pool = objc_autoreleasePoolPush();
    for (OFString* header in headerFields) {
        
        @try {
            OFArray* cookies = [self _parseField:[headerFields objectForKey:header] forHeader:header andURL:url];

            if ([cookies count] >= 1)
                [a addObjectsFromArray:cookies];

        } @catch(id e) {
            objc_autoreleasePoolPop(_pool);
            [a release];
            @throw e;
        }

    }
    objc_autoreleasePoolPop(_pool);

    [a makeImmutable];
    return [a autorelease];

}

+ (OFDictionary *) requestHeaderFieldsWithCookies: (OFArray *)cookies
{
    uint32_t version = 0;
    OFString* field = nil;

    void* _pool =objc_autoreleasePoolPush();

    if ([cookies count] == 0) {
        objc_autoreleasePoolPop(_pool);
        @throw [OFInvalidArgumentException exception];
    }

    version = [(OFHTTPCookie *)[cookies objectAtIndex:0] version];

    if (version)
        field = [@"$Version=\"1\"" autorelease];

    
    OFString* str;
    for (OFHTTPCookie* cookie in cookies) {
        
        str = [OFString stringWithFormat:@"%@=%@", cookie.name, cookie.value];

        if (field)
            field = [field stringByAppendingFormat:@"; %@", str];
        else
            field = str;
        
        if (version && cookie.path)
            field = [field stringByAppendingFormat:@"; $Path=\"%@\"", cookie.path];

        if (version && cookie.domain)
            field = [field stringByAppendingFormat:@"; $Domain=\"%@\"", cookie.domain];
    }

    OFDictionary* cookieField;

    if (version)
        cookieField = [OFDictionary dictionaryWithObject:field forKey:@"Cookie2"];
    else
        cookieField = [OFDictionary dictionaryWithObject:field forKey:@"Cookie"];


    [cookieField retain];
    objc_autoreleasePoolPop(_pool);

    return [cookieField autorelease];

}

+ (OFDictionary OF_GENERIC(OFString *,id) *) responseHeaderFieldsWithCookies: (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies
{
    uint32_t version = 0;
    OFString* field = nil;
    OFString* key = nil;

    void* _pool = objc_autoreleasePoolPush();

    if ([cookies count] == 0) {
        objc_autoreleasePoolPop(_pool);
        @throw [OFInvalidArgumentException exception];
    }

    key = @"Set-Cookie";

    version = [(OFHTTPCookie *)[cookies objectAtIndex:0] version];

    if (version)
        key = @"Set-Cookie2";

    OFString* str;

    for (OFHTTPCookie* cookie in cookies) {

        str = [OFString stringWithFormat:@"%@=%@; Path=%@; Domain=%@", cookie.name, cookie.value, cookie.path, cookie.domain];

        if (cookie.sessionOnly) {
            str = [str stringByAppendingFormat:@"; %s", "Discard"];
        } else {
            OFDictionary* props = cookie.properties;

            if (props[OFHTTPCookieMaximumAge] != nil) {
                str = [str stringByAppendingFormat:@"; Max-Age=%@", props[OFHTTPCookieMaximumAge]];
            } else {
                OFDate* expDate = [cookie.expiresDate autorelease];
                if (expDate != nil)
                    str = [str stringByAppendingFormat:@"; Expires=%@", [expDate dateStringWithFormat: @"%a, %d %b %Y %H:%M:%S GMT"]];
                else
                    str = [str stringByAppendingFormat:@"; %s", "Discard"];
            }

        }

        if (cookie.secure) {
            str = [str stringByAppendingFormat:@"; %s", "Secure"];
        } else {
            if (cookie.HTTPOnly)
                str = [str stringByAppendingFormat:@"; %s", "HttpOnly"];
        }

        if (version) {
            OFArray* ports = [cookie.portList autorelease];

            if ([ports count] > 0)
                str = [str stringByAppendingFormat:@"Port=\""];

            bool oneMore = false;
            for (OFNumber* port in ports) {
                
                if (oneMore)
                    str = [str stringByAppendingFormat:@",%hu", [port unsignedShortValue]];
                else {
                    str = [str stringByAppendingFormat:@"%hu", [port unsignedShortValue]];
                    oneMore = true;
                }
            }

            if ([ports count] > 0)
                str = [str stringByAppendingFormat:@"\""];

            OFString* cookieComment = cookie.comment;
            OFURL* cookieUrlComment = cookie.commentURL;

            if (cookieComment != nil) {
                str = [str stringByAppendingFormat:@"; Comment=%@", cookieComment];
                
            }

            if (cookieUrlComment != nil) {
                str = [str stringByAppendingFormat:@"; CommentURL=%@", [cookieUrlComment string]];
                
            }

            cookieComment = nil;
            cookieUrlComment = nil;

            str = [str stringByAppendingFormat:@"; Version=%d", cookie.version];
        }

        if (field)
            field = [field stringByAppendingFormat:@", %@", str];
        else
            field = str;

        str = nil;

    }

    OFDictionary* cookieField = [OFDictionary dictionaryWithObject:field forKey:key];

    [cookieField retain];
    objc_autoreleasePoolPop(_pool);

    return [cookieField autorelease];
}

- (instancetype)init
{
    self = [super init];

    _properties = nil;

    return self;
}

- (BOOL) _isValidProperty: (OFString *)prop
{
  return ([prop length]
      && [prop rangeOfString: @"\n"].location == OF_NOT_FOUND);
}

- (instancetype)initWithProperties:(OFDictionary *)properties 
{
    if ([self init] == nil)
        return nil;
    void* _pool = objc_autoreleasePoolPush();
    OFMutableDictionary* rawProperties;

    if (![self _isValidProperty: [properties objectForKey: OFHTTPCookiePath]] 
    || ![self _isValidProperty: [properties objectForKey: OFHTTPCookieDomain]]
    || ![self _isValidProperty: [properties objectForKey: OFHTTPCookieName]]
    || ![self _isValidProperty: [properties objectForKey: OFHTTPCookieValue]]
    ) {
        objc_autoreleasePoolPop(_pool);
        [self release];
        @throw [OFInitializationFailedException exceptionWithClass:[OFHTTPCookie class]];
    }

    rawProperties = [[properties mutableCopy] autorelease];
    if ([rawProperties objectForKey:@"Created"] == nil) {
        of_time_interval_t seconds;
        OFDate* now;

        seconds = [[OFDate date] timeIntervalSince1970];
        now = [OFDate dateWithTimeIntervalSince1970:seconds];
        [rawProperties setObject:now forKey:@"Created"];

    }

    _properties = [rawProperties copy];
    objc_autoreleasePoolPop(_pool);

    return self;

}

- (BOOL)isHTTPOnly
{
    
    return (BOOL)[[_properties objectForKey:OFHTTPCookieHTTPOnly] boolValue];
}

- (BOOL)isSecure
{
    
    return (BOOL)[[_properties objectForKey:OFHTTPCookieSecure] boolValue];
}

- (BOOL)isSessionOnly
{
    
    return (BOOL)[[_properties objectForKey:OFHTTPCookieDiscard] boolValue];
}

- (OFString *)comment 
{
    OFString* comment_ = [[_properties objectForKey:OFHTTPCookieComment] copy];
    return [comment_ autorelease];
}

- (OFURL *)commentURL
{
    
    if ([_properties objectForKey:OFHTTPCookieCommentURL]) {
        OFURL* commentURL_ = [[OFURL alloc] initWithString:[_properties objectForKey:OFHTTPCookieCommentURL]];
        return [commentURL_ autorelease];
    }
    else
        return nil;
}

- (OFString *)name
{
    OFString* name_ = [[_properties objectForKey:OFHTTPCookieName] copy];
    return [name_ autorelease];
}

- (OFString *)domain 
{
    
    OFString* domain_ = [[_properties objectForKey:OFHTTPCookieDomain] copy];
    return [domain_ autorelease];
}

- (OFDate *)expiresDate 
{
    OFDate* expiresDate_ = [[_properties objectForKey:OFHTTPCookieExpires] copy];
    return [expiresDate_ autorelease];
}

- (OFString *)path
{
    OFString* path_ = [[_properties objectForKey:OFHTTPCookiePath] copy];
    return [path_ autorelease];
}

- (OFArray *)portList
{
    void* _pool = objc_autoreleasePoolPush();
    OFArray* strPortList = [[_properties objectForKey:OFHTTPCookiePort] componentsSeparatedByString:@","];
    OFMutableArray* numPortList = [OFMutableArray array];
    
    for (OFString* port in strPortList) {
        @try {
            [numPortList addObject:[OFNumber numberWithUnsignedShort:(unsigned short)[port decimalValue]]];
        }@catch(id e) {}
    }

    [numPortList makeImmutable];

    [numPortList retain];
    objc_autoreleasePoolPop(_pool);
    
    return [numPortList autorelease];
}

- (OFDictionary *)properties 
{
    OFDictionary* properties_ = [_properties copy];
    return [properties_ autorelease];
}

- (OFString *)value 
{
    
    OFString* value_ = [[_properties objectForKey:OFHTTPCookieValue] copy];

    return [value_ autorelease];
}

- (uint32_t)version 
{
    
    return (uint32_t)[[_properties objectForKey:OFHTTPCookieVersion] decimalValue];
}

- (id)copy
{
    return [[OFHTTPCookie alloc] initWithProperties:_properties];
}

- (OFString *)description 
{
    return [OFString stringWithFormat: @"<OFHTTPCookie %p: %@=%@>", self,
           [self name], [self value]];
}

- (uint32_t)hash 
{
    return [[self properties] hash];
}

- (bool)isEqual:(id)other 
{
    if ([other isKindOfClass:[self class]]) {
        return [[other properties] isEqual:[self properties]];
    }

    return false;
}

- (void)dealloc 
{
    [_properties release];
    [super dealloc];
}

@end