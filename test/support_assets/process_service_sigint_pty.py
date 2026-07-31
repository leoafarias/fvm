#!/usr/bin/env python3
"""Drive the ProcessService SIGINT harness through an isolated POSIX PTY.

Dart's standard library cannot create a controlling PTY, so this helper owns
only the POSIX terminal setup and reports observations back to the Dart test.
"""

import argparse
import errno
import json
import os
import pty
import re
import select
import signal
import sys
import termios
import time

ROLE_ENVIRONMENT_KEY = "FVM_PROCESS_SERVICE_PTY_ROLE"
PARENT_CONTEXT = b"FVM_PTY_TEST:PARENT_CONTEXT:true"
CHILD_READY_PATTERN = re.compile(rb"FVM_PTY_TEST:CHILD_READY:(\d+)")
CHILD_SIGINT = b"FVM_PTY_TEST:CHILD_SIGINT"
CHILD_CLEANUP_DONE = b"FVM_PTY_TEST:CHILD_CLEANUP_DONE"
PARENT_FORCE_EXIT = b"FVM_PTY_TEST:PARENT_FORCE_EXIT:130"


def _read_once(master_fd, output, timeout):
    readable, _, _ = select.select([master_fd], [], [], timeout)
    if not readable:
        return
    try:
        output.extend(os.read(master_fd, 65536))
    except OSError as error:
        if error.errno != errno.EIO:
            raise


def _wait_for(master_fd, output, marker, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if marker in output:
            return
        remaining = max(0.0, deadline - time.monotonic())
        _read_once(master_fd, output, min(0.05, remaining))
    if marker not in output:
        raise RuntimeError(f"Timed out waiting for {marker!r}")


def _process_exists(process_id):
    try:
        os.kill(process_id, 0)
        return True
    except ProcessLookupError:
        return False


def _process_group_exists(process_group_id):
    try:
        os.killpg(process_group_id, 0)
        return True
    except ProcessLookupError:
        return False


def _wait_until(predicate, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(0.02)
    return predicate()


def _configure_terminal(master_fd):
    attributes = termios.tcgetattr(master_fd)
    attributes[0] &= ~termios.ICRNL
    attributes[3] &= ~(termios.ICANON | termios.ECHO)
    attributes[3] |= termios.ISIG
    attributes[6][termios.VINTR] = b"\x03"
    termios.tcsetattr(master_fd, termios.TCSANOW, attributes)


def _run(args):
    parent_pid, master_fd = pty.fork()
    if parent_pid == 0:
        environment = os.environ.copy()
        environment[ROLE_ENVIRONMENT_KEY] = "parent"
        os.chdir(args.cwd)
        os.execve(args.dart, [args.dart, args.harness], environment)

    output = bytearray()
    parent_reaped = False
    parent_status = None

    try:
        os.set_blocking(master_fd, False)
        _configure_terminal(master_fd)

        _wait_for(master_fd, output, PARENT_CONTEXT, 20)
        if os.tcgetpgrp(master_fd) != parent_pid:
            raise RuntimeError("Dart parent is not the PTY foreground process group")

        _wait_for(master_fd, output, b"FVM_PTY_TEST:CHILD_READY:", 20)
        child_match = CHILD_READY_PATTERN.search(output)
        if child_match is None:
            raise RuntimeError("Could not parse the fake Flutter child PID")
        child_pid = int(child_match.group(1))

        os.write(master_fd, b"\x03")
        _wait_for(master_fd, output, CHILD_SIGINT, 5)

        _wait_for(master_fd, output, CHILD_CLEANUP_DONE, 5)
        terminal_attributes = termios.tcgetattr(master_fd)
        child_restored_terminal = bool(
            terminal_attributes[3] & termios.ICANON
        ) and bool(terminal_attributes[3] & termios.ECHO)

        _wait_for(master_fd, output, PARENT_FORCE_EXIT, 5)
        cleanup_position = output.index(CHILD_CLEANUP_DONE)
        force_exit_position = output.index(PARENT_FORCE_EXIT)
        force_exit_after_cleanup = cleanup_position < force_exit_position

        deadline = time.monotonic() + 5
        while not parent_reaped and time.monotonic() < deadline:
            _read_once(master_fd, output, 0.05)
            waited_pid, waited_status = os.waitpid(parent_pid, os.WNOHANG)
            if waited_pid != 0:
                parent_reaped = True
                parent_status = waited_status

        if not parent_reaped or parent_status is None:
            raise RuntimeError("Timed out waiting for the Dart parent to exit")

        child_gone = _wait_until(lambda: not _process_exists(child_pid), 2)
        process_group_gone = _wait_until(
            lambda: not _process_group_exists(parent_pid),
            2,
        )
        parent_exit_code = (
            os.WEXITSTATUS(parent_status) if os.WIFEXITED(parent_status) else None
        )

        return {
            "forceExitAfterCleanup": force_exit_after_cleanup,
            "childRestoredTerminal": child_restored_terminal,
            "childGone": child_gone,
            "processGroupGone": process_group_gone,
            "parentExitCode": parent_exit_code,
        }
    except Exception as error:
        transcript = repr(bytes(output))
        raise RuntimeError(f"{error}\nPTY transcript: {transcript}") from error
    finally:
        try:
            os.killpg(parent_pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        try:
            os.close(master_fd)
        except OSError:
            pass
        if not parent_reaped:
            try:
                os.waitpid(parent_pid, 0)
            except ChildProcessError:
                pass


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--dart", required=True)
    parser.add_argument("--harness", required=True)
    parser.add_argument("--cwd", required=True)
    args = parser.parse_args()

    try:
        report = _run(args)
    except Exception as error:
        print(error, file=sys.stderr)
        return 1

    print(json.dumps(report, sort_keys=True))
    return 0


if __name__ == "__main__":
    sys.exit(main())
