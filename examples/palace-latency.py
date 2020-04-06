#!/usr/bin/env python3
# Example for latency checking
# Copyright (C) 2020  Ngô Ngọc Đức Huy
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
from sys import stderr
from time import sleep
from typing import Iterable

from palace import Context, Device, Source, decode

CHUNK_LEN: int = 12000
QUEUE_SIZE: int = 4
PERIOD: float = 0.01


def play(files: Iterable[str], device: str) -> None:
    """Load and play the file on given device."""
    with Device(device) as dev, Context(dev) as ctx, Source() as src:
        for filename in files:
            try:
                decoder = decode(filename)
            except RuntimeError:
                stderr.write(f'Failed to open file: {filename}\n')
            decoder.play(CHUNK_LEN, QUEUE_SIZE, src)
            print('Playing: ', filename)
            while src.playing:
                print('Offset:', round(src.offset_seconds), 's - Latency:',
                      src.latency//10**6, 'ms', end='\r', flush=True)
                sleep(PERIOD)
                ctx.update()
            print()


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('files', nargs='+', help='audio files')
    parser.add_argument('-d', '--device', default='', help='device name')
    args = parser.parse_args()
    play(args.files, args.device)
