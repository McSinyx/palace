# Source pytest module
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

"""This pytest module tries to test the correctness of the class Source."""

from itertools import permutations, product, repeat
from math import inf, pi
from operator import is_
from random import random, shuffle

from palace import Buffer, BaseEffect, Source, SourceGroup
from pytest import raises

from fmath import FLT_MAX, allclose, isclose


def test_comparison(context):
    """Test basic comparisons."""
    with Source() as source0, Source() as source1, Source() as source2:
        assert source0 != source1
        sources = [source1, source1, source0, source2]
        sources.sort()
        sources.remove(source2)
        sources.remove(source0)
        assert sources[0] == sources[1]


def test_bool(context):
    """Test boolean value."""
    with Source() as source: assert source
    assert not source


def test_control(context, flac):
    """Test calling control methods."""
    with Buffer(flac) as buffer, buffer.play() as source:
        assert source.playing
        assert not source.paused
        source.pause()
        assert source.paused
        assert not source.playing
        source.resume()
        assert source.playing
        assert not source.paused
        source.stop()
        assert not source.playing
        assert not source.paused
        with raises(AttributeError): source.playing = True
        with raises(AttributeError): source.paused = True


def test_fade_out_to_stop(context, mp3):
    """Test calling method fade_out_to_stop."""
    with Buffer(mp3) as buffer, buffer.play() as source:
        source.fade_out_to_stop(5/7, buffer.length>>1)
        with raises(ValueError): source.fade_out_to_stop(0.42, -1)


def test_group(context):
    """Test read-write property group."""
    with Source(context) as source, SourceGroup(context) as source_group:
        assert source.group is None
        source.group = source_group
        assert source.group == source_group
        assert source in source_group.sources
        source.group = None
        assert source.group is None


def test_priority(context):
    """Test read-write property priority."""
    with Source(context) as source:
        assert source.priority == 0
        source.priority = 42
        assert source.priority == 42


def test_offset(context, ogg):
    """Test read-write property offset."""
    with Buffer(ogg) as buffer, buffer.play() as source:
        assert source.offset == 0
        length = buffer.length
        source.offset = length >> 1
        assert source.offset == length >> 1
        with raises(RuntimeError): source.offset = length
        with raises(OverflowError): source.offset = -1


def test_offset_seconds(context, flac):
    """Test read-only property offset_seconds."""
    with Buffer(flac) as buffer, buffer.play() as source:
        assert isinstance(source.offset_seconds, float)
        with raises(AttributeError):
            source.offset_seconds = buffer.length_seconds / 2


def test_latency(context, aiff):
    """Test read-only property latency."""
    with Buffer(aiff) as buffer, buffer.play() as source:
        assert isinstance(source.latency, int)
        with raises(AttributeError):
            source.latency = 42


def test_latency_seconds(context, mp3):
    """Test read-only property latency_seconds."""
    with Buffer(mp3) as buffer, buffer.play() as source:
        assert isinstance(source.latency_seconds, float)
        with raises(AttributeError):
            source.latency_seconds = buffer.length_seconds / 2


def test_looping(context):
    """Test read-write property looping."""
    with Source(context) as source:
        assert source.looping is False
        source.looping = True
        assert source.looping is True
        source.looping = False
        assert source.looping is False


def test_pitch(context):
    """Test read-write property pitch."""
    with Source(context) as source:
        assert isclose(source.pitch, 1)
        with raises(ValueError): source.pitch = -1
        source.pitch = 5 / 7
        assert isclose(source.pitch, 5/7)


def test_gain(context):
    """Test read-write property gain."""
    with Source(context) as source:
        assert isclose(source.gain, 1)
        with raises(ValueError): source.gain = -1
        source.gain = 5 / 7
        assert isclose(source.gain, 5/7)


def test_gain_range(context):
    """Test read-write property gain_range."""
    with Source(context) as source:
        assert allclose(source.gain_range, (0, 1))
        with raises(ValueError): source.gain_range = 9/11, 5/7
        with raises(ValueError): source.gain_range = 6/9, 420
        with raises(ValueError): source.gain_range = -420, 6/9
        source.gain_range = 5/7, 9/11
        assert allclose(source.gain_range, (5/7, 9/11))


def test_distance_range(context):
    """Test read-write property distance_range."""
    with Source(context) as source:
        assert allclose(source.distance_range, (1, FLT_MAX))
        with raises(ValueError): source.distance_range = 9/11, 5/7
        with raises(ValueError): source.distance_range = -420, 6/9
        with raises(ValueError): source.distance_range = 420, inf
        source.distance_range = 5/7, 9/11
        assert allclose(source.distance_range, (5/7, 9/11))
        source.distance_range = 1, FLT_MAX
        assert allclose(source.distance_range, (1, FLT_MAX))


def test_position(context):
    """Test read-write property position."""
    with Source(context) as source:
        assert allclose(source.position, (0, 0, 0))
        source.position = -1, 0, 1
        assert allclose(source.position, (-1, 0, 1))
        source.position = 4, 20, 69
        assert allclose(source.position, (4, 20, 69))


def test_velocity(context):
    """Test read-write property velocity."""
    with Source(context) as source:
        assert allclose(source.velocity, (0, 0, 0))
        source.velocity = -1, 0, 1
        assert allclose(source.velocity, (-1, 0, 1))
        source.velocity = 4, 20, 69
        assert allclose(source.velocity, (4, 20, 69))


