
**Feature freeze (INSERT DATE HERE):**
- [ ] Create and merge version updating pull requests in Math/Stan/Cmdstan. These should be the last PRs accepted before the freeze.
- [ ] Create Math/Stan RC releases.
- [ ] Create Stanc3 RC binary.
- [ ] Create a release candidate tarball for x86. Make sure RC tarballs include stanc3 binaries.
- [ ] Check external links in docs (i.e. TBB docs link)
- [ ] Create a release candidate feature/bugfix list (major features/bugfixes that need testing, link to new docs in Github)
- [ ] Run [CmdStanR tests](https://github.com/stan-dev/cmdstanr/actions/workflows/cmdstan-tarball-check.yaml) with the RC tarball.
- [ ] Run CmdStanPy tests with the RC tarball.
- [ ] Make a Discourse RC post.
- [ ] Post a tweet with a link to the Discourse RC post.

**Release (INSERT DATE HERE):**
- [ ] Create the Math Release notes.
- [ ] Create the Stan Release notes.
- [ ] Create the Cmdstan Release notes.
- [ ] Create the Stanc3 Release notes.
- [ ] Rebuild and publish docs for the new version.
- [ ] Check that docs for the previous release links correctly to the newest docs.
- [ ] Create the Math release.
- [ ] Create the Stan release.
- [ ] Create the Stanc3 release.
- [ ] Create x86 CmdStan tarballs (check version, check that the extracted folder is in the cmdstan-version format).
- [ ] Create non-x86 CmdStan tarballs.
- [ ] Run CmdStanR tests with the release tarball.
- [ ] Make a Stan blog release announcement post (thank the sponsors and all contributors, mention new devs).
- [ ] Link to the blog post in a Discourse thread.
- [ ] Make a Twitter announcement.
