#!/bin/sh
set -e

# first arg is `pwsh` or similar
if ! { [ "$1" = 'pwsh' ] || [ "$1" = 'pwsh-preview' ] || [ "$1" = '/bin/bash' ] || [ "$1" = '/bin/sh' ] || [ "$1" = 'bash' ] || [ "$1" = 'sh' ]; }; then
 set -- pwsh -nologo -l -c "$@"
fi

exec "$@"
