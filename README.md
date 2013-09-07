Lolita - The Purest C Mini Framework 4 MMO
==========================================

Lolita is a portable, pure c, mini framework mainly for MMO development.

Lolita can be used as a independent host program OR a plugin for Lua enviroment.

Dependency
==========================================

* premake4.4
* lua5.1.4(included)
* lua5.2.1(included)
* lua5.2.2(included,default)

Modules Exported
================

* core.base
* core.arg
* core.info
* core.os
* core.net

Building - Using Premake4.4
===========================

    $ premake4 premake
    $ premake4 make
    $ premake4 deploy

Usage
=====
used as a independent program

    $ cd _deploy
    $ export LD_LIBRARY_PATH=.
    $ export DYLD_LIBRARY_PATH=.
    $ ./lolita exts=../sample/echo bsrv=1 maxconnection=1024 &
    $ ./lolita exts=../sample/echo maxconnection=1025 &
    
used as a plugin for Lua

    require("lolitaext")
