#!/usr/bin/env python3
# Enumerate available devices and show their capabilities
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

from archaicy import DeviceManager


parser = ArgumentParser()
parser.add_argument('device', default='', nargs='?',
                    help='name of device to give extra info')
args = parser.parse_args()

devmgr = DeviceManager()
names = devmgr.device_names
for kind, default in devmgr.device_name_default.items():
    i = names[kind].index(default)
    names[kind][i] += '  [DEFAULT]'
print('Available basic devices:', *names['basic'], sep='\n  ')
print('\nAvailable devices:', *names['full'], sep='\n  ')
print('\nAvailable capture devices:', *names['capture'], sep='\n  ')

with devmgr.open_playback(args.device) as dev:
    print(f'\nInfo of device "{dev.name["full"]}":')
    print('ALC version: {}.{}'.format(*dev.alc_version))
    efx = dev.efx_version
    if efx == (0, 0):
        print('EFX not supported!')
    else:
        print('EFX version: {}.{}'.format(*efx))
        print('Max auxiliary sends:', dev.max_auxiliary_sends)
