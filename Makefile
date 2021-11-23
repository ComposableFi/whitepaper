clean:
	rm -rf dist

dist:
	./scripts/build.sh

dist_md:
	./scripts/build_md.sh