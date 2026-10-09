# Frequencies

The source of [frequencies.vpavlin.xyz](https://frequencies.vpavlin.xyz): **Scala**, the
local-first shared calendar, for Android and Basecamp. It is the Scala-only cut of
[apps.vpavlin.xyz](https://apps.vpavlin.xyz).

- **Basecamp:** add `https://frequencies.vpavlin.xyz/logos-repo.json` as a package repository.
  It lists Scala and the modules it needs (newest version of each); the packages themselves
  are downloaded from their GitHub release assets.
- **Android:** add the F-Droid repo linked on the page. It holds only Scala and is signed with
  the same key as apps.vpavlin.xyz's repo
  (`2373710A76ACB09F287F053E99E533F9D3685529C44E9027CDBC79B1DC0C9105`).

## Updating

After a Scala release is on apps.vpavlin.xyz, run `scripts/sync.sh`, commit and push. The
`Build site` workflow rebuilds the page, copies the APKs from apps.vpavlin.xyz (checked against
the signed index) and deploys to GitHub Pages.

Licensed under MIT or Apache-2.0.
