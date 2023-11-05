import subprocess as sp
import json


class YaacWrapper:
    def run(self, command, **kwargs):
        full_command = [
            "./yaac",
            command,
            *[f"--{key.replace('_', '-')}={value}" for key, value in kwargs.items()]
        ]
        print("COMMAND", full_command)
        p = sp.run(
            full_command,
            capture_output=True,
            encoding="utf8",
        )
        if p.returncode != 0:
            print("FAILED :(")
            print(p.stdout)
            print(p.stderr)
            return None
        else:
            last_line = p.stdout.splitlines()[-1]
            return json.loads(last_line)

yaac = YaacWrapper()
