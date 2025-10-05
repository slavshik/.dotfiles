# #!/bin/bash

URL=`git remote get-url origin`

# Check if a URL is provided
if [ -z "$URL" ]; then
  echo "Usage: $0 <url>"
  exit 1
fi

# Check if the URL contains '*.evolution.com'
if [[ "$URL" == ".evolution.com" ]]; then
  ./evolution/aicommit.sh
else
  ./aicommit.sh
fi
