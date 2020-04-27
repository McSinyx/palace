Installation
============

Prerequisites
-------------

Palace requires Python 3.6 for runtime and `pip`_ for installation.

.. _pip: https://pip.pypa.io/en/latest/

Via PyPI
--------

Palace can be installed from PyPI::

   pip install palace

Wheel distributions are built exclusively for amd64.  Currently, only GNU/Linux
is properly supported.  If you want to help packaging for Windows and macOS,
see `GH-1`_ and `GH-63`_ respectively on our issues tracker on GitHub.

.. _GH-1: https://github.com/McSinyx/palace/issues/1
.. _GH-63: https://github.com/McSinyx/palace/issues/63

From source
-----------

Aside from the build dependencies listed in ``pyproject.toml``,
one will additionally need compatible Python headers, `alure`_,
a C++14 compiler, CMake 2.6+ (and probably ``git`` for fetching the source).
Palace can then be compiled and installed by running:

.. code-block:: sh

   git clone https://github.com/McSinyx/palace.git
   pip install palace/

.. _alure: https://github.com/kcat/alure
