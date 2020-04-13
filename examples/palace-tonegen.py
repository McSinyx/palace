#!/usr/bin/env python3
# Sample for tone generator
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
from functools import partial
from operator import not_
from random import random
from time import sleep
from typing import Callable, Dict, Tuple

from numpy import arange, float32, ndarray, pi, sin, vectorize
from palace import Buffer, Context, BaseDecoder, Device
from scipy.signal import sawtooth, square

WAVEFORMS: Dict[str, Callable[[ndarray], ndarray]] = {
    'sine': sin,
    'square': square,
    'sawtooth': sawtooth,
    'triangle': partial(sawtooth, width=0.5),
    'impulse': vectorize(not_),
    'white-noise': vectorize(lambda time: random())}


class ToneGenerator(BaseDecoder):
    """Generator of elementary signals."""
    def __init__(self, waveform: str, duration: float, frequency: float):
        self.func = lambda frames: WAVEFORMS[waveform](
            frames / self.frequency * pi * 2 * frequency)
        self.duration = duration
        self.start = 0

    @BaseDecoder.frequency.getter
    def frequency(self) -> int: return 44100

    @BaseDecoder.channel_config.getter
    def channel_config(self) -> str:
        return 'Mono'

    @BaseDecoder.sample_type.getter
    def sample_type(self) -> str:
        return '32-bit float'

    @BaseDecoder.length.getter
    def length(self) -> int: return int(self.duration * self.frequency)

    def seek(self, pos: int) -> bool: return False

    @BaseDecoder.loop_points.getter
    def loop_points(self) -> Tuple[int, int]: return 0, 0

    def read(self, count: int) -> bytes:
        stop = min(self.start + count, self.length)
        data = self.func(arange(self.start, stop))
        self.start = stop
        return data.astype(float32).tobytes()


def play(device: str, waveform: str,
         duration: float, frequency: float) -> None:
    """Play waveform at the given frequency for given duration."""
    with Device(device) as dev, Context(dev):
        print('Opened', dev.name)
        dec = ToneGenerator(waveform, duration, frequency)
        print(f'Playing {waveform} signal at {frequency} Hz for {duration} s')
        with Buffer.from_decoder(dec, 'tonegen') as buf, buf.play():
            sleep(duration)


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('-d', '--device', default='', help='device name')
    parser.add_argument('-w', '--waveform', default='sine', choices=WAVEFORMS,
                        help='waveform to be generated, default to sine')
    parser.add_argument('-l', '--duration', default=1.0, type=float,
                        help='duration in second, default to 1.0')
    parser.add_argument('-f', '--frequency', default=440.0, type=float,
                        help='wave frequency in hertz, default to 440.0')
    args = parser.parse_args()
    play(args.device, args.waveform, args.duration, args.frequency)
