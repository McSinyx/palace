#!/usr/bin/env python3
# A simple example showing how to load and play a sound.
# Copyright (C) 2019  Nguyễn Gia Phong
#
# This file is part of archaicy.
#
# archaicy is free software: you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as published
# by the Free Software Foundation, either version 3 of the License,
# or (at your option) any later version.
#
# archaicy is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with archaicy.  If not, see <https://www.gnu.org/licenses/>.

from argparse import ArgumentParser
from datetime import datetime, timedelta
from itertools import count, takewhile
from sys import stderr
from time import sleep
from typing import Iterable

from archaicy import DeviceManager, Context

PERIOD = 0.025


def pretty_time(seconds: float) -> str:
    """Return human-readably formatted time."""
    time = datetime.min + timedelta(seconds=seconds)
    if seconds < 3600: return time.strftime('%M:%S')
    return time.strftime('%H:%M:%S')


def play(files: Iterable[str], device: str):
    """Load and play files on the given device."""
    devmrg = DeviceManager()
    try:
        dev = devmrg.open_playback(device)
    except RuntimeError:
        stderr.write(f'Failed to open "{device}" - trying default\n')
        dev = devmrg.open_playback()
    print('Opened', dev.full_name)

    ctx = dev.create_context()
    Context.make_current(ctx)
    for filename in files:
        try:
            buffer = ctx.get_buffer(filename)
        except RuntimeError:
            stderr.write(f'Failed to open file: {filename}\n')
            continue
        source = ctx.create_source()

        source.play_from_buffer(buffer)
        print(f'Playing {filename} ({buffer.sample_type_name},',
              f'{buffer.channel_config_name}, {buffer.frequency} Hz)')

        invfreq = 1 / buffer.frequency
        for i in takewhile(lambda i: source.playing, count()):
            print(f' {pretty_time(source.sample_offset*invfreq)} /'
                  f' {pretty_time(buffer.length*invfreq)}',
                  end='\r', flush=True)
            sleep(PERIOD)
        print()
        source.destroy()
        ctx.remove_buffer(buffer)
    Context.make_current()
    ctx.destroy()
    dev.close()


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('files', nargs='+', help='audio files')
    parser.add_argument('-d', '--device', help='device name')
    args = parser.parse_args()
    play(args.files, args.device)
