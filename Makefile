project_dir := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
current_dir := $(notdir $(patsubst %/,%,$(dir $(project_dir))))
build_dir=$(project_dir)build
system := $(shell uname -s)
proc := $(shell uname -m)

BUILD_SYS=EMPTY
BUILD_PLATFORM=UNKNOWN
ifeq ($(filter MINGW32,$(system)),)
BUILD_SYS=MINGW32
BUILD_PLATFORM=w64-mingw32
else
ifeq ($(system),Linux)
BUILD_SYS=LINUX
BUILD_PLATFORM=linux
endif
ifeq ($(system),Darwin)
BUILD_SYS=DARWIN
BUILD_PLATFORM=darwin
endif
endif

OBJF_EXT_SOURCES = OFDataArray+WITHBYTES.m \
					OFString+libiconv.m \
					OFError.m \
					OFHTTPCookie.m \
					OFMD2Hash.m \
					OFMD4Hash.m \
					OFProcessInfo.m \
					OFUUID.m \
					OFUniversalException.m

OBJF_EXT_OBJS = OFDataArray+WITHBYTES.lib.o \
					OFString+libiconv.lib.o \
					OFError.lib.o \
					OFHTTPCookie.lib.o \
					OFMD2Hash.lib.o \
					OFMD4Hash.lib.o \
					OFProcessInfo.lib.o \
					OFUUID.lib.o \
					OFUniversalException.lib.o

OBJF_EXT_OBJS_LIST := $(addprefix $(build_dir)/,$(OBJF_EXT_OBJS))

OBJF_EXT_PUBLIC_HEADERS = ObjFWExt.h objfwext_macros.h \
						  OFDataArray+WITHBYTES.h \
						  OFString+libiconv.h \
						  OFError.h \
						  OFHTTPCookie.h \
						  OFMD2Hash.h \
						  OFMD4Hash.h \
						  OFUUID.h \
						  OFUniversalException.h \
						  OFProcessInfo.h 

CC=$(proc)-$(BUILD_PLATFORM)-objfw-compile
CHDIR=cd
MKDIR=mkdir
MOVE=mv
COPY=cp
DELETE=rm -rf
AR=ar

OBJF_EXT=objfw_ext

SHARED_LIBRARY_EXTENSION=

ifeq ($(BUILD_SYS), MINGW32)
SHARED_LIBRARY_EXTENSION=.dll
endif

ifeq ($(BUILD_SYS), DARWIN)
SHARED_LIBRARY_EXTENSION=.dylib
endif

ifeq ($(BUILD_SYS), LINUX)
SHARED_LIBRARY_EXTENSION=.so
endif

ifeq ($(BUILD_SYS), EMPTY)
$(error Unsuported OS $(system))
endif

STATIC_LIBRARY_EXTENSION=.a
LIBRARY_PREFIX=lib

bindir = bin

includedir = include/ObjFWExt

libdir = lib

OBJF_EXT_LIB=$(LIBRARY_PREFIX)$(OBJF_EXT)$(SHARED_LIBRARY_EXTENSION)

MOVE_EXPORT_LIB=echo
COPY_EXPORT_LIB=echo

ifeq ($(BUILD_SYS), MINGW32)
OBJF_EXT_LIB_EXPORT=$(LIBRARY_PREFIX)$(OBJF_EXT)$(SHARED_LIBRARY_EXTENSION)$(STATIC_LIBRARY_EXTENSION)
MOVE_EXPORT_LIB = $(MOVE) $(OBJF_EXT_LIB_EXPORT) $(build_dir)
COPY_EXPORT_LIB=$(COPY) $(build_dir)/$(OBJF_EXT_LIB_EXPORT) $(DESTDIR)/$(libdir)/
endif



.SILENT:

.PHONY: all clean install

all: $(build_dir)/$(OBJF_EXT_LIB)

$(build_dir)/$(OBJF_EXT_LIB): $(OBJF_EXT)

$(OBJF_EXT): $(OBJF_EXT_OBJS_LIST)

$(OBJF_EXT_OBJS_LIST): $(OBJF_EXT_SOURCES)
	echo -e "\e[1;34mBuilding $(OBJF_EXT_LIB)...\e[0m"
	$(CC) --builddir $(build_dir) $(OBJF_EXT_SOURCES) -I. -o $(OBJF_EXT) -liconv --lib 0.9 && \
	$(MOVE) $(OBJF_EXT_LIB) $(build_dir)
	$(MOVE_EXPORT_LIB)
	echo -e "\e[1;34mDone.\e[0m"

clean:
	$(DELETE) $(build_dir)/*.o
	$(DELETE) $(build_dir)/*.a
	$(DELETE) $(build_dir)/*.dll
	$(DELETE) $(build_dir)/*.exe
	echo -e "\e[1;34mAll clean.\e[0m"

install:
	echo -e "\e[1;34mCreating $(DESTDIR).\e[0m"
	if test -d $(DESTDIR); then \
		echo -e "\e[1;34mExist.\e[0m"; \
	else \
		$(MKDIR) $(DESTDIR); \
	fi
	echo -e "\e[1;34mCreating $(DESTDIR)/$(bindir).\e[0m"
	if test -d $(DESTDIR)/$(bindir); then \
		echo -e "\e[1;34mExist.\e[0m"; \
	else \
		$(MKDIR) $(DESTDIR)/$(bindir); \
	fi
	echo -e "\e[1;34mCreating $(DESTDIR)/$(includedir).\e[0m"
	if test -d $(DESTDIR)/$(includedir); then \
		echo -e "\e[1;34mExist.\e[0m"; \
	else \
		$(MKDIR) $(DESTDIR)/$(includedir); \
	fi
	echo -e "\e[1;34mInstalling $(OBJF_EXT_LIB)...\e[0m"
	$(COPY) $(build_dir)/$(OBJF_EXT_LIB) $(DESTDIR)/$(bindir)/
	$(COPY_EXPORT_LIB)
	echo -e "\e[1;34mDone.\e[0m"
	for header in $(OBJF_EXT_PUBLIC_HEADERS); do \
		echo -e "\e[1;34mInstalling $$header...\e[0m"; \
		$(COPY) $$header $(DESTDIR)/$(includedir)/; \
		echo -e "\e[1;34mDone.\e[0m"; \
	done