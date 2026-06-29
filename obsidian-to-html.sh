#!/usr/bin/env bash
#
# TheFrenchGhosty's Obsidian to HTML
# https://github.com/TheFrenchGhosty/obsidian-to-html
# https://github.com/TheFrenchGhosty
# https://thefrenchghosty.me
#

VAULT_DIR="./my_vault"
OUTPUT_DIR="./output"

# Catppuccin Macchiato Theme CSS
CSS=":root { --bg-color: #24273a; --text-color: #cad3f5; --link-color: #8aadf4; --border-color: #363a4f; --code-bg: #1e2030; --quote-color: #a5adcb; --mauve: #c6a0f6; --green: #a6da95; --peach: #f5a97f; --yellow: #eed49f; --pink: #f5bde6; --blue: #8aadf4; --sky: #91d7e3; --red: #ed8796; } body { background-color: var(--bg-color); color: var(--text-color); font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; margin: 0; padding: 2rem; max-width: 900px; margin-left: auto; margin-right: auto; } a { color: var(--link-color); text-decoration: none; } a:hover { text-decoration: underline; color: var(--pink); } img { max-width: 100%; height: auto; border-radius: 5px; display: block; margin: 1rem 0; } h1, h2, h3, h4, h5, h6 { border-bottom: 1px solid var(--border-color); padding-bottom: 0.3rem; } h1 { color: var(--green); } h2 { color: var(--peach); } h3 { color: var(--mauve); } h4, h5, h6 { color: var(--blue); } code { background-color: var(--code-bg); color: var(--yellow); padding: 0.2rem 0.4rem; border-radius: 3px; font-family: \"Courier New\", monospace; } pre { background-color: var(--code-bg); padding: 1rem; border-radius: 5px; overflow-x: auto; border: 1px solid var(--border-color); } pre code { background-color: transparent; color: var(--text-color); padding: 0; } blockquote { border-left: 4px solid var(--mauve); margin-left: 0; padding-left: 1rem; color: var(--quote-color); } table { width: 100%; border-collapse: collapse; } th, td { border: 1px solid var(--border-color); padding: 0.5rem; } th { background-color: var(--code-bg); color: var(--green); } /* Table of Contents Styling */ #TOC { background-color: var(--code-bg); border: 1px solid var(--border-color); border-radius: 5px; padding: 1rem 1.5rem; margin-bottom: 2rem; } #TOC ul { padding-left: 1.5rem; margin: 0.5rem 0; list-style-type: none; } #TOC > ul { padding-left: 0; } #TOC a { color: var(--sky); } #TOC a:hover { color: var(--pink); } /* Catppuccin Macchiato Syntax Highlighting Overrides */ .sourceCode .kw { color: var(--mauve) !important; } .sourceCode .dt { color: var(--yellow) !important; } .sourceCode .st { color: var(--green) !important; } .sourceCode .co { color: var(--quote-color) !important; font-style: italic; } .sourceCode .fu { color: var(--blue) !important; } .sourceCode .va { color: var(--text-color) !important; } .sourceCode .cn { color: var(--peach) !important; } .sourceCode .ot { color: var(--sky) !important; } .sourceCode .al { color: var(--red) !important; font-weight: bold; } .sourceCode .er { color: var(--red) !important; font-weight: bold; }"

# HTML Wrapper Function
generate_html() {
    local title="$1"
    local body="$2"
    cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <style>${CSS}</style>
</head>
<body>
${body}
</body>
</html>
EOF
}

