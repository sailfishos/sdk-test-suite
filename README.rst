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

Start by ensuring that the SDK metadata recorded in ``config.py`` match the SDK version under test and that ``INSTALLER`` points to the correct installer executable or its wrapper that hides any environment-specific aspects of its invocation, like adding local repositories:

::

   #!/bin/bash
   installer=$HOME/installers/SailfishSDK-1.2.3-offline.run
   repo=$installer.repo
   # QTIFW-911
   export TMPDIR=$HOME/tmp
   exec "$installer" --addRepository "file://$repo/commmon/,file://$repo/linux-64/" "$@"

By default the installer executable (or its wrapper) is expected to exist as ``SailfishSDK-installer.run`` in the parent directory of the robot execution directory.

Run the test suite:

::

   mkdir sdk-test-suite.out && cd sdk-test-suite.out
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
