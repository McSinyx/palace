#!/usr/bin/env python3
# A simple example showing how to load and play a sound
# Copyright (C) 2019, 2020  Nguyễn Gia Phong
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

from argparse import ArgumentParser
from datetime import datetime, timedelta
from itertools import count, takewhile
from sys import stderr
from time import sleep
from typing import Iterable, List

from palace import Device, Context, Buffer, MessageHandler

PERIOD: float = 0.025


class LoadingBufferHandler(MessageHandler):
    """Message handler of buffer loading events."""
    def buffer_loading(self, name: str, channel_config: str, sample_type: str,
                       sample_rate: int, data: List[int]) -> None:
        """Print buffers information on buffer loading events."""
        print(f'Playing {name} ({sample_type},',
              f'{channel_config}, {sample_rate} Hz)')


def pretty_time(seconds: float) -> str:
    """Return human-readably formatted time."""
    time = datetime.min + timedelta(seconds=seconds)
    if seconds < 3600: return time.strftime('%M:%S')
    return time.strftime('%H:%M:%S')


def play(files: Iterable[str], device: str) -> None:
    """Load and play files on the given device."""
    with Device(device) as dev, Context(dev) as ctx:
        print('Opened', dev.name)
        ctx.message_handler = LoadingBufferHandler()
        for filename in files:
            try:
                buffer = Buffer(ctx, filename)
            except RuntimeError:
                stderr.write(f'Failed to open file: {filename}\n')
                continue
            with buffer, buffer.play() as src:
                for i in takewhile(lambda i: src.playing, count()):
                    print(f' {pretty_time(src.offset_seconds)} /'
                          f' {pretty_time(buffer.length_seconds)}',
                          end='\r', flush=True)
                    sleep(PERIOD)
                print()


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('files', nargs='+', help='audio files')
    parser.add_argument('-d', '--device', default='', help='device name')
    args = parser.parse_args()
    play(args.files, args.device)
