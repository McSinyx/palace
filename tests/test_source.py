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

from itertools import product, repeat
from math import inf, pi
from operator import is_

from pytest import raises

from fmath import FLT_MAX, allclose, isclose


def test_group(source, source_group):
    """Test read-write property group."""
    assert source.group is None
    source.group = source_group
    assert source.group == source_group
    source.group = None
    assert source.group is None


def test_priority(source):
    """Test read-write property group."""
    assert source.priority == 0
    source.priority = 42
    assert source.priority == 42
    source.priority = 0
    assert source.priority == 0


def test_offset(source):
    """Test read-write property offset."""
    assert source.offset == 0
    # TODO: give the source a decoder to seek


def test_looping(source):
    """Test read-write property looping."""
    assert source.looping is False
    source.looping = True
    assert source.looping is True
    source.looping = False
    assert source.looping is False


def test_pitch(source):
    """Test read-write property pitch."""
    assert isclose(source.pitch, 1)
    with raises(ValueError): source.pitch = -1
    source.pitch = 5 / 7
    assert isclose(source.pitch, 5/7)
    source.pitch = 1
    assert isclose(source.pitch, 1)


def test_gain(source):
    """Test read-write property gain."""
    assert isclose(source.gain, 1)
    with raises(ValueError): source.gain = -1
    source.gain = 5 / 7
    assert isclose(source.gain, 5/7)
    source.gain = 1
    assert isclose(source.gain, 1)


def test_gain_range(source):
    """Test read-write property gain_range."""
    assert allclose(source.gain_range, (0, 1))
    with raises(ValueError): source.gain_range = 9/11, 5/7
    with raises(ValueError): source.gain_range = 6/9, 420
    with raises(ValueError): source.gain_range = -420, 6/9
    source.gain_range = 5/7, 9/11
    assert allclose(source.gain_range, (5/7, 9/11))
    source.gain_range = 0, 1
    assert allclose(source.gain_range, (0, 1))


def test_distance_range(source):
    """Test read-write property distance_range."""
    assert allclose(source.distance_range, (1, FLT_MAX))
    with raises(ValueError): source.distance_range = 9/11, 5/7
    with raises(ValueError): source.distance_range = -420, 6/9
    with raises(ValueError): source.distance_range = 420, inf
    source.distance_range = 5/7, 9/11
    assert allclose(source.distance_range, (5/7, 9/11))
    source.distance_range = 1, FLT_MAX
    assert allclose(source.distance_range, (1, FLT_MAX))


def test_position(source):
    """Test read-write property position."""
    assert allclose(source.position, (0, 0, 0))
    source.position = -1, 0, 1
    assert allclose(source.position, (-1, 0, 1))
    source.position = 4, 20, 69
    assert allclose(source.position, (4, 20, 69))
    source.position = 0, 0, 0
    assert allclose(source.position, (0, 0, 0))


def test_velocity(source):
    """Test read-write property velocity."""
    assert allclose(source.velocity, (0, 0, 0))
    source.velocity = -1, 0, 1
    assert allclose(source.velocity, (-1, 0, 1))
    source.velocity = 4, 20, 69
    assert allclose(source.velocity, (4, 20, 69))
    source.velocity = 0, 0, 0
    assert allclose(source.velocity, (0, 0, 0))


def test_orientation(source):
    """Test read-write property orientation."""
    assert all(map(allclose, source.orientation, ((0, 0, -1), (0, 1, 0))))
    source.orientation = (1, -2, 3), (-4, 5, -6)
    assert all(map(allclose, source.orientation, ((1, -2, 3), (-4, 5, -6))))
    source.orientation = (0, 0, -1), (0, 1, 0)
    assert all(map(allclose, source.orientation, ((0, 0, -1), (0, 1, 0))))


def test_cone_angles(source):
    """Test read-write property cone_angles."""
    assert allclose(source.cone_angles, (360, 360))
    with raises(ValueError): source.cone_angles = 420, 69
    with raises(ValueError): source.cone_angles = -4.20, 69
    with raises(ValueError): source.cone_angles = 4.20, -69
    source.cone_angles = 4.20, 69
    assert allclose(source.cone_angles, (4.20, 69))
    source.cone_angles = 360, 360
    assert allclose(source.cone_angles, (360, 360))


