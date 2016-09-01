#ifdef __cplusplus
#define OBJFW_EXTENSION_EXPORT extern "C"
#else
#define OBJFW_EXTENSION_EXPORT extern
#endif

// Enums and Options
#if (__cplusplus && __cplusplus >= 201103L && (__has_extension(cxx_strong_enums) || __has_feature(objc_fixed_enum))) || (!__cplusplus && __has_feature(objc_fixed_enum))
  #define OF_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
  #if (__cplusplus)
    #define OF_OPTIONS(_type, _name) _type _name; enum : _type
  #else
    #define OF_OPTIONS(_type, _name) enum _name : _type _name; enum _name : _type
  #endif
#else
  #define OF_ENUM(_type, _name) _type _name; enum
  #define OF_OPTIONS(_type, _name) _type _name; enum
#endif
