#import <ObjFW/ObjFW.h>
#import "OFLogger.h"

static OFLogger* _defaultLogger = nil;
static OFThread* _defaultWorkingThread = nil;

@interface OFLogger()

@property (nonatomic, assign) OFThread* workingThread;

- (instancetype)_init;

@end

static of_once_t _default_logger_init_control = 0;
static of_once_t _init_working_thread_control = 0;

static void _initDefaultLogger(void) {
    _defaultLogger = [[OFLogger alloc] _init];
}

static void _initDefaultWorkingThread(void) {
    _defaultWorkingThread = [[OFThread alloc] init];
}


@implementation OFLogger{

    OFThread* _workingThread;

}

@synthesize workingThread = _workingThread;

+ (void)initialize
{
    if (self == [OFLogger class]) {
        of_once(&_default_logger_init_control, &_initDefaultLogger);

        if (_defaultLogger == nil)
            @throw [OFInitializationFailedException exceptionWithClass:self];
    }
}

+ (OFLogger * _Nonnull)defaultLogger
{
    return _defaultLogger;
}

- (instancetype)init
{
    OF_UNRECOGNIZED_SELECTOR
}

- (instancetype)_init
{
    self = [super init];

    of_once(&_init_working_thread_control, _initDefaultWorkingThread);

    self.workingThread = _defaultWorkingThread;

    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)start
{
    @synchronized (self) {
        OFRunLoop* workingRunloop = self.workingThread.runLoop;

        @autoreleasepool {
            [workingRunloop addTimer:[OFTimer timerWithTimeInterval:0.0 repeats:true block:^(OFTimer * _Nonnull workingTimer){

            }]];
        }
    }
}

- (void)stop
{

}

@end
