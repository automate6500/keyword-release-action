#!/bin/bash
set -e

if [ -n "$GITHUB_EVENT_PATH" ];
then
    EVENT_PATH=$GITHUB_EVENT_PATH
elif [ -f ./sample_push_event.json ];
then
    EVENT_PATH='./sample_push_event.json'
    LOCAL_TEST=1
else
    echo "No JSON data to process! :("
    exit 1
fi

env
jq . < $EVENT_PATH

# if keyword is found
if jq '.commits[].message, .head_commit.message' < $EVENT_PATH | grep -i -q "$*";
then
    # do something
    VERSION=$(date +%F.%s)

    DATA="$(printf '{"tag_name":"v%s",' "$VERSION")"
    DATA="${DATA} $(printf '"target_commitish":"master",')"
    DATA="${DATA} $(printf '"name":"v%s",' "$VERSION")"
    DATA="${DATA} $(printf '"body":"Automated release based on keyword: %s",' "$*")"
    DATA="${DATA} $(printf '"draft":false, "prerelease":false}')"

    # https://developer.github.com/changes/2020-02-10-deprecating-auth-through-query-param/
    # URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases?access_token=${GITHUB_TOKEN}"
    URL="https://api.github.com/repos/${GITHUB_REPOSITORY}/releases"

    if ((LOCAL_TEST)); then
        echo "## [TESTING] Keyword was found but no release was created."
    else
        # https://httpie.io/docs/cli/http-headers
        echo "$DATA" | http POST "$URL" "Authorization: token $GITHUB_TOKEN" | jq .
    fi
# otherwise
else
    # exit gracefully
    echo "Nothing to process."
fi
