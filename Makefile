.PHONY: test

test:
	@./tests/run-tests.sh

dist_dir: dist
	@mkdir -p dist

pack: dist_dir
	cp -r media mod.info preview.png ./dist/
