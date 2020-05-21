Overview
========

Pythonic Audio Library and Codecs Environment provides common higher-level API
for audio rendering using OpenAL:

* 3D positional rendering, with HRTF_ support for stereo systems
* Environmental effects: reverb, atmospheric air absorption,
  sound occlusion and obstruction
* Out-of-the-box codec support:

Palace wraps around the C++ interface alure_ using Cython_ for a safe and
convenient interface with type hinting, data descriptors and context managers,
following :pep:`8#naming-conventions` (``PascalCase.snake_case``).

Table of Contents
-----------------

.. toctree::
   :maxdepth: 2

   installation
   tutorial/index
   reference/index
   design
   contributing
   copying

Indices and Tables
------------------

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`

.. _HRTF: https://en.wikipedia.org/wiki/Head-related_transfer_function
.. _alure: https://github.com/kcat/alure
.. _Cython: https://cython.org
