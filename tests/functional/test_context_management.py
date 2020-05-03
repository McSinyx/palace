# Context managers' functional tests
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

from palace import (current_context, cache, free, decode, Device, Context,
                    Buffer, Source, SourceGroup, ReverbEffect, ChorusEffect)
from pytest import mark, raises


def test_current_context():
    """Test the current context."""
    with Device() as device, Context(device) as context:
        assert current_context() == context
    assert current_context() is None


def test_stream_loading(wav):
    """Test implication of context during stream loading."""
    with Device() as device, Context(device): decode(wav)
    with raises(RuntimeError): decode(wav)


@mark.skip(reason='deadlock (GH-73)')
def test_cache_and_free(aiff, flac, ogg):
    """Test cache and free, with and without a current context."""
    with Device() as device, Context(device):
        cache([aiff, flac, ogg])
        free([aiff, flac, ogg])
    with raises(RuntimeError): cache([aiff, flac, ogg])
    with raises(RuntimeError): free([aiff, flac, ogg])


def test_buffer_loading(mp3):
    """Test implication of context during buffer loading."""
    with Device() as device, Context(device):
        with Buffer(mp3): pass
    with raises(RuntimeError):
        with Buffer(mp3): pass


@mark.parametrize('cls', [Source, SourceGroup, ReverbEffect, ChorusEffect])
def test_init_others(cls):
    """Test implication of context during object initialization."""
    with Device() as device, Context(device):
        with cls(): pass
    with raises(RuntimeError):
        with cls(): pass


def test_nested_context_manager():
    """Test if the context manager returns to the previous context."""
    with Device() as device, Context(device) as context:
        with Context(device): pass
        assert current_context() == context


@mark.parametrize('data', [
    'air_absorption_factor', 'cone_angles', 'distance_range', 'doppler_factor',
    'gain', 'gain_auto', 'gain_range', 'group', 'looping', 'offset',
    'orientation', 'outer_cone_gains', 'pitch', 'position', 'radius',
    'relative', 'rolloff_factors', 'spatialize', 'stereo_angles', 'velocity'])
def test_source_setter(data):
    """Test setters of a Source when its context is not current."""
    with Device() as device, Context(device), Source() as source:
        with raises(RuntimeError), Context(device):
            setattr(source, data, getattr(source, data))
