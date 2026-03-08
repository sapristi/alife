import os
import subprocess as sp
import json
from dataclasses import dataclass

from experiment.models import Experiment, Log


class StatLogCollector:
    def __init__(self, experiment: Experiment):
        self.entries = []
        self.exp = experiment
        self.last_dump = None

    def _store(self):
        logs = [Log(experiment=self.exp, reac_count=entry["tags"]["reactions"]["counter"], data=entry) for entry in self.entries]
        Log.objects.bulk_create(logs)
        self.entries = []

    def treat(self, line):
        try:
            data = json.loads(line)
        except Exception:
            # Non-JSON line (e.g. plain text warning) — print it
            print(line.strip("\n"))
            return
        if data.get("message") == "Stats":
            self.entries.append(data)
        elif data.get("message") == "dump":
            self.last_dump = data["tags"]["bacterie"]
        elif data.get("level") in ("Error", "Warning"):
            print(line.strip("\n"))

        if len(self.entries) > 1000:
            self._store()

    def finalize(self):
        self._store()

class DumpCaptureHandler:
    """Captures the last dump message and prints everything else."""
    def __init__(self):
        self.last_dump = None

    def treat(self, line):
        try:
            data = json.loads(line)
        except Exception:
            print(line.strip("\n"))
            return
        if data.get("message") == "dump":
            self.last_dump = data["tags"]["bacterie"]
        else:
            print(line.strip("\n"))

    def finalize(self):
        pass

class DisplayLogHandler:
    def treat(self, log_entry):
        print(log_entry.strip("\n"))

    def finalize(self):
        pass

class QuietLogHandler:
    """Only prints warnings and errors."""
    def treat(self, line):
        try:
            data = json.loads(line)
        except Exception:
            print(line.strip("\n"))
            return
        if data.get("level") in ("Error", "Warning"):
            print(line.strip("\n"))

    def finalize(self):
        pass

@dataclass
class YaacException(Exception):
    statuscode: int
    stderr: str


class YaacWrapper:
    def __init__(self, handler = None):
        self.log_handler = handler or DisplayLogHandler()

    def _parse_output(self, process: sp.Popen[str]):
        self._last_line = None
        os.set_blocking(process.stdout.fileno(), False)
        while True:
            line = process.stdout.readline()

            if len(line) != 0:
                self._last_line = line
                self.log_handler.treat(line)

            if process.poll() is not None:
                # Drain remaining output after process exits
                os.set_blocking(process.stdout.fileno(), True)
                for line in process.stdout:
                    self._last_line = line
                    self.log_handler.treat(line)
                self.log_handler.finalize()
                return

    def _kwarg_to_cmd_arg(self, key, value):
        if isinstance(value, dict):
            value = json.dumps(value)
        return f"--{key.replace('_', '-')}={value}"

    def _run_process(self, command, **kwargs):
        full_command = [
            "./yaac",
            command,
            *[self._kwarg_to_cmd_arg(key, value) for key, value in kwargs.items()]
        ]
        # TODO: use select for buffers ?
        # https://stackoverflow.com/questions/1180606/using-subprocess-popen-for-process-with-large-output
        process = sp.Popen(
            full_command,
            stdout=sp.PIPE,
            encoding="utf8",
            env={
                # "JSON_LOG": "true",
                 "STATS": "true"
            }
        )
        self._parse_output(process)
        rc = process.poll()

        if rc != 0:
            raise YaacException(statuscode=rc, stderr=process.stderr)

    def run(self, command, **kwargs):
        self._run_process(command, **kwargs)
        if self._last_line is None:
            return None
        try:
            return json.loads(self._last_line)
        except (json.JSONDecodeError, TypeError):
            return None

yaac = YaacWrapper()
