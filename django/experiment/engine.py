import os
import subprocess as sp
import json
from dataclasses import dataclass

from experiment.models import Experiment, Log


class StatLogCollector:
    def __init__(self, experiment: Experiment):
        self.entries = []
        self.exp = experiment

    def _store(self):
        logs = [Log(experiment=self.exp, reac_count=entry["tags"]["reactions"]["counter"], data=entry) for entry in self.entries]
        Log.objects.bulk_create(logs)
        self.entries = []

    def treat(self, line):
        try:
            data = json.loads(line)
        except Exception:
            print(line.strip("\n"))
            return
        if data.get("message") == "Stats":
            self.entries.append(data)
        else:
            print(line.strip("\n"))
            return

        if len(self.entries) > 1000:
            self._store()

    def finalize(self):
        self._store()

class DisplayLogHandler:
    def treat(self, log_entry):
        print(log_entry.strip("\n"))

    def finalize(self):
        pass

@dataclass
class YaacException(Exception):
    statuscode: int
    stderr: str


class YaacWrapper:
    def __init__(self, handler = None):
        self.log_handler = handler or DisplayLogHandler()

    def parse_output(self, process: sp.Popen[str]):
        os.set_blocking(process.stdout.fileno(), False)
        while True:
            line=process.stdout.readline()

            if len(line) != 0:
                self._last_line = line

            if process.poll() is not None:
                self.log_handler.finalize()
                return self._last_line

            if len(line) != 0:
                self.log_handler.treat(line)

    def run(self, command, **kwargs):
        full_command = [
            "./yaac",
            command,
            *[f"--{key.replace('_', '-')}={value}" for key, value in kwargs.items()]
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
        output = self.parse_output(process)
        rc = process.poll()

        if rc != 0:
            raise YaacException(statuscode=rc, stderr=process.stderr)

        res_data = json.loads(output)
        return res_data

yaac = YaacWrapper()
