#!/usr/bin/python

# Script for retrieving release notes from pull requests merged since the last release

import datetime
import urllib.request
import json
import argparse
import os

parser = argparse.ArgumentParser(description='Get release notes from merged PRs since last release')
parser.add_argument("repo", help="repository name")
parser.add_argument("--time", help="time of last release", default="fetch")

args = parser.parse_args()
repository = args.repo

REPO_PR_FORMAT = {"stanc3": "Release notes",
                  "math": "Release notes",
                  "stan": "Summary",
                  "cmdstan": "Summary",}

try:
    TOKEN = os.environ["GITHUB_TOKEN"]
    header = {"Authorization":"Bearer " + TOKEN}
except:
    print("No GITHUB_TOKEN environment variable found. This mail fail if you hit the rate limit.")
    header = {}

if args.time == "fetch":
    release_url = "https://api.github.com/repos/stan-dev/"+repository+"/releases/latest"
    request = urllib.request.Request(release_url, headers=header)
    releases = json.loads(urllib.request.urlopen(request).read().decode())
    last_release_date = releases["published_at"]
else:
    last_release_date = datetime.datetime.fromisoformat(args.time).isoformat()


prs_url = "https://api.github.com/repos/stan-dev/"+repository+"/pulls?state=closed&sort=created&per_page=100&sort=asc&page="

print("Release notes for", repository, "since", last_release_date)

num_of_prs = 0
prs_on_page = 1
current_page = 1
# cycle through the pages until you hit a page with no PRs
while prs_on_page > 0:
    tmp_url = prs_url + str(current_page)
    request = urllib.request.Request(tmp_url, headers=header)
    text = urllib.request.urlopen(request).read().decode()
    prs_info = json.loads(text)
    prs_on_page = len(prs_info)
    for pr in prs_info:
        # check if PR was merged
        if pr["merged_at"]:
            # if merged check date
            if pr["merged_at"] > last_release_date:
                num_of_prs = num_of_prs + 1
                body = pr["body"]
                if REPO_PR_FORMAT[repository] in body:
                    parsing_release_notes = False
                    for line in body.split("\r\n"):
                        if parsing_release_notes:
                            if line.find("##") >= 0:
                                parsing_release_notes = False
                        if parsing_release_notes:
                            line = line.strip()
                            if len(line) > 0:
                                print(" - " + line + " (#" + str(pr["number"]) + ")")
                        if line.find(REPO_PR_FORMAT[repository]) >= 0:
                            parsing_release_notes = True
                else:
                    print(" - " + pr['title'] + " (#" + str(pr['number']) +")")

    current_page = current_page + 1

print("\nNumber of merged PRs:" + str(num_of_prs))
