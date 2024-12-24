"""
Install amllib with pip as editable package

This creates a link to the library location
and allows loading the library from arbitrary
directories without editing sys.path or copying
the library to these directories.

Changes in the source code are available directly,
since pip just links to the source code.
"""

import sys
import subprocess

subprocess.check_call([sys.executable,
                       '-m',
                       'pip',
                       'install',
                       '-e',
                       '.'])
