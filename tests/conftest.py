# Common test fixtures
# Copyright (C) 2020  Ngô Ngọc Đức Huy
# Copyright (C) 2020  Nguyễn Gia Phong
#
# This file is part of palace.
#
# palace is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# palace is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with palace.  If not, see <https://www.gnu.org/licenses/>.

from os.path import abspath, dirname, join

from pytest import fixture

DATA_DIR = abspath(join(dirname(__file__), 'data'))


@fixture
def aiff():
    """Provide a sample AIFF file."""
    return join(DATA_DIR, '24741__tim-kahn__b23-c1-raw.aiff')


@fixture
def flac():
    """Provide a sample FLAC file."""
    return join(DATA_DIR, '261590__kwahmah-02__little-glitch.flac')


@fixture
def mp3():
    """Provide a sample MP3 file."""
    return join(DATA_DIR, '353684__tec-studio__drip2.mp3')


@fixture
def ogg():
    """Provide a sample Ogg Vorbis file."""
    return join(DATA_DIR, '164957__zonkmachine__white-noise.ogg')


@fixture
def wav():
    """Provide a sample WAVE file."""
    return join(DATA_DIR, '99642__jobro__deconvoluted-20hz-to-20khz.wav')
