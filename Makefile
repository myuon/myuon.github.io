watch:
	hugo server --buildDrafts --bind 172.27.16.166

build:
	hugo

publish: build
	git subtree push --prefix docs/ origin master

