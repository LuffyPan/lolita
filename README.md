Lolita - The Purest C Mini Framework 4 MMO
==========================================

Lolita is a portable, pure c, mini framework mainly for MMO development.

Lolita can be used as a independent host program OR a plugin for Lua enviroment.

Make
===========================

If you are lucky enough, You don't need to install **uuid-dev**, **pkg-config**, **luajit**.. by yourself!

If you wanna use **luajit**. **LUAJIT=1** should be add as Makefile's parameter

Linux, Mac OS(GCC)

* make
* ./lolita x=test/config_server

Windows(Mingw32)

* make(mingw32-make) or make(mingw32-make) mingw
* lolita x=test/config_server

Windows(MSVC), Mac OS(Xcode)

* install [premake4](http://industriousone.com/premake/download)
* premake4 xxxx (xxx = vs2002, vs2005, vs2008, vs2010, vs2012, xcode3, xcode4)
