lolita - The Purest C Mini Framework 4 MMO
==========================================

lolita is a portable, pure c, mini framework mainly for MMO development.

lolita can be used as a independent host program OR a plugin for Lua enviroment.

Dependcy
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
    $ ./lolita corext=path2lolitax/cox.lua avatar=path2avatar/av.lua
    
used as a plugin for Lua

    require("lolitaext")