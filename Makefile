.PHONY: test pack metadata

TRANSLATIONS := $(wildcard 42/media/lua/shared/Translate/*/*.json)

test:
	@jq -e -s 'all(.[]; all(to_entries[]; (.value | gsub("%%|%[1-9]"; "") | contains("%") | not)))' $(TRANSLATIONS) >/dev/null
	@./tests/run-tests.sh

metadata:
	python3 sync_description.py DESCRIPTION dist/workshop.txt

# dist/ is the workshop publication root: preview.png (page preview) and the
# mod payload are refreshed by pack; workshop.txt (pub metadata) is
# regenerated from the workspace DESCRIPTION file by `make metadata`.
pack: metadata
	rm -rf dist/Contents/mods/BetterGunJam/41 dist/Contents/mods/BetterGunJam/42
	mkdir -p dist/Contents/mods/BetterGunJam
	cp -r 41 dist/Contents/mods/BetterGunJam/
	cp -r 42 dist/Contents/mods/BetterGunJam/
	cp preview.png dist/preview.png