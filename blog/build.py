#!/usr/bin/env python
import baker
import os
import subprocess

@baker.command
def watch(rebuild=False):
    build(rebuild)
    subprocess.run(["stack exec site watch"], shell=True)

@baker.command
def build(rebuild=False):
    subprocess.run(["stack build; stack exec site {}".format('rebuild' if rebuild else 'build')], shell=True)

@baker.command
def org_to_markdown(file):
    dir, base_ext = os.path.split(file)
    base, ext = os.path.splitext(base_ext)

    if ext != ".org":
        print("{} is not a org-file".format(file))
    if os.path.exists(file) != True:
        print("{} does not exist?".format(file))

    new_filepath = os.path.join(dir.replace("org", "markdown"), base + ".md")
    with open(new_filepath, 'w') as outfile:
        subprocess.run(" ".join(["emacs", file, "-Q", "--batch", "-f", "org-md-export-as-markdown", '--eval="(princ (buffer-string))"']), stdout=outfile, shell=True)

baker.run()
    
