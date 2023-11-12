import subprocess as sp
import json


class YaacWrapper:
    def run(self, command, **kwargs):
        full_command = [
            "./yaac",
            command,
            *[f"--{key.replace('_', '-')}={value}" for key, value in kwargs.items()]
        ]
        p = sp.run(
            full_command,
            capture_output=True,
            encoding="utf8",
        )
        if p.returncode != 0:
            print("FAILED :(")
            print("Command", command)
            print(p.stdout)
            print(p.stderr)
            return None

        output = p.stdout.splitlines()
        logs = output[:-1]
        print("\n".join(logs))
        res_data = json.loads(output[-1])
        return res_data

yaac = YaacWrapper()
