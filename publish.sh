#!/bin/bash

rm -rf ./_book
gitbook build
mkdir ./_book/ebook
gitbook pdf ./ ./_book/ebook/React模式.pdf
gitbook mobi ./ ./_book/ebook/React模式.mobi
gitbook epub ./ ./_book/ebook/React模式.epub
git checkout gh-pages
git pull origin gh-pages
cp -rf ./_book/* ./
git add .
git commit -m 'chore(docs): regenerated book'
git push origin gh-pages
git checkout master