Installation
============

Prerequisites
-------------

Palace requires Python 3.6 for runtime and pip_ for installation.

Via PyPI
--------

Palace can be installed from PyPI::

   pip install palace

Wheel distributions are built exclusively for amd64.  Currently, only GNU/Linux
and macOS are properly supported. If you want to help packaging for Windows,
please see `GH-1`_ on our issues tracker on GitHub.

From source
-----------

Aside from the build dependencies listed in ``pyproject.toml``,
one will additionally need compatible Python headers, alure_,
a C++14 compiler, CMake 2.6+ (and probably ``git`` for fetching the source).
Palace can then be compiled and installed by running::

   git clone https://github.com/McSinyx/palace.git
   pip install palace/

.. _pip: https://pip.pypa.io/en/latest/
.. _GH-1: https://github.com/McSinyx/palace/issues/1
.. _alure: https://github.com/kcat/alure
