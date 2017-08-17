watch: build
  stack exec site watch

build:
  stack build
  stack exec site build

publish:
  cd blog/_site
  git add .
  git commit -m 'build'
  git push

