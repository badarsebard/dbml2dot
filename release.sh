#!/bin/bash

version="$1"; shift
message="$@"

if [ -z "$version" ]; then
	echo "Version must not be empty"
	exit 1
fi
if [ -z "$message" ]; then
	echo "Message must not be empty"
	exit 1
fi
pip install --upgrade .

rm -Rvf dist/

python setup.py sdist
python setup.py bdist_wheel

gpg --detach-sign -a dist/dbmlviz-$version.tar.gz

git tag --sign --message "$message" "v${version}"
git push --tags
twine upload dist/dbmlviz-$version.tar.gz dist/dbmlviz-$version.tar.gz.asc