def test_orientation(context):
    """Test read-write property orientation."""
    with Source(context) as source:
        assert allclose(source.orientation, ((0, 0, -1), (0, 1, 0)), allclose)
        source.orientation = (1, 1, -2), (3, -5, 8)
        assert allclose(source.orientation, ((1, 1, -2), (3, -5, 8)), allclose)


def test_cone_angles(context):
    """Test read-write property cone_angles."""
    with Source(context) as source:
        assert allclose(source.cone_angles, (360, 360))
        with raises(ValueError): source.cone_angles = 420, 69
        with raises(ValueError): source.cone_angles = -4.20, 69
        with raises(ValueError): source.cone_angles = 4.20, -69
        source.cone_angles = 4.20, 69
        assert allclose(source.cone_angles, (4.20, 69))


def test_outer_cone_gains(context):
    """Test read-write property outer_cone_gains."""
    with Source(context) as source:
        assert allclose(source.outer_cone_gains, (0, 1))
        with raises(ValueError): source.outer_cone_gains = 6/9, -420
        with raises(ValueError): source.outer_cone_gains = 6/9, 420
        with raises(ValueError): source.outer_cone_gains = -420, 6/9
        with raises(ValueError): source.outer_cone_gains = 420, 6/9
        source.outer_cone_gains = 5/7, 9/11
        assert allclose(source.outer_cone_gains, (5/7, 9/11))


def test_rolloff_factors(context):
    """Test read-write property rolloff_factors."""
    with Source(context) as source:
        assert allclose(source.rolloff_factors, (1, 0))
        with raises(ValueError): source.rolloff_factors = -6, 9
        with raises(ValueError): source.rolloff_factors = 6, -9
        source.rolloff_factors = 6, 9
        assert allclose(source.rolloff_factors, (6, 9))


def test_doppler_factor(context):
    """Test read-write property doppler_factor."""
    with Source(context) as source:
        assert isclose(source.doppler_factor, 1)
        with raises(ValueError): source.doppler_factor = -6.9
        with raises(ValueError): source.doppler_factor = 4.20
        source.doppler_factor = 5 / 7
        assert isclose(source.doppler_factor, 5/7)


def test_relative(context):
    """Test read-write property relative."""
    with Source(context) as source:
        assert source.relative is False
        source.relative = True
        assert source.relative is True
        source.relative = False
        assert source.relative is False


def test_radius(context):
    """Test read-write property radius."""
    with Source(context) as source:
        assert isclose(source.radius, 0)
        with raises(ValueError): source.radius = -1
        source.radius = 5 / 7
        assert isclose(source.radius, 5/7)


def test_stereo_angles(context):
    """Test read-write property stereo_angles."""
    with Source(context) as source:
        assert allclose(source.stereo_angles, (pi/6, -pi/6))
        source.stereo_angles = 420, -69
        assert allclose(source.stereo_angles, (420, -69))
        source.stereo_angles = -5/7, 9/11
        assert allclose(source.stereo_angles, (-5/7, 9/11))


def test_spatialize(context):
    """Test read-write property spatialize."""
    with Source(context) as source:
        assert source.spatialize is None
        source.spatialize = False
        assert source.spatialize is False
        source.spatialize = True
        assert source.spatialize is True
        source.spatialize = None
        assert source.spatialize is None


def test_resampler_index(context):
    """Test read-write property resampler_index."""
    with Source() as source:
        assert source.resampler_index == context.default_resampler_index
        with raises(ValueError): source.resampler_index = -1
        source.resampler_index = 69
        assert source.resampler_index == 69


def test_air_absorption_factor(context):
    """Test read-write property air_absorption_factor."""
    with Source(context) as source:
        assert isclose(source.air_absorption_factor, 0)
        with raises(ValueError): source.air_absorption_factor = -1
        with raises(ValueError): source.air_absorption_factor = 11
        source.air_absorption_factor = 420 / 69
        assert isclose(source.air_absorption_factor, 420/69)


def test_gain_auto(context):
    """Test read-write property gain_auto."""
    with Source(context) as source:
        assert all(gain is True for gain in source.gain_auto)
        for gain_auto in product(*repeat((False, True), 3)):
            source.gain_auto = gain_auto
            assert all(map(is_, source.gain_auto, gain_auto))


def tests_sends(device, context):
    """Test send paths assignment."""
    with Source() as source, BaseEffect() as effect:
        invalid_filter = [-1, 0, 1]
        for i in range(device.max_auxiliary_sends):
            source.sends[i].effect = effect
            source.sends[i].filter = random(), random(), random()
            shuffle(invalid_filter)
            with raises(ValueError): source.sends[i].filter = invalid_filter
            with raises(AttributeError): source.sends[i].effect
            with raises(AttributeError): source.sends[i].filter
        with raises(IndexError): source.sends[-1]
        with raises(TypeError): source.sends[4.2]
        with raises(TypeError): source.sends['0']
        with raises(TypeError): source.sends[6:9]
        with raises(AttributeError): source.sends = ...


def test_filter(context):
    """Test write-only property filter."""
    with Source() as source:
        with raises(AttributeError): source.filter
        source.filter = 1, 6.9, 5/7
        source.filter = 0, 0, 0
        for gain, gain_hf, gain_lf in permutations([4, -2, 0]):
            with raises(ValueError): source.filter = gain, gain_hf, gain_lf
