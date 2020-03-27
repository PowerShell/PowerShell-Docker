#!/bin/sh
set -e

# first arg is `pwsh` or similar
if ! { [ $1 = 'pwsh' ] || [ $1 = 'pwsh-preview' ]; }; then
 set -- pwsh -nologo -l -c "$@"
fi

exec "$@"