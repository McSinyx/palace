Installation
============

Prerequisites
-------------

Palace requires Python 3.6 for runtime and pip for installation.

Via PyPI
--------

Palace can be installed from PyPI:

.. code-block:: sh

   pip install palace

Wheel distributions are only built for GNU/Linux and macOS on amd64
at the time of writing.

However, the wheels for macOS does *not* include shared libraries like alure,
which are expected to be installed either from source or from Homebrew.
This is because we cannot (yet) get ``delocate`` to worked with alure
compiled from source, which showed up to be inside of ``@rpath``.

From source
-----------

Aside from the build dependencies listed in ``pyproject.toml``,
one will additionally need compatible Python headers, alure, a C++14 compiler,
CMake 2.6+ (and git for fetching the source).  Palace can then be compiled
and installed by running:

.. code-block:: sh

   git clone https://github.com/McSinyx/palace.git
   pip install palace/
