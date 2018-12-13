#!/bin/sh

set -e

[ -z "${GITHUB_PAT}" ] && exit 0
[ "${TRAVIS_BRANCH}" != "dev" ] && exit 0

git config --global user.email "michael.rustler@kompetenz-wasser.de"
git config --global user.name "Michael Rustler"

git clone -b master \
  https://${GITHUB_PAT}@github.com/${TRAVIS_REPO_SLUG}.git \
  website-output
cd website-output
git rm -rf *
cp -r ../public/* ./
git add --all *
git commit -m "Update the website" || true
git push -q origin master
