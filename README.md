# palace
Palace is a Python 3D audio API wrapping around [alure][0].
To quote alure's README,

> It uses OpenAL for audio rendering, and provides common higher-level features
> such as file loading and decoding, buffer caching, background streaming,
> and source management for virtually unlimited sound source handles.

## Features
In some sense, what palace aimes to be to OpenAL is what [ModernGL][1]
is to OpenGL (except that all the heavy-lifting are taken are by alure):

* 3D sound rendering
* Environmental audio effects: reverb, atmospheric air absorption,
  sound occlusion and obstruction
* Binaural (HRTF) rendering
* Out-of-the-box audio decoding of FLAC, MP3, Ogg Vorbis, Opus, WAV, AIFF, etc.
* Modern Pythonic API: snake_case, `@property`, `with` context manager,
  type annotation

## Installation
### Via PyPI
Palace requires Python 3.6+ and [alure][0].
Given these dependencies satisfied, palace could be installed using `pip` via

    pip install palace

Currently only GNU/Linux is supported.  If you want to help package for
other operating systems, please head to issue #1.

### From source
To build from source, one will also need to have Python headers, [Cython][2],
and a C++11 compiler (and probably `git` for fetching the source) installed.
Palace can then be compiled and installed by running

```sh
git clone https://github.com/McSinyx/palace
cd palace
python setup.py install --user
```

## Usage
One may start with the `examples` for sample usage of palace.
For further information, Python's `help` is your friend.

[0]: https://github.com/kcat/alure
[1]: https://github.com/moderngl/moderngl
[2]: https://cython.org/
