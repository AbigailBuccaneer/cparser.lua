## LuaUnit  
	by Philippe Fremy

[![Build status](https://ci.appveyor.com/api/projects/status/us6uh4e5q597jj54?svg=true&passingText=Windows%20Build%20passing&failingText=Windows%20Build%20failed)](https://ci.appveyor.com/project/bluebird75/luaunit)
[![Build Status](https://travis-ci.org/bluebird75/luaunit.svg?branch=master)](https://travis-ci.org/bluebird75/luaunit)
[![Documentation Status](https://readthedocs.org/projects/luaunit/badge/?version=latest)](https://readthedocs.org/projects/luaunit/?badge=latest)

Luaunit is a unit-testing framework for Lua. It allows you 
to write test functions and test classes with test methods, combined with 
setup/teardown functionality. A wide range of assertions are supported.

Luaunit supports several output format, like Junit or TAP, for easier integration
into Continuous Integration platforms (Jenkins, Maven, ...) . The integrated command-line 
options provide a flexible interface to select tests by name or patterns, control output 
format, set verbosity, ...

LuaUnit works with Lua 5.1, 5.2 and 5.3 . It was tested on Windows XP, Windows Server 2012 R2 (x64) and Ubuntu 14.04 (see 
continuous build results on [Travis-CI](https://travis-ci.org/bluebird75/luaunit) and [AppVeyor](https://ci.appveyor.com/project/bluebird75/luaunit) ) and should work on all platforms supported by lua.
It has no other dependency than lua itself. 

LuaUnit is packed into a single-file. To make start using it, just add the file to your project.

LuaUnit is maintained on github:
https://github.com/bluebird75/luaunit

For more information on LuaUnit development, please check: [Developing LuaUnit](http://luaunit.readthedocs.org/en/latest/#developing-luaunit)

It is released under the BSD license.

Documentation is available on
[read-the-docs](http://luaunit.readthedocs.org/en/latest/)

##Install

The version of this module available from LuaRocks is quite
outdated. Most of the stuff does not work, specially the examples. You
can download this repo via

	git clone git@github.com:bluebird75/luaunit.git

and then install it by copying `luaunit.lua` to the Lua libs directory
or run, if you have the default installation, 

	sudo python doit.py install

Edit `install()` for Lua version and installation directory if that
fails. It uses, by default, Linux paths that depend on the version. 

**Community**

LuaUnit has a mailing list with low activity (a few emails per months). To subscribe or read the archives, please go to: [LuaUnit Mailing-list](http://lists.freehackers.org/list/luaunit%40freehackers.org/). If you are using LuaUnit, please drop us a note, we are always happy to hear from new users.

### History 

#### Version 3.2
* lua 5.3 and luajit (1, 2.0, 2.1) support, validated on Travis CI

#### Version 3.1 - 10 Mar. 2015
* luaunit no longer pollutes global namespace, unless defining EXPORT_ASSERT_TO_GLOBALS to true
* fixes and validation of JUnit XML generation
* strip luaunit internal information from stacktrace
* general improvements of test results with duration and other details
* improve printing for tables, with an option to always print table id
* fix printing of recursive tables 

**Important note when upgrading to version 3.1** : assertions functions are
no longer exported directly to the global namespace. See documentation for upgrade
paths.

#### Version 3.0 - 9. Oct 2014

Since some people have forked LuaUnit and release some 2.x version, I am
jumping the version number.

- moved to Github
- full documentation available in text, html and pdf at read-the-docs.org
- new output format: JUnit
- much better table assertions
- new assertions for strings, with patterns and case insensitivity: assertStrContains, 
  assertNotStrContains, assertNotStrIContains, assertStrIContains, assertStrMatches
- new assertions for floats: assertAlmostEquals, assertNotAlmostEquals
- type assertions: assertIsString, assertIsNumber, ...
- error assertions: assertErrorMsgEquals, assertErrorMsgContains, assertErrorMsgMatches
- improved error messages for several assertions
- command-line options to select test, control output type and verbosity

#### Version 2.0
Unofficial fork from version 1.3
- lua 5.2 module style, without global namespace pollution
- setUp() may be named Setup() or setup()
- tearDown() may be named Teardown() or teardown()
- wrapFunction() may be called WrapFunctions() or wrap_functions()
- run() may also be called Run()
- table deep comparision (also available in 1.4)
- control verbosity with setVerbosity() SetVerbosity() and set_verbosity()

#### Version 1.5 - 8. Nov 2012
- compatibility with Lua 5.1 and 5.2
- better object model internally
- a lot more of internal tests
- several internal bug fixes
- make it easy to customize the test output
- running test functions no longer requires a wrapper
- several level of verbosity


#### Version 1.4 - 26. Jul 2012
- switch from X11 to more popular BSD license
- add TAP output format for integration into Jenkins
- official repository now on github


#### Version 1.3 - 30. Oct 2007
- port to lua 5.1
- iterate over the test classes, methods and functions in the alphabetical order
- change the default order of expected, actual in assertEquals (adjustable with USE_EXPECTED_ACTUAL_IN_ASSERT_EQUALS).


#### Version 1.2 - 13. Jun 2005  
- first public release


#### Version 1.1
- move global variables to internal variables
- assertion order is configurable between expected/actual or actual/expected
- new assertion to check that a function call returns an error
- display the calling stack when an error is spotted
- two verbosity level, like in python unittest

