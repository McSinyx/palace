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

from argparse import Action, ArgumentParser
from functools import partial
from math import pi
from random import random
from time import sleep
from typing import Callable, Dict, Tuple

from palace import Buffer, Context, BaseDecoder, Device
from numpy import arange, float32, ndarray, sin, vectorize
from scipy.signal import sawtooth, square, unit_impulse

WAVEFORMS: Dict[str, Callable[[ndarray], ndarray]] = {
    'sine': sin,
    'square': square,
    'sawtooth': sawtooth,
    'triangle': partial(sawtooth, 0.5),
    'impulse': lambda frames: unit_impulse(len(frames)),
    'white-noise': vectorize(lambda time: random())}


class ToneGenerator(BaseDecoder):
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


class TypePrinter(Action):
    def __call__(self, parser: ArgumentParser, *args, **kwargs) -> None:
        print('Available waveform types:', *WAVEFORMS, sep='\n')
        parser.exit()


def play(device: str, waveform: str,
         duration: float, frequency: float) -> None:
    with Device(device) as dev, Context(dev):
        dec = ToneGenerator(waveform, duration, frequency)
        with Buffer.from_decoder(dec, 'tonegen') as buf, buf.play() as src:
            while src.playing:
                sleep()


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('-t', '--types', nargs=0, action=TypePrinter,
                        help='print available waveform types in this example')
    parser.add_argument('-w', '--waveform', default='sine', type=str,
                        help='waveform to be generated, default to sine')
    parser.add_argument('-d', '--device', default='', help='device name')
    parser.add_argument('-l', '--duration', default=5.0, type=float,
                        help='duration, in second')
    parser.add_argument('-f', '--frequency', default=440.0, type=float,
                        help='frequency for the wave in hertz, default to 440')
    args = parser.parse_args()
    play(args.device, args.waveform, args.duration, args.frequency)
