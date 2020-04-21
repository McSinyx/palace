# single-precision floating-point math
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

"""This module provides access to mathematical functions
for single-precision floating-point numbers.
"""
__all__ = ['FLT_MAX', 'allclose', 'isclose']

from math import isclose as _isclose
from typing import Sequence

FLT_EPSILON: float = 2.0 ** -23
FLT_MAX: float = 2.0**128 - 2.0**104


def isclose(a: float, b: float) -> bool:
    """Determine whether two single-precision floating-point numbers
    are close in value.

    For the values to be considered close, the relative difference
    between them must be smaller than FLT_EPSILON.

    -inf, inf and NaN behave similarly to the IEEE 754 Standard.
    That is, NaN is not close to anything, even itself.
    inf and -inf are only close to themselves.
    """
    return _isclose(a, b, rel_tol=FLT_EPSILON)


def allclose(a: Sequence[float], b: Sequence[float]) -> bool:
    """Determine whether two sequences of single-precision
    floating-point numbers are close in value.

    For the values to be considered close, the relative difference
    between them must be smaller than FLT_EPSILON.

    -inf, inf and NaN behave similarly to the IEEE 754 Standard.
    That is, NaN is not close to anything, even itself.
    inf and -inf are only close to themselves.
    """
    return all(map(isclose, a, b))