def test_outer_cone_gains(source):
    """Test read-write property outer_cone_gains."""
    assert allclose(source.outer_cone_gains, (0, 1))
    with raises(ValueError): source.outer_cone_gains = 6/9, -420
    with raises(ValueError): source.outer_cone_gains = 6/9, 420
    with raises(ValueError): source.outer_cone_gains = -420, 6/9
    with raises(ValueError): source.outer_cone_gains = 420, 6/9
    source.outer_cone_gains = 5/7, 9/11
    assert allclose(source.outer_cone_gains, (5/7, 9/11))
    source.outer_cone_gains = 0, 1
    assert allclose(source.outer_cone_gains, (0, 1))


def test_rolloff_factors(source):
    """Test read-write property rolloff_factors."""
    assert allclose(source.rolloff_factors, (1, 0))
    with raises(ValueError): source.rolloff_factors = -6, 9
    with raises(ValueError): source.rolloff_factors = 6, -9
    source.rolloff_factors = 6, 9
    assert allclose(source.rolloff_factors, (6, 9))
    source.rolloff_factors = 1, 0


def test_doppler_factor(source):
    """Test read-write property doppler_factor."""
    assert isclose(source.doppler_factor, 1)
    with raises(ValueError): source.doppler_factor = -6.9
    with raises(ValueError): source.doppler_factor = 4.20
    source.doppler_factor = 5 / 7
    assert isclose(source.doppler_factor, 5/7)
    source.doppler_factor = 1
    assert isclose(source.doppler_factor, 1)


def test_relative(source):
    """Test read-write property relative."""
    assert source.relative is False
    source.relative = True
    assert source.relative is True
    source.relative = False
    assert source.relative is False


def test_radius(source):
    """Test read-write property radius."""
    assert isclose(source.radius, 0)
    with raises(ValueError): source.radius = -1
    source.radius = 5 / 7
    assert isclose(source.radius, 5/7)
    source.radius = 1
    assert isclose(source.radius, 1)


def test_stereo_angles(source):
    """Test read-write property stereo_angles."""
    assert allclose(source.stereo_angles, (pi/6, -pi/6))
    source.stereo_angles = 4, 20
    assert allclose(source.stereo_angles, (4, 20))
    source.stereo_angles = -6, -9
    assert allclose(source.stereo_angles, (-6, -9))
    source.stereo_angles = pi/6, -pi/6
    assert allclose(source.stereo_angles, (pi/6, -pi/6))


def test_spatialize(source):
    """Test read-write property spatialize."""
    assert source.spatialize is None
    source.spatialize = False
    assert source.spatialize is False
    source.spatialize = True
    assert source.spatialize is True
    source.spatialize = None
    assert source.spatialize is None


def test_resampler_index(source):
    """Test read-write property resampler_index."""
    # TODO: test initial value
    old_resampler_index = source.resampler_index
    with raises(ValueError): source.resampler_index = -1
    source.resampler_index = 69
    assert source.resampler_index == 69
    source.resampler_index = old_resampler_index
    assert source.resampler_index == old_resampler_index


def test_air_absorption_factor(source):
    """Test read-write property air_absorption_factor."""
    assert isclose(source.air_absorption_factor, 0)
    with raises(ValueError): source.air_absorption_factor = -1
    with raises(ValueError): source.air_absorption_factor = 11
    source.air_absorption_factor = 420 / 69
    assert isclose(source.air_absorption_factor, 420/69)
    source.air_absorption_factor = 0
    assert isclose(source.air_absorption_factor, 0)


def test_gain_auto(source):
    """Test read-write property gain_auto."""
    assert all(gain is True for gain in source.gain_auto)
    for gain_auto in product(*repeat((False, True), 3)):
        source.gain_auto = gain_auto
        assert all(map(is_, source.gain_auto, gain_auto))
