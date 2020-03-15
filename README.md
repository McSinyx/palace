# palace
Palace is a Python 3D audio API wrapping around [alure].
To quote alure's README,

> It uses OpenAL for audio rendering, and provides common higher-level features
> such as file loading and decoding, buffer caching, background streaming,
> and source management for virtually unlimited sound source handles.

## Features
In some sense, what palace aimes to be to [OpenAL Soft] is what [ModernGL]
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
Palace requires Python 3.6+ for runtime and [pip] for installation.

### Via PyPI
Palace can be install from the [Python Package Index][PyPI] via simply

    pip install palace

Wheel distributions are only built for GNU/Linux and macOS on amd64
at the time of writing.  If you want to help out, please head to
GitHub issue [#1][GH-1].

### From source
Aside from the build dependencies listed in `pyproject.toml`, one will
additionally need compatible Python headers, [alure], a C++14 compiler,
[CMake] 2.6+ (and probably `git` for fetching the source).
Palace can then be compiled and installed by running
```sh
git clone https://github.com/McSinyx/palace
pip install palace/
```

## Usage
One may start with the `examples` for sample usage of palace.
For further information, Python's `help` is your friend.

## License and Credits
Palace is released under the [GNU LGPL version 3 or later][LGPLv3+].

To ensure that palace can run without any dependencies outside of the [pip]
toolchain, the wheels are bundled with dynamically linked libraries from
the build machine, which is similar to static linking:

| Library        | License      |
| -------------- | ------------ |
| [Alure][alure] | ZLib         |
| [OpenAL Soft]  | GNU LGPLv2+  |
| [Vorbis]       | 3-clause BSD |
| [Opus]         | 3-clause BSD |
| [libsndfile]   | GNU LGPL2.1+ |

[alure]: https://github.com/kcat/alure
[OpenAL Soft]: https://kcat.strangesoft.net/openal.html
[ModernGL]: https://github.com/moderngl/moderngl
[Cython]: https://cython.org/
[pip]: https://pip.pypa.io/en/latest/
[PyPI]: https://pypi.org/project/palace/
[GH-1]: https://github.com/McSinyx/palace/issues/1
[CMake]: https://cmake.org/
[Vorbis]: https://xiph.org/vorbis/
[Opus]: http://opus-codec.org/
[libsndfile]: http://www.mega-nerd.com/libsndfile/
[LGPLv3+]: https://www.gnu.org/licenses/lgpl-3.0.en.html
