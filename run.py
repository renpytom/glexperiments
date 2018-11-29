#!/usr/bin/env python

import subprocess
import sys

subprocess.check_call([ "python", "setup.py", "build_ext", "-q", "-i" ])

sys.argv.pop(0)
m = __import__(sys.argv[0]).main()
