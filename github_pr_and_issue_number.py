#!/usr/bin/python

import json
import sys

if __name__ == "__main__":
    issues = json.load(sys.stdin)
    pr, i = None, None
    for issue in issues:
        if pr and i:
            break
        if 'pull_request' in issue:
            pr = issue['number']
        else:
            i = issue['number']
    print pr
    print i
