#!/bin/bash
# doi_or_title_fetcher.sh
# Usage examples:
#   ./doi_or_title_fetcher.sh "10.1145/3511808.3557220"
#   ./doi_or_title_fetcher.sh "Promptagator Few-shot dense retrieval from 8 examples"
#
# Install bibtex-tidy to use this script:
# >> npm install -g bibtex-tidy
#


set -euo pipefail

########################################
# Helper: API call with retry
########################################
make_api_call() {
  local url="$1"
  local max_retries=3
  local retry_delay=2
  local attempt=1

  while [[ $attempt -le $max_retries ]]; do
    local response
    response=$(curl -s -w "\n%{http_code}" "$url")
    local http_code
    http_code=$(echo "$response" | tail -n1)
    response=$(echo "$response" | sed '$d')

    if [[ "$http_code" == "200" ]]; then
      echo "$response"
      return 0
    elif [[ "$http_code" == "429" ]]; then
      if [[ $attempt -lt $max_retries ]]; then
        echo "⚠️ Rate limited. Waiting ${retry_delay}s before retry..." >&2
        sleep "$retry_delay"
        retry_delay=$((retry_delay * 2))
        attempt=$((attempt + 1))
      else
        echo "❌ Rate limit exceeded after $max_retries attempts" >&2
        return 1
      fi
    else
      echo "❌ API returned status code $http_code" >&2
      return 1
    fi
  done
}

########################################
# Helper: BibTeX formatting
########################################
format_bibtex() {
  local title="$1"
  local authors="$2"
  local year="$3"
  local venue="$4"
  local doi="$5"
  local entry_type="$6"
  local venue_field="$7"

  # Generate citation key
  local first_author
  first_author=$(echo "$authors" | awk -F ' and ' '{print $1}' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z]//g')
  local first_word
  first_word=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z ]//g' | awk '{print $1}')
  local key="${first_author}${year}${first_word}"

  # Build BibTeX entry
  local bib="@${entry_type}{${key},
  title         = {${title}},
  author        = {${authors}},
  year          = {${year}}"
  [[ -n "$venue" && "$venue" != "null" ]] && bib+=",  ${venue_field}     = {${venue}}"
  [[ "$doi" != "null" ]] && bib+=",  doi           = {${doi}}"
  bib+="}"

  echo "$bib"
}

########################################
# Helper: Clipboard and notification
########################################
copy_to_clipboard() {
  local bib="$1"
  local tidied
  tidied=$(echo "$bib" | bibtex-tidy \
             --generate-keys --curly --align=14 --sort-fields --blank-lines \
             --no-escape --drop-all-caps --enclosing-braces \
             --remove-empty-fields --quiet)

  [[ -z "$tidied" ]] && tidied="$bib"
  local key
  key=$(echo "$tidied" | head -1 | sed -E 's/@[^{}]+{//;s/,.*//')
  echo "$tidied" | pbcopy
  osascript -e "display notification \"BibTeX copied ($key)\" with title \"DOI Fetcher\" sound name \"Glass\""
  echo "$tidied"
}

########################################
# Helper: Title similarity check
########################################
check_title_similarity() {
  local query="$1"
  local returned="$2"
  python3 -c 'import sys,difflib;print(int(difflib.SequenceMatcher(None,sys.argv[1].lower(),sys.argv[2].lower()).ratio()*100))' \
    "$query" "$returned"
}

########################################
# Helper: Get BibTeX from DOI
########################################
get_bibtex_from_doi() {
  local doi="$1"
  [[ "$doi" != http* ]] && doi="https://dx.doi.org/${doi#doi:}"
  curl -sL -H "Accept: application/x-bibtex" "$doi"
}

########################################
# OpenAlex search
########################################
search_openalex() {
  local query="$1"
  local encoded
  encoded=$(printf "%s" "$query" | jq -sRr @uri)
  local oa_url="https://api.openalex.org/works?filter=title.search:%22${encoded}%22"

  echo "🔍 Searching OpenAlex..."
  local oa_json
  oa_json=$(make_api_call "$oa_url") || return 1

  if ! echo "$oa_json" | jq -e '.results[0]' >/dev/null 2>&1; then
    echo "❌ No OpenAlex match"
    return 1
  fi

  # Extract fields
  local title
  title=$(echo "$oa_json" | jq -r '.results[0].title')
  local year
  year=$(echo "$oa_json" | jq -r '.results[0].publication_year')
  local venue
  venue=$(echo "$oa_json" | jq -r '.results[0].primary_location.source.display_name')
  local doi
  doi=$(echo "$oa_json" | jq -r '.results[0].doi')
  local authors
  authors=$(echo "$oa_json" | jq -r '.results[0].authorships | map(.author.display_name) | join(" and ")')

  # Check title similarity
  local sim
  sim=$(check_title_similarity "$query" "$title")
  if (( sim < 70 )); then
    echo "⚠️ OpenAlex match similarity too low ($sim%)"
    return 1
  fi

  # First try to get BibTeX from DOI
  if [[ "$doi" != "null" ]]; then
    echo "🔍 Trying to fetch BibTeX from DOI..."
    local bib
    bib=$(get_bibtex_from_doi "$doi")
    if [[ -n "$bib" ]]; then
      copy_to_clipboard "$bib"
      return 0
    fi
    echo "⚠️ Could not fetch BibTeX from DOI, falling back to OpenAlex data..."
  fi

  # If DOI fetch failed, construct BibTeX from OpenAlex data
  local entry_type="article"
  local venue_field="journal"
  [[ "$venue" =~ (Conference|Workshop|Symposium) ]] && { entry_type="inproceedings"; venue_field="booktitle"; }

  local bib
  bib=$(format_bibtex "$title" "$authors" "$year" "$venue" "$doi" "$entry_type" "$venue_field")
  copy_to_clipboard "$bib"
}

########################################
# Main function
########################################
main() {
  echo "🔍 Starting DOI/Title fetcher…"
  echo "Input: $1"

  local raw="$1"
  raw="$(echo "$raw" | tr -d '[:space:]')"
  local is_doi=0
  [[ "$raw" == http* || "$raw" == doi:* || "$raw" == 10.*/* ]] && is_doi=1

  if [[ $is_doi -eq 0 ]]; then
    # Title search: try OpenAlex
    search_openalex "$1"
  else
    # DOI search
    local doi="$raw"
    echo "🔍 Fetching BibTeX from DOI..."
    local bib
    bib=$(get_bibtex_from_doi "$doi") || { echo "❌ Could not fetch BibTeX"; exit 1; }
    copy_to_clipboard "$bib"
  fi
}

# Run main function
main "$1"