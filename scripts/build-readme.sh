#!/bin/bash
#===============================================================================
#
#          FILE:  build-readme.sh
#
#         USAGE:  ./scripts/build-readme.sh
#
#   DESCRIPTION:  ---
#
#       OPTIONS:  ---
#
#  REQUIREMENTS:  - bash
#                 - python3 (used by readme-from-csv.py)
#                 - jq
#                 - github cli
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Emerson Rocha <rocha[at]ieee.org>
#       COMPANY:  EticaAI
#       LICENSE:  Public Domain dedication
#                 SPDX-License-Identifier: Unlicense
#       VERSION:  v1.0
#       CREATED:  2022-08-31 03:08 UTC
#      REVISION:  ---
#===============================================================================
set -e

#### Functions _________________________________________________________________

#######################################
# Fetch repo statistics of one repository
#
# Globals:
#
# Arguments:
#   repo        Repository to fetch the data
#   savepath    (optional) Path to store the metadata
# Returns
#   None
#######################################
gh_repo_statistics() {
  repo="${1}"
  repo="${repo//https:\/\/github.com\/''/}" # Remove full url, if exist
  savepath="${2-"partials/raw"}"
  fullsavepath="${savepath}/github-repo/${repo//\//'__'}.json"

  # echo "TODO repo[$repo] savepath[$savepath] fullsavepath [$fullsavepath]"

  if [ -f "${fullsavepath}" ]; then
    echo "Cached file [${fullsavepath}]. Skiping"
    echo "@TODO implement better stale-cache system"
    return 0
  fi

  # We delete some verbose fields such as .owner and .organization with jq
  # Then, sed is used to delete lots of something_url field
  gh api \
    -H "Accept: application/vnd.github+json" \
    "/repos/${repo}" |
    jq 'del(.owner)' |
    jq 'del(.organization)' |
    sed -e '/_url/d' \
      >"${fullsavepath}"
  # exit 1
  sleep 3
}

#######################################
# Iterate list with all repositories and call gh_repo_statistics()
#
# Globals:
#
# Arguments:
#   repositories_file  (optional)  File with list of repositories
# Returns
#   None
#######################################
gh_repo_statistics_list() {
  repositories_file="${1-'partials/raw/github-projects-list.txt'}"

  while read -r line; do
    # echo "$line"
    gh_repo_statistics "$line"
  done <"$repositories_file"
}

#######################################
# Fetch repo statistics of one repository
#
# Globals:
#
# Arguments:
#   repo        Repository to fetch the data
#   savepath    (optional) Path to store the metadata
# Returns
#   None
#######################################
gh_topic_statistics() {
  topic="${1}"
  topic="${topic//https:\/\/github.com\/topics\/''/}" # Remove full url, if exist
  savepath="${2-"partials/raw"}"
  fullsavepath="${savepath}/github-topic/${topic}.json"

  # echo "TODO gh_topic_statistics topic[$topic] savepath[$savepath] fullsavepath [$fullsavepath]"
  # exit 1
  if [ -f "${fullsavepath}" ]; then
    echo "Cached file [${fullsavepath}]. Skiping"
    echo "@TODO implement better stale-cache system"
    return 0
  fi

  # set -x
  # Here we delete only items (which would return the repositories for this topic)
  gh api \
    -H "Accept: application/vnd.github+json" \
    "/search/repositories?q=topic:${topic}" |
    jq 'del(.items)' \
      >"${fullsavepath}"
  # exit 1
  sleep 3
}

#######################################
# Iterate list with all topics and call gh_topic_statistics()
#
# Globals:
#
# Arguments:
#   topics_file  (optional)  File with list of topics
# Returns
#   None
#######################################
gh_topics_statistics_list() {
  topics_file="${1-'partials/raw/github-topic-list.txt'}"

  while read -r line; do
    echo "gh_topics_statistics_list [$line]"
    gh_topic_statistics "$line"
  done <"$topics_file"
}

#### Main ______________________________________________________________________

set -x

./scripts/readme-from-csv.py \
  --method=extract-github-url 'data/*.csv' \
  >partials/raw/github-projects-list.txt

