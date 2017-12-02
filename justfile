watch: build
  cd blog && stack exec site watch

build:
  cd blog && stack build && stack exec site build

publish:
  cd public && git add . && git commit -m 'build' && git push origin master

