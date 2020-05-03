# Message handling functional tests
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

import aifc
from os import environ
from platform import system
from unittest.mock import Mock
from uuid import uuid4

from palace import (channel_configs, sample_types, decode,
                    Device, Context, Buffer, SourceGroup, MessageHandler)
from pytest import mark


travis_macos = bool(environ.get('TRAVIS')) and system() == 'Darwin'
skipif_travis_macos = mark.skipif(travis_macos, reason='Travis CI for macOS')


def mock(message):
    """Return the MessageHandler corresponding to the given message."""
    return type(''.join(map(str.capitalize, message.split('_'))),
                (MessageHandler,), {message: Mock()})()


@mark.skip(reason='unknown way of disconnecting device to test this')
def test_device_diconnected():
    """Test the handling of device disconnected message."""


@skipif_travis_macos
def test_source_stopped(wav):
    """Test the handling of source stopped message."""
    with Device() as device, Context(device) as context, Buffer(wav) as buffer:
        context.message_handler = mock('source_stopped')
        with buffer.play() as source:
            while source.playing: pass
            context.update()
            context.message_handler.source_stopped.assert_called_with(source)


@skipif_travis_macos
def test_source_force_stopped(ogg):
    """Test the handling of source force stopped message."""
    with Device() as device, Context(device) as context:
        context.message_handler = mock('source_force_stopped')
        # TODO: test source preempted by a higher-prioritized one
        with Buffer(ogg) as buffer: source = buffer.play()
        context.message_handler.source_force_stopped.assert_called_with(source)
        with SourceGroup() as group, Buffer(ogg) as buffer:
            source.group = group
            buffer.play(source)
            group.stop_all()
        context.message_handler.source_force_stopped.assert_called_with(source)
        source.destroy()


@skipif_travis_macos
def test_buffer_loading(aiff):
    """Test the handling of buffer loading message."""
    with Device() as device, Context(device) as context:
        context.message_handler = mock('buffer_loading')
        with Buffer(aiff), aifc.open(aiff, 'r') as f:
            args, kwargs = context.message_handler.buffer_loading.call_args
            name, channel_config, sample_type, sample_rate, data = args
            assert name == aiff
            assert channel_config == channel_configs[f.getnchannels()-1]
            assert sample_type == sample_types[f.getsampwidth()-1]
            assert sample_rate == f.getframerate()
            # TODO: verify data


def test_resource_not_found(flac):
    """Test the handling of resource not found message."""
    with Device() as device, Context(device) as context:
        context.message_handler = mock('resource_not_found')
        context.message_handler.resource_not_found.return_value = ''
        name = str(uuid4())
        try:
            decode(name)
        except RuntimeError:
            pass
        context.message_handler.resource_not_found.assert_called_with(name)
