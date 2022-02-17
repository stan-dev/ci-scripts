#!/usr/bin/python

# Script for retrieving release notes from pull requests merged since the last release

import urllib.request, json

repository = "docs"
# release_url = "https://api.github.com/repos/stan-dev/"+repository+"/releases/latest"
# releases = json.loads(urllib.request.urlopen(release_url).read().decode())
last_release_date = "2021-10-18T00:00:00Z"

prs_url = "https://api.github.com/repos/stan-dev/"+repository+"/pulls?state=closed&sort=created&per_page=100&sort=asc&page="


num_of_prs = 0
prs_on_page = 1
current_page = 1
users = {}

# cycle through the pages until you hit a page with no PRs
while prs_on_page > 0:
    tmp_url = prs_url + str(current_page)
    request = urllib.request.Request(tmp_url)
    token = "githubpat"
    request.add_header("Authorization", "Basic %s" % token)
    with urllib.request.urlopen(request) as url:
        prs_info = json.loads(url.read().decode())
        prs_on_page = len(prs_info)
        for pr in prs_info:
            # check if PR was merged
            if pr["merged_at"]:
                # if merged check date
                if pr["merged_at"] > last_release_date:
                    num_of_prs = num_of_prs + 1
                    body = pr["body"]
                    user = pr["user"]["login"]
                    if user in users:
                        users[user] = users[user] + 1
                    else:
                        users[user] = 1
                    parsing_release_notes = False
                    for line in body.split("\r\n"):
                        if parsing_release_notes:
                            if line.find("##") >= 0:
                                parsing_release_notes = False
                        if parsing_release_notes:
                            line = line.strip()
                            if len(line) > 0:
                                print(" - " + line + "(#" + str(pr["number"]) + ")")
                        if line.find("Release notes") >= 0:
                            parsing_release_notes = True
    print(current_page)
    current_page = current_page + 1

print("\nNumber of merged PRs:" + str(num_of_prs))
print(users)