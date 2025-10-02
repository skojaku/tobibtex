# DOI and Title to BibTeX Fetcher

This repository contains an Alfred workflow and a standalone bash script to fetch BibTeX entries for academic papers using either a DOI or a title.

![](./demo.gif)

## Alfred Workflow (Recommended)

The primary way to use this tool is through the Alfred workflow. It allows you to fetch BibTeX entries directly from Alfred's search bar.

### Installation

1.  **Download the workflow:**

    [![Download Workflow](https://img.shields.io/badge/Download-Alfred%20Workflow-blue?style=for-the-badge&logo=alfred)](https://github.com/skojaku/tobibtex/raw/main/toBibtex.alfredworkflow)

    Click the button above or download the `toBibtex.alfredworkflow` file from this repository.
2.  **Install the workflow:**
    - Double-click the downloaded `.alfredworkflow` file to install it in Alfred.
3.  **Install dependencies:**
    The workflow requires several command-line tools:

    -   **`bibtex-tidy`**: For formatting the BibTeX output
        ```bash
        npm install -g bibtex-tidy
        ```
    -   **`jq`**: For parsing JSON data. On macOS, install using [Homebrew](https://brew.sh/):
        ```bash
        brew install jq
        ```
        For other systems, see the [official `jq` installation guide](https://stedolan.github.io/jq/download/).
    -   **`curl`**: Usually pre-installed on macOS.
    -   **`python3`**: Usually pre-installed on macOS.
    -   **`pbcopy` & `osascript`**: Pre-installed on macOS for clipboard and notification support.

### Usage

Once installed, you can use the keyword `bib` in Alfred to trigger the workflow.

-   **Fetch by DOI:**
    ```
    bib 10.1088/1367-2630/16/6/063023
    ```
-   **Fetch by Title:**
    ```
    bib Random walks and diffusion on networks
    ```

The fetched BibTeX entry will be copied to your clipboard, and you'll receive a notification.

## Bash Script (for non-Alfred users)

If you don't use Alfred, you can use the standalone bash script `doi_or_title_fetcher.sh`.

### Dependencies

The script relies on the following command-line tools:

-   `curl`: For making HTTP requests.
-   `jq`: For parsing JSON data.
-   `python3`: For title similarity checks.
-   `bibtex-tidy`: For formatting the BibTeX output.
-   `pbcopy` & `osascript`: For clipboard and notification integration on macOS.

### Installation

1.  **Install dependencies:**
    -   **`bibtex-tidy`**:
        ```bash
        npm install -g bibtex-tidy
        ```
    -   **`jq`**: On macOS, you can use [Homebrew](https://brew.sh/):
        ```bash
        brew install jq
        ```
        For other systems, see the [official `jq` installation guide](https://stedolan.github.io/jq/download/).

2.  **Make the script executable (optional):**
    If you want to run the script directly, you can make it executable:
    ```bash
    chmod +x doi_or_title_fetcher.sh
    ```


### Usage

Run the script from your terminal, passing the DOI or the title as an argument.

-   **Fetch by DOI:**
    ```bash
    ./doi_or_title_fetcher.sh "10.1145/3511808.3557220"
    ```
-   **Fetch by Title:**
    ```bash
    ./doi_or_title_fetcher.sh "Promptagator Few-shot dense retrieval from 8 examples"
    ```

The script will print the fetched BibTeX to the console and copy it to your clipboard.