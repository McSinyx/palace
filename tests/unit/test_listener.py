# Listener pytest module
# Copyright (C) 2020  Ngô Xuân Minh
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

"""This pytest module tries to test the correctness of the class Listener."""

from pytest import raises

from math import inf


def test_gain(context):
    """Test write property gain."""
    context.listener.gain = 5/7
    context.listener.gain = 7/5
    context.listener.gain = 0
    context.listener.gain = inf
    with raises(ValueError): context.listener.gain = -1


def test_position(context):
    """Test write property position."""
    context.listener.position = 1, 0, 1
    context.listener.position = 1, 0, -1
    context.listener.position = 1, -1, 0
    context.listener.position = 1, 1, 0
    context.listener.position = 0, 0, 0
    context.listener.position = 1, 1, 1


def test_velocity(context):
    """Test write property velocity."""
    context.listener.velocity = 420, 0, 69
    context.listener.velocity = 69, 0, -420
    context.listener.velocity = 0, 420, -69
    context.listener.velocity = 0, 0, 42
    context.listener.velocity = 0, 0, 0
    context.listener.velocity = 420, 69, 420


def test_orientaion(context):
    """Test write property orientation."""
    context.listener.orientation = (420, 0, 69), (0, 42, 0)
    context.listener.orientation = (69, 0, -420), (0, -69, 420)
    context.listener.orientation = (0, 420, -69), (420, -69, 69)
    context.listener.orientation = (0, 0, 42), (-420, -420, 0)
    context.listener.orientation = (0, 0, 0), (-420, -69, -69)
    context.listener.orientation = (420, 69, 420), (69, -420, 0)


def test_meters_per_unit(context):
    """Test write property meter_per_unit."""
    context.listener.meters_per_unit = 4/9
    context.listener.meters_per_unit = 9/4
    with raises(ValueError): context.listener.meters_per_unit = 0
    context.listener.meters_per_unit = inf
    with raises(ValueError): context.listener.meters_per_unit = -1
