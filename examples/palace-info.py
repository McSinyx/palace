#!/usr/bin/env python3
# Enumerate available devices and show their capabilities
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

from palace import device_names, Device


parser = ArgumentParser()
parser.add_argument('device', type=Device, default='', nargs='?',
                    help='name of device to give extra info')
args = parser.parse_args()

with args.device:
    print('Available basic devices, with the first being default:',
          *device_names.basic, sep='\n  ')
    print('\nAvailable devices, with the first being default:',
          *device_names.full, sep='\n  ')
    print('\nAvailable capture devices, with the first being default:',
          *device_names.capture, sep='\n  ')

    print(f'\nInfo of device {args.device.name!r}:')
    print('ALC version: {}.{}'.format(*args.device.alc_version))
    efx = args.device.efx_version
    if efx == (0, 0):
        print('EFX not supported!')
    else:
        print('EFX version: {}.{}'.format(*efx))
        print('Max auxiliary sends:', args.device.max_auxiliary_sends)
