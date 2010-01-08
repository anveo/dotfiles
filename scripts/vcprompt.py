#!/usr/bin/env python
from __future__ import with_statement
import os
import re
import sqlite3
import sys
from subprocess import Popen, PIPE

UNKNOWN = "(unknown)"
SYSTEMS = []


def vcs(function):
    """Simple decorator which adds the wrapped function to SYSTEMS variable"""
    SYSTEMS.append(function)
    return function


def vcprompt(path=None):
    paths = (path or os.getcwd()).split('/')

    while paths:
        path = "/".join(paths)
        prompt = ''
        for vcs in SYSTEMS:
            prompt = vcs(path)
            if prompt:
                return prompt
        paths.pop()
    return ""


@vcs
def bzr(path):
    file = os.path.join(path, '.bzr/branch/last-revision')
    if not os.path.exists(file):
        return None
    with open(file, 'r') as f:
        line = f.read().split(' ', 1)[0]
        return 'bzr:r' + (line or UNKNOWN)


@vcs
def cvs(path):
    # Stabbing in the dark here
    # TODO make this not suck
    file = os.path.join(path, 'CVS/')
    if not os.path.exists(file):
        return None
    return "cvs:%s" % UNKNOWN


@vcs
def fossil(path):
    # In my five minutes of playing with Fossil this looks OK
    file = os.path.join(path, '_FOSSIL_')
    if not os.path.exists(file):
        return None

    repo = UNKNOWN
    conn = sqlite3.connect(file)
    c = conn.cursor()
    repo = c.execute("""SELECT * FROM
                        vvar WHERE
                        name = 'repository' """)
    conn.close()
    repo = repo.fetchone()[1].split('/')[-1]
    return "fossil:" + repo


@vcs
def hg(path):
    files = ['.hg/branch', '.hg/undo.branch']
    file = None
    for f in files:
        f = os.path.join(path, f)
        if os.path.exists(f):
            file = f
            break
    if not file:
        return None
    with open(file, 'r') as f:
        line = f.read().strip()
        return 'hg:' + (line or UNKNOWN)

@vcs
def git(path):
    prompt = "git:"
    branch = UNKNOWN
    file = os.path.join(path, '.git/HEAD')
    if not os.path.exists(file):
        return None

    with open(file, 'r') as f:
        line = f.read()
        if re.match('^ref: refs/heads/', line.strip()):
            branch = (line.split('/')[-1] or UNKNOWN).strip()
    return prompt + branch


@vcs
def svn(path):
    revision = UNKNOWN
    file = os.path.join(path, '.svn/entries')
    if not os.path.exists(file):
        return None
    with open(file, 'r') as f:
        previous_line = ""
        for line in f:
            line = line.strip()
            # In SVN's entries file, the first set of digits is
            # the version number. The second is the revision.
            if re.match('(\d+)', line):
                if re.match('dir', previous_line):
                    revision = "r%s" % line
                    break
            previous_line = line
    return 'svn:%s' % revision


if __name__ == '__main__':
    sys.stdout.write(vcprompt())
