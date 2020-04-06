#!/usr/bin/env python3
# Apply reverb effect to sound playback
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

from argparse import Action, ArgumentParser
from datetime import datetime, timedelta
from sys import stderr
from time import sleep
from typing import Iterable

from palace import (reverb_preset_names, decode,
                    Device, Context, Source, AuxiliaryEffectSlot, Effect)

CHUNK_LEN: int = 12000
QUEUE_SIZE: int = 4
PERIOD: float = 0.025


class PresetPrinter(Action):
    def __call__(self, parser: ArgumentParser, *args, **kwargs) -> None:
        print('Available reverb preset names:', *reverb_preset_names, sep='\n')
        parser.exit()


def pretty_time(seconds: float) -> str:
    """Return human-readably formatted time."""
    time = datetime.min + timedelta(seconds=seconds)
    if seconds < 3600: return time.strftime('%M:%S')
    return time.strftime('%H:%M:%S')


def play(files: Iterable[str], device: str, reverb: str) -> None:
    """Load and play files on the given device."""
    with Device(device) as dev, Context(dev) as ctx:
        print('Opened', dev.name)
        with Source() as src, AuxiliaryEffectSlot() as slot, Effect() as fx:
            print('Loading reverb preset', reverb)
            fx.reverb_preset = reverb
            slot.effect = fx
            src.auxiliary_send = slot, 0

            for filename in files:
                try:
                    decoder = decode(filename)
                except RuntimeError:
                    stderr.write(f'Failed to open file: {filename}\n')
                    continue
                decoder.play(CHUNK_LEN, QUEUE_SIZE, src)
                print(f'Playing {filename} ({decoder.sample_type},',
                      f'{decoder.channel_config}, {decoder.frequency} Hz)')
                while src.playing:
                    print(f' {pretty_time(src.offset_seconds)} /'
                          f' {pretty_time(decoder.length_seconds)}',
                          end='\r', flush=True)
                    sleep(PERIOD)
                    ctx.update()
                print()


if __name__ == '__main__':
    parser = ArgumentParser()
    parser.add_argument('files', nargs='+', help='audio files')
    parser.add_argument('-p', '--presets', action=PresetPrinter, nargs=0,
                        help='print available preset names and exit')
    parser.add_argument('-d', '--device', default='', help='device name')
    parser.add_argument('-r', '--reverb', default='GENERIC',
                        help='reverb preset')
    args = parser.parse_args()
    play(args.files, args.device, args.reverb)
