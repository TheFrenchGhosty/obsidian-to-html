# obsidian-to-html

Take an Obsidian vault and turn it into HTML where each HTML file is self-contained (for easy sharing).

## Features

- Converts every Markdown note into a standalone HTML file with inlined CSS
- Embeds attachments (images, PDFs, archives, audio, video, ...) as **base64 data URIs**, so each `.html` is fully portable — no external assets required
- Resolves Obsidian `![[embeds]]` and `[[wikilinks]]`, rewriting note links to `.html`
- Falls back to a vault-wide search when an attachment isn't found next to the note
- Generates a navigable `index.html` per folder (with subfolders and notes listed)
- Skips `.obsidian` and `.trash` internal directories
- Styled with the Catppuccin Macchiato theme, includes a pandoc-generated Table of Contents at the top

## Requirements

- `bash`
- `perl` (with `File::Basename`, `File::Spec`, `File::Find`, `MIME::Base64` - all core modules)
- [`pandoc`](https://pandoc.org/) (optional but recommended; falls back to raw `<pre>` output if missing)

## Usage

1. Edit the paths at the top of `script.sh`:

   ```bash
   VAULT_DIR="./my_vault"
   OUTPUT_DIR="./output"
   ```

2. Run the script:

   ```bash
   ./script.sh
   ```

3. Open `./output/index.html` in your browser, or share any individual `.html` file.

## Supported Attachment Types

Images (`png`, `jpg`, `jpeg`, `gif`, `svg`, `webp`), `pdf`, archives (`7z`, `zip`, `rar`, `tar`, `gz`), Office docs (`doc`, `docx`, `xls`, `xlsx`), and media (`mp3`, `mp4`, `wav`). Unknown types fall back to a generic download link.

## Example Output

A converted note `Notes.html` might contain:

```html
<h1>Notes</h1>

<p>Here is the architecture diagram:</p>
<img alt="diagram.png" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA..." />

<p>Full spec below:</p>
<embed src="data:application/pdf;base64,JVBERi0xLjQKJ..." width="100%" height="800px" type="application/pdf" />

<p>Source archive:</p>
<a href="data:application/x-7z-compressed;base64,N3q8ryccAA..." download="source.7z">Download source.7z</a>

<p>See <a href="Meeting Notes.html">Meeting Notes</a> for context.</p>
```

Each file is self-contained - the image, PDF and most other file types are all embedded inline, so the HTML can be shared or hosted anywhere without extra assets.

---

## AI Acknowledgement

This was made with the help of LLM.

The project was written and refined with GLM5.2 with reasoning enabled.

I did know exactly what I wanted I just couldn't be bothered to write it myself, I know how to use pandoc, the rest was just fiddly I had no interest in learning. I made the LLM do exactly what I wanted, and then I tweaked a lot of it by hand. There was a LOT of back and forth, and a lot of "human" work, but this is, at its core still a project made using LLMs.

All testing was made by a Human.

It took me around 3 hours of work (minimum).

This was for personal use first and foremost, I just decided to release it.

Consider this provided as is, as the LICENSE says.

AI sucks, but I'm not a developer, have no interest in becoming one, and I'm too poor to hire a contractor. Blame capitalism, not me.
