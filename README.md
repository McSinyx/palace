# palace
Palace is a Python 3D audio API wrapping around [alure].
To quote alure's README,

> It uses OpenAL for audio rendering, and provides common higher-level features
> such as file loading and decoding, buffer caching, background streaming,
> and source management for virtually unlimited sound source handles.

## Features
In some sense, what palace aimes to be to OpenAL is what [ModernGL]
is to OpenGL (except that all the heavy-lifting are taken are by alure):

* 3D sound rendering
* Environmental audio effects: reverb, atmospheric air absorption,
  sound occlusion and obstruction
* Binaural (HRTF) rendering
* Out-of-the-box audio decoding of FLAC, MP3, Ogg Vorbis, Opus, WAV, AIFF, etc.
* Modern Pythonic API: snake_case, `@property`, `with` context manager,
  type annotation

## Installation
### Prerequisites
Palace runtime only depends on [alure] and Python 3.6+.
`pip` is required for installation.

### Via PyPI
Wheel distribution is not yet ready at the time of writing.  If you want to
help out, please head to our GitHub issues [#1][GH-1] and [#3][GH-3].

### From source
Aside from the build dependencies listed in `pyproject.toml`, one will
additionally need compatible Python headers and a C++11 compiler (and probably
`git` for fetching the source).  Palace can then be compiled and installed
by running
```sh
git clone https://github.com/McSinyx/palace
pip install palace/
```

## Usage
One may start with the `examples` for sample usage of palace.
For further information, Python's `help` is your friend.

## License and Credits
Palace is released under the [GNU LGPL version 3 or later][LGPLv3+].

The [`cmake` modules are provided by scikit-build][sk-cmake], which is
originally released under the [MIT and 2-clause BSD][sk-license] licence.

[alure]: https://github.com/kcat/alure
[ModernGL]: https://github.com/moderngl/moderngl
[Cython]: https://cython.org/
[GH-1]: https://github.com/McSinyx/palace/issues/1
[GH-3]: https://github.com/McSinyx/palace/issues/3
[LGPLv3+]: https://www.gnu.org/licenses/lgpl-3.0.en.html
[sk-cmake]: https://scikit-build.readthedocs.io/en/latest/cmake-modules.html
[sk-license]: https://github.com/scikit-build/scikit-build/blob/master/LICENSE
