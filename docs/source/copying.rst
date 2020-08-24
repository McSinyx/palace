Copying
=======

This listing is our best-faith, hard-work effort at accurate attribution,
sources, and licenses for everything in palace.  If you discover
an asset/contribution that is incorrectly attributed or licensed,
please contact us immediately.  We are happy to do everything we can
to fix or remove the issue.

License
-------

Palace is free software: you can redistribute it and/or modify it
under the terms of the `GNU Lesser General Public License`_
as published by the Free Software Foundation, either version 3
of the License, or (at your option) any later version.

To ensure that palace can run without any dependencies outside of the pip_
toolchain, the wheels are bundled with dynamically linked libraries from
the build machine, which is similar to static linking:

==============  ============
Library         License
==============  ============
Alure_          ZLib
`OpenAL Soft`_  GNU LGPLv2+
Vorbis_         3-clause BSD
Opus_           3-clause BSD
libsndfile_     GNU LGPL2.1+
==============  ============

In addition, the following sounds are used for testing:

===============================================  =========
Sound (located in ``tests/data``)                License
===============================================  =========
`164957__zonkmachine__white-noise.ogg`_          CC0 1.0
`24741__tim-kahn__b23-c1-raw.aiff`_              CC BY 3.0
`261590__kwahmah-02__little-glitch.flac`_        CC BY 3.0
`353684__tec-studio__drip2.mp3`_                 CC0 1.0
`99642__jobro__deconvoluted-20hz-to-20khz.wav`_  CC BY 3.0
===============================================  =========

Credits
-------

Palace would never have seen the light of day without the help from
the developers of Alure_ and Cython_ who promptly gave detail answers
and made quick fixes to all of our problems.

The wheels are build using cibuildwheel_, which made building extension modules
much less of a painful experience.  `Travis CI`_ and AppVeyor_ kindly provides
their services free of charge for automated CI/CD.

This documentation is generated using Sphinx_, whose maintainer responses
extreamly quickly to obsolete Cython-related issues.

.. _GNU Lesser General Public License:
   https://www.gnu.org/licenses/lgpl-3.0.en.html
.. _pip: https://pip.pypa.io/en/latest/
.. _Alure: https://github.com/kcat/alure
.. _OpenAL Soft: https://kcat.strangesoft.net/openal.html
.. _Vorbis: https://xiph.org/vorbis/
.. _Opus: https://opus-codec.org/
.. _libsndfile: http://www.mega-nerd.com/libsndfile/
.. _164957__zonkmachine__white-noise.ogg: https://freesound.org/s/164957/
.. _24741__tim-kahn__b23-c1-raw.aiff: https://freesound.org/s/24741/
.. _261590__kwahmah-02__little-glitch.flac: https://freesound.org/s/261590/
.. _353684__tec-studio__drip2.mp3: https://freesound.org/s/353684/
.. _99642__jobro__deconvoluted-20hz-to-20khz.wav: https://freesound.org/s/99642/
.. _Cython: https://cython.org/
.. _cibuildwheel: https://cibuildwheel.readthedocs.io/en/stable/
.. _Sphinx: https://www.sphinx-doc.org/en/master/
.. _Travis CI: https://travis-ci.com/
.. _AppVeyor: https://www.appveyor.com/
