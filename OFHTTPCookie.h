#import <ObjFW/OFObject.h>
@class OFArray;
@class OFDictionary;
@class OFDate;
@class OFURL;
@class OFString;


extern OFString * const OFHTTPCookieComment; /** Obtain text of the comment */
extern OFString * const OFHTTPCookieCommentURL; /** Obtain the comment URL */
extern OFString * const OFHTTPCookieDiscard; /** Obtain the sessions discard setting */
extern OFString * const OFHTTPCookieDomain; /** Obtain cookie domain */
extern OFString * const OFHTTPCookieExpires; /** Obtain cookie expiry date */
extern OFString * const OFHTTPCookieMaximumAge; /** Obtain maximum age (expiry) */
extern OFString * const OFHTTPCookieName; /** Obtain name of cookie */
extern OFString * const OFHTTPCookieOriginURL; /** Obtain cookie origin URL */
extern OFString * const OFHTTPCookiePath; /** Obtain cookie path */
extern OFString * const OFHTTPCookiePort; /** Obtain cookie ports */
extern OFString * const OFHTTPCookieSecure; /** Obtain cookie security */
extern OFString * const OFHTTPCookieHTTPOnly; /** Obtain cookie httponly */
extern OFString * const OFHTTPCookieValue; /** Obtain value of cookie */
extern OFString * const OFHTTPCookieVersion; /** Obtain cookie version */

@interface OFHTTPCookie: OFObject<OFCopying>

@property(readonly, copy) OFString *comment;
@property(readonly, copy) OFURL *commentURL;
@property(readonly, copy) OFString *domain;
@property(readonly, copy) OFDate *expiresDate;
@property(readonly, getter=isHTTPOnly) BOOL HTTPOnly;
@property(readonly, getter=isSecure) BOOL secure;
@property(readonly, getter=isSessionOnly) BOOL sessionOnly;
@property(readonly, copy) OFString *name;
@property(readonly, copy) OFString *path;
@property(readonly, copy) OFArray OF_GENERIC(OFNumber *) *portList;
@property(readonly, copy) OFDictionary OF_GENERIC(OFString *,id) *properties;
@property(readonly, copy) OFString *value;
@property(readonly) uint32_t version;

+ (instancetype) cookieWithProperties: (OFDictionary *)properties;
+ (OFDictionary OF_GENERIC(OFString *,id) *) requestHeaderFieldsWithCookies: (OFArray OF_GENERIC(OFHTTPCookie *) *)cookies;
+ (OFArray OF_GENERIC(OFHTTPCookie *) *) cookiesWithResponseHeaderFields: (OFDictionary OF_GENERIC(OFString *,id) *)headerFields forURL: (OFURL *)url;
- (instancetype) initWithProperties: (OFDictionary *)properties;

@end