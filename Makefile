watch:
	hugo server --buildDrafts --bind 172.27.16.166

publish:
	git subtree push --prefix docs/ origin master

