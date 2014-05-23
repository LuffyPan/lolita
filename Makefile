.PHONY : mingw lolita linux undefined

COREPATH = src/core
LUAPATH = deps/lua-5.2.3/src
CFLAGS = -g -Wall -I$(COREPATH) -D LOLITA_CORE_GITVER=\"$(GITVER)\"
LDFLAGS :=

CORESRC := \
$(COREPATH)/co.c \
$(COREPATH)/comm.c \
$(COREPATH)/cort.c \
$(COREPATH)/compat.c \
$(COREPATH)/coos.c \
$(COREPATH)/conet.c \
$(COREPATH)/comain.c

LUASRC := \
$(LUAPATH)/lapi.c \
$(LUAPATH)/lauxlib.c \
$(LUAPATH)/lbaselib.c \
$(LUAPATH)/lbitlib.c \
$(LUAPATH)/lcode.c \
$(LUAPATH)/lcorolib.c \
$(LUAPATH)/lctype.c \
$(LUAPATH)/ldblib.c \
$(LUAPATH)/ldebug.c \
$(LUAPATH)/ldo.c \
$(LUAPATH)/ldump.c \
$(LUAPATH)/lfunc.c \
$(LUAPATH)/lgc.c \
$(LUAPATH)/linit.c \
$(LUAPATH)/liolib.c \
$(LUAPATH)/llex.c \
$(LUAPATH)/lmathlib.c \
$(LUAPATH)/lmem.c \
$(LUAPATH)/loadlib.c \
$(LUAPATH)/lobject.c \
$(LUAPATH)/lopcodes.c \
$(LUAPATH)/loslib.c \
$(LUAPATH)/lparser.c \
$(LUAPATH)/lstate.c \
$(LUAPATH)/lstring.c \
$(LUAPATH)/lstrlib.c \
$(LUAPATH)/ltable.c \
$(LUAPATH)/ltablib.c \
$(LUAPATH)/ltm.c \
$(LUAPATH)/lundump.c \
$(LUAPATH)/lvm.c \
$(LUAPATH)/lzio.c

UNAME=$(shell uname)
SYS=$(if $(filter Linux%,$(UNAME)),linux,\
	    $(if $(filter MINGW%,$(UNAME)),mingw,\
	    $(if $(filter Darwin%,$(UNAME)),macosx,\
	        undefined\
)))

GITVER=$(shell git describe --dirty)

ifdef LUAJIT
CFLAGS += $(shell pkg-config --cflags luajit) -D LOLITA_CORE_LUAJIT
LDFLAGS += $(shell pkg-config --libs luajit)
LUASRC :=
else
CFLAGS += -I$(LUAPATH)
endif

all: $(SYS)

undefined:
	@echo "I can't guess your platform, please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "      linux mingw macosx"


mingw : TARGET := lolita.exe
mingw : LDFLAGS += -lws2_32 -lole32

mingw : $(SRC) lolita

linux : TARGET := lolita
linux : CFLAGS += -I/usr/include -D LUA_USE_LINUX
linux : LDFLAGS += -lm -ldl

linux : $(SRC) lolita

macosx : TARGET := lolita
macosx : CFLAGS += -I/usr/include -D LUA_USE_MACOSX
macosx : LDFLAGS += -lm -ldl

macosx : $(SRC) lolita

lolita :
	gcc $(CFLAGS) -o $(TARGET) $(CORESRC) $(LUASRC) $(LDFLAGS)

clean :
	-rm -f lolita.exe
	-rm -f lolita
