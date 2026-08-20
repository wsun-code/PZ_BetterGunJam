.PHONY: test pack

test:
	@./tests/run-tests.sh

dist_dir: dist
	@mkdir -p dist

pack: dist_dir
	rm -rf ./dist/41 ./dist/42
	cp -r 42 ./dist/
	cp -r 41 ./dist/
