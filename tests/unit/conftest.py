# test environment
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

"""This module provide default objects of palace classes as fixtures
for convenient testing.
"""

from pytest import fixture
from palace import Device, Context


@fixture(scope='session')
def device():
    """Provide the default device."""
    with Device() as dev: yield dev


@fixture(scope='session')
def context(device):
    """Provide a context creared from the default device
    (default context).
    """
    with Context(device) as ctx: yield ctx
