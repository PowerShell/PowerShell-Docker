#!/bin/sh
set -e

# first arg is `pwsh` or similar
if [ $1 = 'pwsh' ] || [ $1 = 'pwsh-preview' ]; then
 # using this as a no-op
 set -e
else
 set -- pwsh -nologo -l -c "$@"
fi

exec "$@"