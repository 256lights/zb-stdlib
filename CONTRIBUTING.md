# How to Contribute

zb is still in an early stage of development.
If you have ideas or feedback, feel free to [start a discussion](https://github.com/256lights/zb/discussions).
If you like zb, consider giving the repository a star
and/or [sponsoring @zombiezen](https://github.com/sponsors/zombiezen).

## Contributing Code

zb is open to accepting contributions.
If your change is minor,
please feel free to submit a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests).
If your change is larger, or adds a feature,
please [start a discussion](https://github.com/256lights/zb/discussions) beforehand
so that we can discuss the change.
You're welcome to file an implementation pull request immediately as well,
although we generally lean towards discussing the change
and then reviewing the implementation separately.

### Finding something to work on

If you want to write some code,
but don't know where to start or what you might want to do,
take a look at the [Good First Issue label](https://github.com/256lights/zb-stdlib/labels/good%20first%20issue)
or the [Help Wanted label](https://github.com/256lights/zb-stdlib/labels/help%20wanted).
The latter is where you can find issues we would like to address,
but can't currently find time for or require skills we don't have.
See if any of the latest ones look interesting!
If you need help before you can start work,
you can comment on the issue,
and we will try to help as best we can.

### Making a pull request

- Follow the normal [pull request flow](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request).
- Feel free to make as many commits as you want;
  we will squash them all into a single commit
  before merging your change.
- Check the diffs, write a useful description
  (including something like `Fixes #123` if it's fixing a bug)
  and send the PR out.

### Code review

All submissions require review.
It is almost never the case that a pull request is accepted without some changes requested,
so please do not be offended!

When you have finished making requested changes to your pull request,
please make a comment containing "PTAL" (Please Take Another Look) on your pull request.
GitHub notifications can be noisy,
and it is unfortunately easy for things to be lost in the shuffle.

Once your PR is approved (hooray!),
the reviewer will squash your commits into a single commit
and then merge the commit onto the main branch.
Thank you!

## Github code review workflow conventions

(For project members and frequent contributors.)

As a contributor:

- Try hard to make each Pull Request as small and focused as possible.
  In particular, this means that if a reviewer asks you to do something
  that is beyond the scope of the Pull Request,
  the best practice is to file another issue
  and reference it from the Pull Request
  rather than just adding more commits to the existing PR.
- Make as many commits as you want locally,
  but try not to push them to Github until you've addressed comments;
  this allows the email notification about the push
  to be a signal to reviewers that the PR is ready to be looked at again.
- When there may be confusion about what should happen next for a PR, be explicit;
  add a "PTAL" comment if it is ready for review again,
  or a "Please hold off on reviewing for now"
  if you are still working on addressing comments.
- "Resolve" comments that you are sure you've addressed;
  let your reviewers resolve ones that you're not sure about.
- Do not use `git push --force`;
  this can cause comments from your reviewers that are associated with a specific commit to be lost.
  This implies that once you've sent a Pull Request,
  you should use `git merge` instead of `git rebase` to incorporate commits from the main branch.

As a reviewer:

- Be timely in your review process, especially if you are an Assignee.
- Try to use `Start a Review` instead of single comments,
  to reduce email noise.
- "Resolve" your own comments if they have been addressed.

When squashing-and-merging:

- Do a final review of the one-line PR summary,
  ensuring that it accurately describes the change.
- Delete the automatically added commit lines;
  these are generally not interesting
  and make commit history harder to read.
