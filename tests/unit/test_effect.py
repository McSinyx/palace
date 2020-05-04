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

from palace import BaseEffect, ChorusEffect, ReverbEffect, Source
from pytest import raises

from fmath import isclose, allclose


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


def test_reverb_density(context):
    """Test ReverbEffect's property density."""
    with ReverbEffect() as fx:
        assert fx.density == 1
        fx.density = 5/7
        assert isclose(fx.density, 5/7)
        fx.density = 0
        assert fx.density == 0
        fx.density = 1
        assert fx.density == 1
        with raises(ValueError): fx.density = 7/5
        with raises(ValueError): fx.density = -1


def test_reverb_diffusion(context):
    """Test ReverbEffect's property diffusion."""
    with ReverbEffect() as fx:
        assert fx.diffusion == 1
        fx.diffusion = 5/7
        assert isclose(fx.diffusion, 5/7)
        fx.diffusion = 0
        assert fx.diffusion == 0
        fx.diffusion = 1
        assert fx.diffusion == 1
        with raises(ValueError): fx.diffusion = 7/5
        with raises(ValueError): fx.diffusion = -1


def test_reverb_gain(context):
    """Test ReverbEffect's property gain."""
    with ReverbEffect() as fx:
        assert isclose(fx.gain, 0.3162)
        fx.gain = 5/7
        assert isclose(fx.gain, 5/7)
        fx.gain = 0
        assert fx.gain == 0
        fx.gain = 1
        assert fx.gain == 1
        with raises(ValueError): fx.gain = 7/5
        with raises(ValueError): fx.gain = -1


def test_reverb_gain_hf(context):
    """Test ReverbEffect's property gain_hf."""
    with ReverbEffect() as fx:
        assert isclose(fx.gain_hf, 0.8913)
        fx.gain_hf = 5/7
        assert isclose(fx.gain_hf, 5/7)
        fx.gain_hf = 0
        assert fx.gain_hf == 0
        fx.gain_hf = 1
        assert fx.gain_hf == 1
        with raises(ValueError): fx.gain_hf = 7/5
        with raises(ValueError): fx.gain_hf = -1


def test_reverb_gain_lf(context):
    """Test ReverbEffect's property gain_lf."""
    with ReverbEffect() as fx:
        assert fx.gain_lf == 1
        fx.gain_lf = 5/7
        assert isclose(fx.gain_lf, 5/7)
        fx.gain_lf = 0
        assert fx.gain_lf == 0
        fx.gain_lf = 1
        assert fx.gain_lf == 1
        with raises(ValueError): fx.gain_lf = 7/5
        with raises(ValueError): fx.gain_lf = -1


def test_reverb_decay_time(context):
    """Test ReverbEffect's property decay_time."""
    with ReverbEffect() as fx:
        assert isclose(fx.decay_time, 1.49)
        fx.decay_time = 5/7
        assert isclose(fx.decay_time, 5/7)
        fx.decay_time = 0.1
        assert isclose(fx.decay_time, 0.1)
        fx.decay_time = 20
        assert fx.decay_time == 20
        with raises(ValueError): fx.decay_time = 21
        with raises(ValueError): fx.decay_time = -1


def test_reverb_decay_hf_ratio(context):
    """Test ReverbEffect's property decay_hf_ratio."""
    with ReverbEffect() as fx:
        assert isclose(fx.decay_hf_ratio, 0.83)
        fx.decay_hf_ratio = 5/7
        assert isclose(fx.decay_hf_ratio, 5/7)
        fx.decay_hf_ratio = 0.1
        assert isclose(fx.decay_hf_ratio, 0.1)
        fx.decay_hf_ratio = 2
        assert fx.decay_hf_ratio == 2
        with raises(ValueError): fx.decay_hf_ratio = 21
        with raises(ValueError): fx.decay_hf_ratio = -1


def test_reverb_decay_lf_ratio(context):
    """Test ReverbEffect's property decay_lf_ratio."""
    with ReverbEffect() as fx:
        assert fx.decay_lf_ratio == 1
        fx.decay_lf_ratio = 5/7
        assert isclose(fx.decay_lf_ratio, 5/7)
        fx.decay_lf_ratio = 0.1
        assert isclose(fx.decay_lf_ratio, 0.1)
        fx.decay_lf_ratio = 2
        assert fx.decay_lf_ratio == 2
        with raises(ValueError): fx.decay_lf_ratio = 21
        with raises(ValueError): fx.decay_lf_ratio = -1


def test_reverb_reflections_gain(context):
    """Test ReverbEffect's property reflections_gain."""
    with ReverbEffect() as fx:
        assert isclose(fx.reflections_gain, 0.05)
        fx.reflections_gain = 5/7
        assert isclose(fx.reflections_gain, 5/7)
        fx.reflections_gain = 3.16
        assert isclose(fx.reflections_gain, 3.16)
        fx.reflections_gain = 0
        assert fx.reflections_gain == 0
        with raises(ValueError): fx.reflections_gain = 4
        with raises(ValueError): fx.reflections_gain = -1


