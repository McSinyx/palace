# Functional pytest module
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
import pytest
import subprocess
from os.path import abspath, dirname, join
from random import choices
from subprocess import run
from sys import executable

EVENT = join(abspath(dirname(__file__)), 'palace-event.py')
HRTF = join(abspath(dirname(__file__)), 'palace-hrtf.py')
INFO = join(abspath(dirname(__file__)), 'palace-info.py')
LATENCY = join(abspath(dirname(__file__)), 'palace-latency.py')
REVERB = join(abspath(dirname(__file__)), 'palace-reverb.py')
STDEC = join(abspath(dirname(__file__)), 'palace-stdec.py')
TONEGEN = join(abspath(dirname(__file__)), 'palace-tonegen.py')
WAV = abspath(join(dirname(__file__), '..', 'data',
                   'Dying-Robot-SoundBible.com-1721415199.wav'))
WAVEFORMS = ['sine', 'square', 'sawtooth',
             'triangle', 'impulse', 'white-noise']


def test_event():
    event = run([executable, EVENT, WAV], stdout=subprocess.PIPE)
    assert b'Opened' in event.stdout
    assert b'Playing' in event.stdout


def test_hrtf():
    hrtf = run([executable, HRTF, WAV], stdout=subprocess.PIPE)
    assert b'Opened' in hrtf.stdout
    assert b'Playing' in hrtf.stdout


def test_info():
    info = run([executable, INFO], stdout=subprocess.PIPE)
    assert b'Available basic devices' in info.stdout
    assert b'Available devices' in info.stdout
    assert b'Available capture devices' in info.stdout
    assert b'Info of device' in info.stdout
    assert b'ALC version' in info.stdout
    assert b'Available resamplers' in info.stdout
    assert b'EFX version' in info.stdout
    assert b'Max auxiliary sends' in info.stdout
    assert b'with the first being default' in info.stdout


def test_latency():
    latency = run([executable, LATENCY, WAV], stdout=subprocess.PIPE)
    assert b'Opened' in latency.stdout
    assert b'Playing' in latency.stdout
    assert b'Offset' in latency.stdout


def test_reverb():
    reverbs = run([executable, REVERB, '-p'], stdout=subprocess.PIPE)
    assert b'Available reverb preset names:' in reverbs.stdout
    fxs = reverbs.stdout.split(b'\n')[1:-1]
    fxs = choices(fxs, k=5)
    for fx in fxs:
        rv = run([executable, REVERB, '-r', fx, WAV], stdout=subprocess.PIPE)
        assert b'Opened' in rv.stdout
        assert b'Playing' in rv.stdout
        assert fx in rv.stdout


def test_stdec():
    stdec = run([executable, STDEC, WAV], stdout=subprocess.PIPE)
    assert b'Opened' in stdec.stdout
    assert b'Playing' in stdec.stdout


@pytest.mark.parametrize('waveform', WAVEFORMS)
def test_tonegen(waveform):
    tonegen = run([executable, TONEGEN, '-w', waveform],
                  stdout=subprocess.PIPE)
    assert b'Opened' in tonegen.stdout
    assert b'Playing' in tonegen.stdout
    assert waveform.encode() in tonegen.stdout
