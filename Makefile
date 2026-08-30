.PHONY: test dist metadata

TRANSLATIONS := $(wildcard 42/media/lua/shared/Translate/*/*.json)
DIST_WORKSHOP := dist_workshop

test:
	@jq -e -s 'all(.[]; all(to_entries[]; (.value | gsub("%%|%[1-9]"; "") | contains("%") | not)))' $(TRANSLATIONS) >/dev/null
	@./tests/run-tests.sh

metadata:
	python3 sync_description.py DESCRIPTION $(DIST_WORKSHOP)/workshop.txt

# $(DIST_WORKSHOP)/ is the workshop publication root: preview.png (page preview)
# and the mod payload are refreshed by `make dist`; workshop.txt (pub
# metadata) is regenerated from the workspace DESCRIPTION file by
# `make metadata`.
dist: metadata
	mkdir -p $(DIST_WORKSHOP)/Contents/mods/BetterGunJam
	rm -rf $(DIST_WORKSHOP)/Contents/mods/BetterGunJam/*
	cp -r 41 $(DIST_WORKSHOP)/Contents/mods/BetterGunJam/
	cp -r 42 $(DIST_WORKSHOP)/Contents/mods/BetterGunJam/
	cp LICENSE $(DIST_WORKSHOP)/Contents/mods/BetterGunJam/
	cp preview.png $(DIST_WORKSHOP)/preview.png