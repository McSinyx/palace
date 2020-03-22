#!/usr/bin/env python3
# HRTF rendering example using ALC_SOFT_HRTF extension
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
from math import cos, sin
from sys import stderr
from time import sleep
from typing import Iterable

from palace import TRUE, HRTF, HRTF_ID, Device, Context, Source, Decoder

CHUNK_LEN: int = 12000
QUEUE_SIZE: int = 4
PERIOD: float = 0.025


def pretty_time(seconds: float) -> str:
    """Return human-readably formatted time."""
    time = datetime.min + timedelta(seconds=seconds)
    if seconds < 3600: return time.strftime('%M:%S')
    return time.strftime('%H:%M:%S')


def play(files: Iterable[str], device: str, hrtf_name: str,
         omega: float) -> None:
    """Render files using HRTF with source rotating in omega rad/s."""
    with Device(device) as dev:
        print('Opened', dev.name)
        hrtf_names = dev.hrtf_names
        if hrtf_names:
            print('Available HRTFs:')
            for name in hrtf_names: print(f'    {name}')
        else:
            print('No HRTF found!')
        attrs = {HRTF: TRUE}
        if hrtf_name is not None:
            try:
                attrs[HRTF_ID] = hrtf_names.index(hrtf_name)
            except ValueError:
                stderr.write(f'HRTF {hrtf_name!r} not found\n')

        with Context(dev, attrs) as ctx, Source(ctx) as src:
            if dev.hrtf_enabled:
                print(f'Using HRTF {dev.current_hrtf!r}')
            else:
                print('HRTF not enabled!')
            src.spatialize = True

            for filename in files:
                try:
                    decoder = Decoder(ctx, filename)
                except RuntimeError:
                    stderr.write(f'Failed to open file: {filename}\n')
                    continue
                decoder.play(src, CHUNK_LEN, QUEUE_SIZE)
                print(f'Playing {filename} ({decoder.sample_type},',
                      f'{decoder.channel_config}, {decoder.frequency} Hz)')

                for i in takewhile(lambda i: src.playing,
                                   count(step=PERIOD)):
                    print(f' {pretty_time(src.offset_seconds)} /'
                          f' {pretty_time(decoder.length_seconds)}',
                          end='\r', flush=True)
                    src.position = sin(i*omega), 0, -cos(i*omega)
                    sleep(PERIOD)
                    ctx.update()
                print()


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('files', nargs='+', help='audio files')
    parser.add_argument('-d', '--device', default='', help='device name')
    parser.add_argument('-n', '--hrtf', dest='hrtf_name', help='HRTF name')
    parser.add_argument('-o', '--omega', type=float, default=1.0,
                        help='angular velocity')
    args = parser.parse_args()
    play(args.files, args.device, args.hrtf_name, args.omega)