./scripts/readme-from-csv.py \
  --method=extract-github-topic-url 'data/*.csv' \
  >partials/raw/github-topic-list.txt

./scripts/readme-from-csv.py \
  --method=extract-generic-url 'data/*.csv' \
  >partials/raw/generic-url-list.txt

./scripts/readme-from-csv.py \
  --method=extract-wikidata-q 'data/*.csv' \
  >partials/raw/wikidata-q-list.txt

set +x
gh_repo_statistics_list "partials/raw/github-projects-list.txt"
gh_topics_statistics_list "partials/raw/github-topic-list.txt"
# exit 1
set -x

./scripts/readme-from-csv.py \
  data/general-concepts.hxl.csv \
  --line-formatter='### [{raw_line[1]} ({raw_line[0]})](https://www.wikidata.org/wiki/{raw_line[0]})\n{raw_line[2]}\n' \
  >partials/general-concepts.md

# ./scripts/readme-from-csv.py \
#   data/github-topics.hxl.csv \
#   --line-formatter='==== {raw_line[1]}\n`{raw_line}`\n' \
#   --line-select='{raw_line[0]}==1' \
#   >partials/github-topics_1.md

# @TODO implement checking how many repos are in a topic
#       https://docs.github.com/en/rest/search#search-topics
# @TODO https://gist.github.com/usametov/af8f13a351a66fb05a9895f11417dd9d

./scripts/readme-from-csv.py \
  data/github-topics.hxl.csv \
  --line-formatter='  - [{raw_line[1]}](https://github.com/topics/{raw_line[1]}): {raw_line[2]} repositories' \
  --line-select='{raw_line[0]}==1' \
  >partials/github-topics_1.md

./scripts/readme-from-csv.py \
  data/github-topics.hxl.csv \
  --line-formatter='  - [{raw_line[1]}](https://github.com/topics/{raw_line[1]}): {raw_line[2]} repositories' \
  --line-select='{raw_line[0]}==2' \
  >partials/github-topics_2.md

./scripts/readme-from-csv.py \
  data/github-topics.hxl.csv \
  --line-formatter='  - [{raw_line[1]}](https://github.com/topics/{raw_line[1]}): {raw_line[2]} repositories' \
  --line-select='{raw_line[0]}==3' \
  >partials/github-topics_3.md

# shellcheck disable=SC2016
./scripts/readme-from-csv.py \
  data/software.hxl.csv \
  --line-formatter='#### [{raw_line[1]} ({raw_line[2]})]({raw_line[3]})\n\n```\n{raw_line[4]}\n```' \
  --line-select='{raw_line[0]}=="synthetic-data"' \
  >partials/software_synthetic-data.md

./scripts/readme-from-csv.py \
  --method=compile-readme \
  README.template.md \
  >README.md

set +x

# frictionless describe --json data/github-topics.hxl.csv
# frictionless describe --json data/general-concepts.hxl.csv
# frictionless describe --json data/software.hxl.csv

# frictionless validate datapackage.json

# @TODO - https://github.com/sindresorhus/awesome/issues/2242
#       - https://github.com/danielecook/Awesome-Bioinformatics/blob/master/.github/workflows/url-check.yml
#       - https://github.com/peter-evans/link-checker

exit 0

# installing pandoc from source

# https://github.com/jgm/pandoc/releases/tag/2.19.2

wget https://github.com/jgm/pandoc/releases/download/2.19.2/pandoc-2.19.2-linux-amd64.tar.gz -o /tmp/pandoc.tar.gz

# @TODO implement search for topics

# gh api \
#   -H "Accept: application/vnd.github+json" \
#   /search/repositories?q=topic:bioinformatics
# https://github.com/search?q=topic%3Abioinformatics&type=Repositories&ref=advsearch&l=&l=

gh api \
  -H "Accept: application/vnd.github+json" \
  /search/repositories?q=topic:spatial-epidemiology

gh api \
  -H "Accept: application/vnd.github+json" \
  /search/repositories?q=topic:spatial-epidemiology | jq .total_count