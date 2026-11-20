<!-- Loads when a file under kaizen/ is read; symlinked into kaizen directories elsewhere. -->

Keep these docs current: when a change affects documented behavior, update the
relevant doc in the same commit.

Track every patch, override, upstream `TODO`, and workaround in
`docs/issues.md`. Add an entry when introducing a workaround, update its status
when upstream merges or releases a fix, and remove the entry in the commit that
drops the workaround.

@README.md
@docs/features.md
@docs/plugins.md
@docs/style.md
@docs/interaction.md
@docs/development.md
@docs/issues.md
