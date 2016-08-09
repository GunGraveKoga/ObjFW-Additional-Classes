#import <ObjFW/ObjFW.h>
#import "OFProcess+ExitCode.h"


@implementation OFProcess (ExitCode)

- (int)exitCode
{
	#if defined(OF_WINDOWS)
	DWORD code_ = 0;
	int res = 0;

	while ((res = GetExitCodeProcess(self->_process, &code_)) != 0) {
		if (code_ == 259)
			continue;

		CloseHandle(self->_process);

		break;
	}
	if (res != 0)
		return (int)code_;

	return -1;
	#else
		int status = 0;
		int endID = 0;

		do {

			if ((endID = waitpid(self->_pid, &status, WNOHANG|WUNTRACED)) == -1)
				return -1;

			if (endID == 0) {
				[OFThread sleepForTimeInterval:0.5];
				continue;
			}

			if (endID == self->_pid) {
				if (WIFEXITED(status))
					return WEXITSTATUS(status);

				return 1;
			}


		} while(true);
	#endif

		return 1;
}

@end