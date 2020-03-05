# Source pytest module
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

"""This pytest module tries to test the correctness of the class Context."""

from palace import current_context, Context, MessageHandler


def test_with_context(device):
    """Test if `with` can be used to start a context
    and is destroyed properly.
    """
    with Context(device) as context:
        assert current_context() == context


def test_nested_context_manager(device):
    """Test if the context manager returns to the
    previous context.
    """
    with Context(device) as context:
        with Context(device): pass
        assert current_context() == context


def test_message_handler(device):
    """Test read-write property MessageHandler."""
    context = Context(device)
    assert type(context.message_handler) is MessageHandler
    message_handler_test = type('MessageHandlerTest', (MessageHandler,), {})()
    context.message_handler = message_handler_test
    assert context.message_handler is message_handler_test
    with context:
        assert current_context().message_handler is context.message_handler
