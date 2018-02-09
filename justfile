watch:
  hugo server --buildDrafts

publish:
  cd public && git add . && git commit -m 'build' && git push origin master