def test_reverb_reflections_delay(context):
    """Test ReverbEffect's property reflections_delay."""
    with ReverbEffect() as fx:
        assert isclose(fx.reflections_delay, 0.007)
        fx.reflections_delay = 0.3
        assert isclose(fx.reflections_delay, 0.3)
        fx.reflections_delay = 0
        assert fx.reflections_delay == 0
        with raises(ValueError): fx.reflections_delay = 1
        with raises(ValueError): fx.reflections_delay = -1


def test_reverb_reflections_pan(context):
    """Test ReverbEffect's property reflections_pan."""
    with ReverbEffect() as fx:
        assert allclose(fx.reflections_pan, (0, 0, 0))
        fx.reflections_pan = 5/7, -69/420, 6/9
        assert allclose(fx.reflections_pan, (5/7, -69/420, 6/9))
        with raises(ValueError): fx.reflections_pan = 1, 1, 1
        with raises(ValueError): fx.reflections_pan = 0, 0, 2
        with raises(ValueError): fx.reflections_pan = 0, 2, 0
        with raises(ValueError): fx.reflections_pan = 2, 0, 0
        with raises(ValueError): fx.reflections_pan = 0, 0, -2
        with raises(ValueError): fx.reflections_pan = 0, -2, 0
        with raises(ValueError): fx.reflections_pan = -2, 0, 0


def test_reverb_late_reverb_gain(context):
    """Test ReverbEffect's property late_reverb_gain."""
    with ReverbEffect() as fx:
        assert isclose(fx.late_reverb_gain, 1.2589)
        fx.late_reverb_gain = 5/7
        assert isclose(fx.late_reverb_gain, 5/7)
        fx.late_reverb_gain = 0
        assert fx.late_reverb_gain == 0
        fx.late_reverb_gain = 10
        assert fx.late_reverb_gain == 10
        with raises(ValueError): fx.late_reverb_gain = 11
        with raises(ValueError): fx.late_reverb_gain = -1


def test_reverb_late_reverb_delay(context):
    """Test ReverbEffect's property late_reverb_delay."""
    with ReverbEffect() as fx:
        assert isclose(fx.late_reverb_delay, 0.011)
        fx.late_reverb_delay = 0.05
        assert isclose(fx.late_reverb_delay, 0.05)
        fx.late_reverb_delay = 0
        assert fx.late_reverb_delay == 0
        fx.late_reverb_delay = 0.1
        assert isclose(fx.late_reverb_delay, 0.1)
        with raises(ValueError): fx.late_reverb_delay = 1
        with raises(ValueError): fx.late_reverb_delay = -1


def test_reverb_late_reverb_pan(context):
    """Test ReverbEffect's property late_reverb_pan."""
    with ReverbEffect() as fx:
        assert allclose(fx.late_reverb_pan, (0, 0, 0))
        fx.late_reverb_pan = 5/7, -69/420, 6/9
        assert allclose(fx.late_reverb_pan, (5/7, -69/420, 6/9))
        with raises(ValueError): fx.late_reverb_pan = 1, 1, 1
        with raises(ValueError): fx.late_reverb_pan = 0, 0, 2
        with raises(ValueError): fx.late_reverb_pan = 0, 2, 0
        with raises(ValueError): fx.late_reverb_pan = 2, 0, 0
        with raises(ValueError): fx.late_reverb_pan = 0, 0, -2
        with raises(ValueError): fx.late_reverb_pan = 0, -2, 0
        with raises(ValueError): fx.late_reverb_pan = -2, 0, 0


def test_reverb_echo_time(context):
    """Test ReverbEffect's property echo_time."""
    with ReverbEffect() as fx:
        assert isclose(fx.echo_time, 0.25)
        fx.echo_time = 0.075
        assert isclose(fx.echo_time, 0.075)
        fx.echo_time = 0.1
        assert isclose(fx.echo_time, 0.1)
        with raises(ValueError): fx.echo_time = 0.05
        with raises(ValueError): fx.echo_time = 0.5


def test_reverb_echo_depth(context):
    """Test ReverbEffect's property echo_depth."""
    with ReverbEffect() as fx:
        assert fx.echo_depth == 0
        fx.echo_depth = 5/7
        assert isclose(fx.echo_depth, 5/7)
        fx.echo_depth = 0
        assert fx.echo_depth == 0
        fx.echo_depth = 1
        assert fx.echo_depth == 1
        with raises(ValueError): fx.echo_depth = 7/5
        with raises(ValueError): fx.echo_depth = -1


def test_reverb_modulation_time(context):
    """Test ReverbEffect's property modulation_time."""
    with ReverbEffect() as fx:
        assert isclose(fx.modulation_time, 0.25)
        fx.modulation_time = 5/7
        assert isclose(fx.modulation_time, 5/7)
        fx.modulation_time = 0.04
        assert isclose(fx.modulation_time, 0.04)
        fx.modulation_time = 4
        assert fx.modulation_time == 4
        with raises(ValueError): fx.modulation_time = 4.2
        with raises(ValueError): fx.modulation_time = 0


