# DOI and Title to BibTeX Fetcher

This script fetches BibTeX entries for academic papers using either a DOI or a title. It's a convenient tool for quickly getting citation data for your reference manager.

## Features

- Fetches BibTeX directly from a DOI.
- Searches for papers by title using the [OpenAlex API](https://openalex.org/).
- Checks title similarity to ensure the correct paper is found.
- Cleans up the resulting BibTeX using `bibtex-tidy`.
- Copies the BibTeX to the clipboard and shows a system notification (macOS only).

## Dependencies

This script relies on a few command-line tools. Please ensure they are installed on your system.

- `curl`: For making HTTP requests.
- `jq`: For parsing JSON data from the OpenAlex API.
- `python3`: For the title similarity check.
- `bibtex-tidy`: For formatting and cleaning the BibTeX output.
- `pbcopy` & `osascript`: For clipboard and notification integration on macOS.

## Installation

1.  **Make the script executable:**

    ```bash
    chmod +x doi_or_title_fetcher.sh
    ```

2.  **Install `bibtex-tidy`:**

    This tool is used to format the BibTeX output. It can be installed via `npm`.

    ```bash
    npm install -g bibtex-tidy
    ```

3.  **Install `jq`:**

    On macOS, you can use [Homebrew](https://brew.sh/):

    ```bash
    brew install jq
    ```

    For other operating systems, please refer to the [official `jq` installation guide](https://stedolan.github.io/jq/download/).

## Usage

Run the script from your terminal, passing the DOI or the title as an argument.

### Fetch by DOI

```bash
./doi_or_title_fetcher.sh "10.1145/3511808.3557220"
```

### Fetch by Title

```bash
./doi_or_title_fetcher.sh "Promptagator Few-shot dense retrieval from 8 examples"
```

The script will print the fetched BibTeX to the console and copy it to your clipboard.