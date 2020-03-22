#!/usr/bin/env python3
# Use decoders from Python standard libraries
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
import sunau
import wave
from argparse import ArgumentParser
from datetime import datetime, timedelta
from itertools import count, takewhile
from sys import stderr
from time import sleep
from typing import Iterable, Tuple
from types import ModuleType

from palace import (channel_configs, sample_types, decoder_factories,
                    Device, Context, Buffer, BaseDecoder, FileIO)

PERIOD: float = 0.025


def pretty_time(seconds: float) -> str:
    """Return human-readably formatted time."""
    time = datetime.min + timedelta(seconds=seconds)
    if seconds < 3600: return time.strftime('%M:%S')
    return time.strftime('%H:%M:%S')


def play(files: Iterable[str], device: str) -> None:
    """Load and play files on the given device."""
    with Device(device) as dev, Context(dev) as ctx:
        print('Opened', dev.name)
        for filename in files:
            try:
                buffer = Buffer(ctx, filename)
            except RuntimeError:
                stderr.write(f'Failed to open file: {filename}\n')
                continue
            with buffer, buffer.play() as src:
                print(f'Playing {filename} ({buffer.sample_type},',
                      f'{buffer.channel_config}, {buffer.frequency} Hz)')
                for i in takewhile(lambda i: src.playing, count()):
                    print(f' {pretty_time(src.offset_seconds)} /'
                          f' {pretty_time(buffer.length_seconds)}',
                          end='\r', flush=True)
                    sleep(PERIOD)
                print()


class StandardDecoder(BaseDecoder):
    """Decoder wrapper for standard libraries aifc, sunau and wave."""
    def __init__(self, file: FileIO, module: ModuleType, mode: str):
        self.error = module.Error
        try:
            self.impl = module.open(file, mode)
        except self.error:
            raise RuntimeError

    @BaseDecoder.frequency.getter
    def frequency(self) -> int: return self.impl.getframerate()

    @BaseDecoder.channel_config.getter
    def channel_config(self) -> str:
        return channel_configs[self.impl.getnchannels()-1]

    @BaseDecoder.sample_type.getter
    def sample_type(self) -> str:
        return sample_types[self.impl.getsampwidth()-1]

    @BaseDecoder.length.getter
    def length(self) -> int: return self.impl.getnframes()

    def seek(self, pos: int) -> bool:
        try:
            self.impl.setpos(pos)
        except self.error:
            return False
        else:
            return True

    @BaseDecoder.loop_points.getter
    def loop_points(self) -> Tuple[int, int]: return 0, 0

    def read(self, count: int) -> bytes: return self.impl.readframes(count)


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('files', nargs='+', help='audio files')
    parser.add_argument('-d', '--device', default='', help='device name')
    args = parser.parse_args()
    decoder_factories.aifc = lambda file: StandardDecoder(file, aifc, 'rb')
    decoder_factories.sunau = lambda file: StandardDecoder(file, sunau, 'r')
    decoder_factories.wave = lambda file: StandardDecoder(file, wave, 'rb')
    play(args.files, args.device)
