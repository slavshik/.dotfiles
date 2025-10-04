# #!/bin/bash

URL=`git remote get-url origin`

# Check if a URL is provided
if [ -z "$URL" ]; then
  echo "Usage: $0 <url>"
  exit 1
fi

# Check if the URL contains '*.evolution.com'
if [[ "$URL" == ".evolution.com" ]]; then
  echo "URL matches *.evolution.com. Running ./evolution/aicommit.sh"
  ./evolution/aicommit.sh
else
  echo "URL does not match *.evolution.com. Running ./aicommit.sh"
  ./aicommit.sh
fi
