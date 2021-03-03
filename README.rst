=======================
Sailfish SDK Test Suite
=======================
-----------------------------
Utilizing The Robot Framework
-----------------------------

This test suite automates Sailfish SDK testing with the help of Robot Framework.

- http://robotframework.org/


Environment preparation - Linux
===============================

1. Install Robot Framework with Python PIP::

     pip3 install --user robotframework

This will install the Robot Framework executables under ``~/.local/bin/``. The rest of this guide assumes those executables are available in ``PATH``.

Environment preparation - OS X
==============================

TBD


Environment preparation - MS Windows
====================================

TBD


Running the test suite
======================

After cloning the Git repository containing this test suite, ensure that all submodules are populated and up to date::

  git submodule update --init --recursive

If needed, prepare a wrapper script that hides any environment-specific aspects of installer invocation, like adding local repositories:

::

   #!/bin/bash
   installer=$HOME/installers/SailfishSDK-1.2.3-offline.run
   repo=$installer.repo
   # QTIFW-911
   export TMPDIR=$HOME/tmp
   exec "$installer" --addRepository "file://$repo/commmon/,file://$repo/linux-64/" "$@"

Create a working directory for this test run, enter it and configure the test suite - point it to
the installer executable/wrapper (run `configure` with  `--help` to learn about available options):

::

   mkdir sdk-test-suite.out && cd sdk-test-suite.out
   ../path/to/sdk-test-suite/configure ../path/to/installer.run

Run the test suite::

   robot ../path/to/sdk-test-suite

Open test report::

  xdg-open report.html


Test case tags
==============

interactive
  User interaction is required during test case execution

needs-gui
  Headless execution of a test case is not possible


Development environment setup
=============================


Eclipse with RED plugin
-----------------------

- https://github.com/nokia/RED

Install inside Eclipse via ``Help > Eclipse Marketplace...``, seach for RED.
