# Effect pytest module
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

"""This pytest module verifies environmental effects."""

from palace import BaseEffect, ReverbEffect, Source
from pytest import raises


def test_slot_gain(context):
    """Test write-only property slot_gain."""
    with BaseEffect() as fx:
        fx.slot_gain = 0
        fx.slot_gain = 1
        fx.slot_gain = 5/7
        with raises(ValueError): fx.slot_gain = 7/5
        with raises(ValueError): fx.slot_gain = -1


def test_source_sends(context):
    """Test property source_sends by assigning it to a source."""
    with Source() as src, BaseEffect() as fx:
        src.sends[0].effect = fx
        assert fx.source_sends[-1] == (src, 0)


def test_use_count(context):
    """Test read-only property use_count."""
    with BaseEffect() as fx:
        assert fx.use_count == len(fx.source_sends)


def test_reverb(context):
    """Test ReverbEffect initialization."""
    with ReverbEffect('DRUGGED'): pass
    with raises(ValueError):
        with ReverbEffect('NOT_AN_EFFECT'): pass


def test_reverb_send_auto(context):
    """Test ReverbEffect's write-only property send_auto."""
    with ReverbEffect() as fx:
        fx.send_auto = False
        fx.send_auto = True
