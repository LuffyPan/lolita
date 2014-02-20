Lolita - The Purest C Mini Framework 4 MMO
==========================================

Lolita is a portable, pure c, mini framework mainly for MMO development.

Lolita can be used as a independent host program OR a plugin for Lua enviroment.

Dependency
==========================================

* Premake4.4
* Lua5.2.3(included as submodule)

Modules Exported
================

* core.base
* core.arg
* core.info
* core.os
* core.net

Building - Using Premake4.4
===========================

    $ git submodule init
    $ git submodule update
    $ premake4 premake
    $ premake4 make
    $ premake4 deploy

Usage
=====
used as a independent program

    $ cd _deploy
    $ ./lolita X=../test/config_server
    $ ./lolita X=../test/config_client
    
used as a plugin for Lua

    require("lolitaext")
