watch:
	hugo server --buildDrafts

build:
	hugo

publish: build
	git add docs && git commit -m 'build: html'
	git subtree push --prefix docs/ origin master

