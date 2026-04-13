# Contributing to Beacon

## Adding a tech pack

1. Copy `templates/tech-pack.template.md` to `technologies/{framework}/{version}.md`
2. Fill in all 10 required sections (schema validation will reject incomplete packs)
3. Test against at least one real site using that framework
4. Open a PR with title `feat(tech-packs): add {framework} {version}`

All contributions require a `Signed-off-by` DCO trailer:
```
git commit -s -m "feat(tech-packs): add astro 5.x"
```

## Improving a skill

Install the bundled dev plugins (see `.claude/plugins/README.md`), then:
```
invoke skill-creator
```

## Updating a script

Scripts in `scripts/` must have their SHA256 updated in `scripts/checksums.sha256` after any change.

## License

MIT. By contributing you agree to license your work under MIT and sign off via DCO.
