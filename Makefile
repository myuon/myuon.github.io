watch:
	hugo server --buildDrafts --bind 172.27.16.166

build:
	hugo

publish: build
	git add docs && git commit -m 'build: html'
	git subtree push --prefix docs/ origin master

