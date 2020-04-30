# Context pytest module
# Copyright (C) 2020  Ngô Ngọc Đức Huy
# Copyright (C) 2020  Nguyễn Gia Phong
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

"""This pytest module tries to test the correctness of the class Context."""

from palace import current_context, distance_models, Context, MessageHandler
from pytest import raises

from math import inf


def test_comparison(device):
    """Test basic comparisons."""
    with Context(device) as c0, Context(device) as c1, Context(device) as c2:
        assert c0 != c1
        contexts = [c1, c1, c0, c2]
        contexts.sort()
        contexts.remove(c2)
        contexts.remove(c0)
        assert contexts[0] == contexts[1]


def test_bool(device):
    """Test boolean value."""
    with Context(device) as context: assert context
    assert not context


def test_batch_control(device):
    """Test calls of start_batch and end_batch."""
    with Context(device) as context:
        # At the moment these are no-op.
        context.start_batch()
        context.end_batch()


def test_message_handler(device):
    """Test read-write property MessageHandler."""
    context = Context(device)
    assert type(context.message_handler) is MessageHandler
    message_handler_test = type('MessageHandlerTest', (MessageHandler,), {})()
    context.message_handler = message_handler_test
    assert context.message_handler is message_handler_test
    with context:
        assert current_context().message_handler is context.message_handler


def test_async_wake_interval(device):
    """Test read-write property async_wake_interval."""
    with Context(device) as context:
        context.async_wake_interval = 42
        assert context.async_wake_interval == 42


def test_format_support(device):
    """Test method is_supported."""
    with Context(device) as context:
        assert isinstance(context.is_supported('Rear', '32-bit float'), bool)
        with raises(ValueError): context.is_supported('Shu', 'Mulaw')
        with raises(ValueError): context.is_supported('Stereo', 'Type')


def test_default_resampler_index(device):
    """Test read-only property default_resampler_index."""
    with Context(device) as context:
        index = context.default_resampler_index
        assert index >= 0
        assert len(context.available_resamplers) > index
        with raises(AttributeError): context.available_resamplers = 0


def test_doppler_factor(device):
    """Test write-only property doppler_factor."""
    with Context(device) as context:
        context.doppler_factor = 4/9
        context.doppler_factor = 9/4
        context.doppler_factor = 0
        context.doppler_factor = inf
        with raises(ValueError): context.doppler_factor = -1
        with raises(AttributeError): context.doppler_factor


def test_speed_of_sound(device):
    """Test write-only property speed_of_sound."""
    with Context(device) as context:
        context.speed_of_sound = 5/7
        context.speed_of_sound = 7/5
        with raises(ValueError): context.speed_of_sound = 0
        context.speed_of_sound = inf
        with raises(ValueError): context.speed_of_sound = -1
        with raises(AttributeError): context.speed_of_sound


def test_distance_model(device):
    """Test write-only distance_model."""
    with Context(device) as context:
        for model in distance_models: context.distance_model = model
        with raises(ValueError): context.distance_model = 'EYYYYLMAO'
        with raises(AttributeError): context.distance_model
