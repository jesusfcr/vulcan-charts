#!/bin/bash

eval $(ssh-agent -s)
echo $ID_RSA | base64 -d | ssh-add -

mkdir $HOME/pages
helm package ./stable/* --destination $HOME/pages

git stash -u

git config --global url.ssh://git@github.com/.insteadOf https://github.com/

git checkout gh-pages

mv -f $HOME/pages/*.tgz .
if [[ -z `git status -s` ]]; then
    echo "tree is clean"
else
    echo "Publish charts"
    helm repo index . --url https://adevinta.github.io/vulcan-charts
    git add .
    git commit -m "$TRAVIS_COMMIT_MESSAGE"
    git push origin gh-pages
fi
