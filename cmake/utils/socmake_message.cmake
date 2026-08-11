#[[[ @module socmake_message
#]]

include_guard(GLOBAL)

#[[[
# Thin wrapper around CMake's built-in `message() <https://cmake.org/cmake/help/latest/command/message.html>`_ command
# that prefixes the message text with ``SoCMake: ``, so that every message emitted by SoCMake follows a uniform,
# easily greppable format (e.g. ``-- SoCMake: <text>`` for a ``STATUS`` message).
#
# It is meant to be used as a drop-in replacement for ``message()`` wherever SoCMake itself reports something to the user::
#
#   socmake_message(STATUS "Doing something")
#   socmake_message(WARNING "Something looks wrong")
#   socmake_message(FATAL_ERROR "Something is wrong")
#
# :param MODE: Message mode, forwarded as-is to ``message()`` (e.g. ``STATUS``, ``WARNING``, ``FATAL_ERROR``, ``DEBUG``).
# :type MODE: string
#]]
macro(socmake_message MODE)
    message(${MODE} "SoCMake: " ${ARGN})
endmacro()
