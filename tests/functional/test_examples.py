# Functional tests using examples
# Copyright (C) 2020  Ngô Ngọc Đức Huy
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

from os import environ
from os.path import abspath, dirname, join
from platform import system
from random import choices
from subprocess import PIPE, run, CalledProcessError
from sys import executable
from uuid import uuid4

from palace import reverb_preset_names
from pytest import mark, raises

EXAMPLES = abspath(join(dirname(__file__), '..', '..', 'examples'))
EVENT = join(EXAMPLES, 'palace-event.py')
HRTF = join(EXAMPLES, 'palace-hrtf.py')
INFO = join(EXAMPLES, 'palace-info.py')
LATENCY = join(EXAMPLES, 'palace-latency.py')
REVERB = join(EXAMPLES, 'palace-reverb.py')
STDEC = join(EXAMPLES, 'palace-stdec.py')
TONEGEN = join(EXAMPLES, 'palace-tonegen.py')

MADEUP_DEVICE = str(uuid4())
REVERB_PRESETS = choices(reverb_preset_names, k=5)
WAVEFORMS = ['sine', 'square', 'sawtooth',
             'triangle', 'impulse', 'white-noise']

travis_macos = bool(environ.get('TRAVIS')) and system() == 'Darwin'
skipif_travis_macos = mark.skipif(travis_macos, reason='Travis CI for macOS')


def capture(*argv):
    """Return the captured standard output of given Python script."""
    return run([executable, *argv], stdout=PIPE).stdout.decode()


@skipif_travis_macos
def test_event(aiff, flac, mp3, ogg, wav):
    """Test the event handling example."""
    event = capture(EVENT, aiff, flac, mp3, ogg, wav)
    assert 'Opened' in event
    assert f'Playing {aiff}' in event
    assert f'Playing {flac}' in event
    assert f'Playing {mp3}' in event
    assert f'Playing {ogg}' in event
    assert f'Playing {wav}' in event


@skipif_travis_macos
def test_hrtf(ogg):
    """Test the HRTF example."""
    hrtf = capture(HRTF, ogg)
    assert 'Opened' in hrtf
    assert f'Playing {ogg}' in hrtf


def test_info():
    """Test the information query example."""
    run([executable, INFO], check=True)
    with raises(CalledProcessError):
        run([executable, INFO, MADEUP_DEVICE], check=True)


@skipif_travis_macos
def test_latency(mp3):
    """Test the latency example."""
    latency = capture(LATENCY, mp3)
    assert 'Opened' in latency
    assert f'Playing {mp3}' in latency
    assert 'Offset' in latency


@skipif_travis_macos
@mark.parametrize('preset', REVERB_PRESETS)
def test_reverb(preset, flac):
    """Test the reverb example."""
    reverb = capture(REVERB, flac, '-r', preset)
    assert 'Opened' in reverb
    assert f'Playing {flac}' in reverb
    assert f'Loading reverb preset {preset}' in reverb


@skipif_travis_macos
def test_stdec(aiff):
    """Test the stdec example."""
    stdec = capture(STDEC, aiff)
    assert 'Opened' in stdec
    assert f'Playing {aiff}' in stdec


@mark.parametrize('waveform', WAVEFORMS)
def test_tonegen(waveform):
    """Test the tonegen example."""
    tonegen = capture(TONEGEN, '-l', '0.1', '-w', waveform)
    assert 'Opened' in tonegen
    assert f'Playing {waveform}' in tonegen