# Function to process a markdown file
process_markdown_file() {
    local md_file="$1"
    local out_dir="$2"
    local filename=$(basename "$md_file")
    local title="${filename%.md}"

    # Pass VAULT_DIR to perl to allow searching the whole vault for attachments
    local processed_md=$(VAULT_DIR="$VAULT_DIR" perl -MFile::Basename -MFile::Spec -MMIME::Base64 -MFile::Find -pe '
        my $dir = dirname($ARGV);
        my $vault = $ENV{VAULT_DIR};

        # Convert Obsidian embeds ![[file.png]] to standard markdown
        s/!\[\[(.*?)\]\]/![$1]($1)/g;

        # Convert Obsidian wikilinks [[Note]] to standard markdown with .html
        s/\[\[(.*?)\]\]/[$1]($1.html)/g;

        # Convert standard markdown links pointing to .md files to .html
        s/\[([^\]]+)\]\(([^)]+)\.md\)/[$1]($2.html)/g;

        # Embed attachments as base64 (skipping http/https links)
        s{!\[(.*?)\]\(((?!https?:)[^)]+)\)}{
            my ($alt, $path) = ($1, $2);

            # Decode URL entities like %20 to spaces
            $path =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

            $path =~ s/^\///; # Remove leading slash for vault-rooted paths

            my $actual_path = File::Spec->rel2abs("$dir/$path");

            # If not found next to the note, search the entire vault
            if (!-f $actual_path) {
                my $found_path;
                my $basename = File::Basename::basename($path);
                eval {
                    File::Find::find(sub {
                        if (-f $_ && $_ eq $basename) {
                            $found_path = $File::Find::name;
                        }
                    }, $vault);
                };
                $actual_path = $found_path if $found_path;
            }

            if (-f $actual_path) {
                my ($ext) = $path =~ /\.([^.]+)$/;
                my %mime = (
                    png => "image/png", jpg => "image/jpeg", jpeg => "image/jpeg", gif => "image/gif", svg => "image/svg+xml", webp => "image/webp",
                    pdf => "application/pdf",
                    "7z" => "application/x-7z-compressed", zip => "application/zip", rar => "application/vnd.rar", tar => "application/x-tar", gz => "application/gzip",
                    doc => "application/msword", docx => "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                    xls => "application/vnd.ms-excel", xlsx => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                    mp3 => "audio/mpeg", mp4 => "video/mp4", wav => "audio/wav"
                );
                my $m = $mime{lc($ext)} // "application/octet-stream";

                open(my $fh, "<:raw", $actual_path) or return "![$alt]($path)";
                my $raw = do { local $/; <$fh> }; # Fixed: Added <$fh> to read the file
                close($fh);

                my $b64 = encode_base64($raw, "");
                my $base = File::Basename::basename($path);

                # Generate appropriate HTML based on file type
                if ($m =~ /^image\//) {
                    "![$alt](data:$m;base64,$b64)";
                } elsif ($m eq "application/pdf") {
                    "<embed src=\"data:$m;base64,$b64\" width=\"100%\" height=\"800px\" type=\"application/pdf\" />";
                } else {
                    "<a href=\"data:$m;base64,$b64\" download=\"$base\">Download $base</a>";
                }
            } else {
                "![$alt]($path)";
            }
        }ge;
    ' "$md_file")

    # Convert to HTML using pandoc, disabling YAML/TeX, enabling autolink and TOC
    local body_html
    if command -v pandoc &> /dev/null; then
        # Using --standalone and extracting the body to guarantee --toc works
        local pandoc_html=$(echo "$processed_md" | pandoc -f markdown-yaml_metadata_block-tex_math_dollars+autolink_bare_uris -t html --syntax-highlighting=pygments --toc --standalone)
        body_html=$(echo "$pandoc_html" | sed -n '/<body>/,/<\/body>/p' | sed '1d;$d')
    else
        echo "Warning: pandoc not found. Outputting raw text for $title." >&2
        body_html="<pre>$processed_md</pre>"
    fi

    generate_html "$title" "$body_html" > "$out_dir/${title}.html"
}

# Function to generate index for a directory
generate_index() {
    local dir="$1"
    local rel_dir="$2"
    local out_dir="$3"

    local body="<h1>Index: ${rel_dir}</h1>"

    if [ "$rel_dir" != "." ]; then
        body="${body}\n<p><a href=\"../index.html\">../ (Up one directory)</a></p>"
    fi

    # Find subdirectories
    local dirs=$(find "$dir" -mindepth 1 -maxdepth 1 -type d -not -name ".obsidian" -not -name ".trash" | sort)
    if [ -n "$dirs" ]; then
        body="${body}\n<h2>Folders</h2>\n<ul>"
        while IFS= read -r d; do
            local d_name=$(basename "$d")
            body="${body}\n<li><a href=\"./${d_name}/index.html\">📁 ${d_name}</a></li>"
        done <<< "$dirs"
        body="${body}\n</ul>"
    fi

    # Find markdown files
    local mds=$(find "$dir" -mindepth 1 -maxdepth 1 -type f -name "*.md" | sort)
    if [ -n "$mds" ]; then
        body="${body}\n<h2>Notes</h2>\n<ul>"
        while IFS= read -r m; do
            local m_name=$(basename "$m" .md)
            body="${body}\n<li><a href=\"./${m_name}.html\">📄 ${m_name}</a></li>"
        done <<< "$mds"
        body="${body}\n</ul>"
    fi

    if [ -z "$dirs" ] && [ -z "$mds" ]; then
        body="${body}\n<p>This folder is empty.</p>"
    fi

    generate_html "Index - ${rel_dir}" "$(echo -e "$body")" > "$out_dir/index.html"
}

# Main Execution
echo "Converting Obsidian Vault to self-contained HTML..."

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

# Find all directories in the vault
find "$VAULT_DIR" -type d | while IFS= read -r dir; do
    # Skip Obsidian internal folders
    if [[ "$dir" == *".obsidian"* || "$dir" == *".trash"* ]]; then
        continue
    fi

    # Calculate relative path
    rel_dir="${dir#$VAULT_DIR/}"
    if [ "$dir" == "$VAULT_DIR" ]; then
        rel_dir="."
    fi

    # Ensure relative path doesn't start with ./
    rel_dir="${rel_dir#./}"
    if [ -z "$rel_dir" ]; then rel_dir="."; fi

    out_dir="$OUTPUT_DIR/$rel_dir"
    mkdir -p "$out_dir"

    # Generate index for this directory
    generate_index "$dir" "$rel_dir" "$out_dir"

    # Process all markdown files in this directory
    find "$dir" -maxdepth 1 -type f -name "*.md" | while IFS= read -r md_file; do
        process_markdown_file "$md_file" "$out_dir"
    done
done

echo "Done! Output saved to: $OUTPUT_DIR"