def test_reverb_modulation_depth(context):
    """Test ReverbEffect's property modulation_depth."""
    with ReverbEffect() as fx:
        assert fx.modulation_depth == 0
        fx.modulation_depth = 5/7
        assert isclose(fx.modulation_depth, 5/7)
        fx.modulation_depth = 0
        assert fx.modulation_depth == 0
        fx.modulation_depth = 1
        assert fx.modulation_depth == 1
        with raises(ValueError): fx.modulation_depth = 7/5
        with raises(ValueError): fx.modulation_depth = -1


def test_reverb_air_absorption_gain_hf(context):
    """Test ReverbEffect's property air_absorption_gain_hf."""
    with ReverbEffect() as fx:
        assert isclose(fx.air_absorption_gain_hf, 0.9943)
        fx.air_absorption_gain_hf = 0.999
        assert isclose(fx.air_absorption_gain_hf, 0.999)
        fx.air_absorption_gain_hf = 0.892
        assert isclose(fx.air_absorption_gain_hf, 0.892)
        fx.air_absorption_gain_hf = 1
        assert fx.air_absorption_gain_hf == 1
        with raises(ValueError): fx.air_absorption_gain_hf = 7/5
        with raises(ValueError): fx.air_absorption_gain_hf = 0.5


def test_reverb_hf_reference(context):
    """Test ReverbEffect's property hf_reference."""
    with ReverbEffect() as fx:
        assert fx.hf_reference == 5000
        fx.hf_reference = 6969
        assert fx.hf_reference == 6969
        fx.hf_reference = 1000
        assert fx.hf_reference == 1000
        fx.hf_reference = 20000
        assert fx.hf_reference == 20000
        with raises(ValueError): fx.hf_reference = 20000.5
        with raises(ValueError): fx.hf_reference = 999


def test_reverb_lf_reference(context):
    """Test ReverbEffect's property lf_reference."""
    with ReverbEffect() as fx:
        assert fx.lf_reference == 250
        fx.lf_reference = 666
        assert fx.lf_reference == 666
        fx.lf_reference = 1000
        assert fx.lf_reference == 1000
        fx.lf_reference = 20
        assert fx.lf_reference == 20
        with raises(ValueError): fx.lf_reference = 19.5
        with raises(ValueError): fx.lf_reference = 1001


def test_reverb_room_rolloff_factor(context):
    """Test ReverbEffect's property room_rolloff_factor."""
    with ReverbEffect() as fx:
        assert fx.room_rolloff_factor == 0
        fx.room_rolloff_factor = 9/6
        assert fx.room_rolloff_factor == 9/6
        fx.room_rolloff_factor = 0
        assert fx.room_rolloff_factor == 0
        fx.room_rolloff_factor = 10
        assert fx.room_rolloff_factor == 10
        with raises(ValueError): fx.room_rolloff_factor = 10.5
        with raises(ValueError): fx.room_rolloff_factor = -1


def test_reverb_decay_hf_limit(context):
    """Test ReverbEffect's property decay_hf_limit."""
    with ReverbEffect() as fx:
        assert fx.decay_hf_limit is True
        fx.decay_hf_limit = False
        assert fx.decay_hf_limit is False
        fx.decay_hf_limit = True
        assert fx.decay_hf_limit is True


def test_chorus_waveform(context):
    """Test ChorusEffect's property waveform."""
    with ChorusEffect() as fx:
        assert fx.waveform == 'triangle'
        fx.waveform = 'sine'
        assert fx.waveform == 'sine'
        fx.waveform = 'triangle'
        assert fx.waveform == 'triangle'
        with raises(ValueError): fx.waveform = 'ABC'


def test_chorus_phase(context):
    """Test ChorusEffect's property phase."""
    with ChorusEffect() as fx:
        assert fx.phase == 90
        fx.phase = 180
        assert fx.phase == 180
        fx.phase = -180
        assert fx.phase == -180
        with raises(ValueError): fx.phase = 181
        with raises(ValueError): fx.phase = -181


def test_chorus_depth(context):
    """Test ChorusEffect's property depth."""
    with ChorusEffect() as fx:
        assert isclose(fx.depth, 0.1)
        fx.depth = 0
        assert fx.depth == 0
        fx.depth = 1
        assert fx.depth == 1
        with raises(ValueError): fx.depth = 2
        with raises(ValueError): fx.depth = -1


def test_chorus_feedback(context):
    """Test ChorusEffect's property feedback."""
    with ChorusEffect() as fx:
        assert isclose(fx.feedback, 0.25)
        fx.feedback = -1
        assert fx.feedback == -1
        fx.feedback = 1
        assert fx.feedback == 1
        with raises(ValueError): fx.feedback = 3/2
        with raises(ValueError): fx.feedback = -7/5


def test_chorus_delay(context):
    """Test ChorusEffect's property delay."""
    with ChorusEffect() as fx:
        assert isclose(fx.delay, 0.016)
        fx.delay = 0
        assert fx.delay == 0
        fx.delay = 0.016
        assert isclose(fx.delay, 0.016)
        with raises(ValueError): fx.delay = 0.017
        with raises(ValueError): fx.delay = -0.1
