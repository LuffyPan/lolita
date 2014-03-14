Lolita - The Purest C Mini Framework 4 MMO
==========================================

Lolita is a portable, pure c, mini framework mainly for MMO development.

Lolita can be used as a independent host program OR a plugin for Lua enviroment.

Dependency
==========================================

* Premake4.4
* Lua5.2.3(included)

Modules Exported
================

* core.conf
* core.base
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
    $ ./lolita x=../test/config_server
    $ ./lolita x=../test/config_client
    
used as a plugin for Lua

    require("lolitaext")
