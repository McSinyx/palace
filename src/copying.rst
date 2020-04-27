Copying
=======

License
-------
Palace is free software: you can redistribute it and/or modify it
under the terms of the `GNU Lesser General Public License`_
as published by the Free Software Foundation, either version 3
of the License, or (at your option) any later version.

.. _GNU Lesser General Public License:
   https://www.gnu.org/licenses/lgpl-3.0.en.html

Credits
-------

To ensure that palace can run without any dependencies outside of the `pip`_
toolchain, the wheels are bundled with dynamically linked libraries from
the build machine, which is similar to static linking:

==============  ============
Library         License
==============  ============
`Alure`_        ZLib
`OpenAL Soft`_  GNU LGPLv2+
`Vorbis`_       3-clause BSD
`Opus`_         3-clause BSD
`libsndfile`_   GNU LGPL2.1+
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
