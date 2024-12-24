"""
Uninstall amllib with pip.

This deletes the linkage to the amllib library.
"""

import sys
import os
import subprocess

subprocess.check_call([sys.executable,
                       '-m',
                       'pip',
                       'uninstall',
                       'amllib'])

# Remove auxilary directory
path = r'./amllib.egg-info/'
os.system('rm -rf ' + path)
