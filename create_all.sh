#!/usr/bin/env bash

if ! command -v pdfcpu >/dev/null; then
    echo "pdfcpu not found"
    echo "On mac, run brew install pdfcpu"
    echo "Else, go to https://github.com/pdfcpu/pdfcpu/releases"
    exit 1
fi

template_pdf="$(realpath "$1")"
template_create="$2"
names_file="$3"

__EOF__

USAGE=$(
    read -d '' <<__EOF__
Usage: $0 <template.pdf> <template_create.json> <names_file.txt>
The PDF created will be the same name as the names_file.txt.


__EOF__
)

if [[ ! -f $template_pdf ]]; then
    echo "$USAGE"
    echo "ERROR: Template pdf not found: $template_pdf"
    exit 1
fi
if [[ ! -f $template_create ]]; then
    echo "$USAGE"
    echo "ERROR: JSON file for creating the pdf not found: $template_create"
    exit 1
fi
if [[ ! -f $names_file ]]; then
    echo "$USAGE"
    echo "ERROR: list of names file not found: $names_file"
    exit 1
fi

base_name="$(basename "$names_file" | awk -F. '{print $1}')"
output_pdf="$(realpath "$base_name.pdf")"
create_file="$base_name.json"
echo $output_pdf
echo $template_pdf
if [[ $output_pdf == "$template_pdf" ]]; then
    echo "$USAGE"
    echo "ERROR: the output file is the same name as the template file: $output_pdf"
    echo "       Change the name of the template pdf ($template_pdf) or change the name"
    echo "       of the file containing the list of names"
    exit 1
fi

last_line="$(tail -1 "$names_file")"
if [[ ! $last_line =~ ^$ ]]; then
    echo "Adding new line to $names_file"
    echo "" >>"$names_file"
fi

read -r -d '' SETUP_INFO <<__EOF__
Template PDF:         $template_pdf
Create JSON Template: $create_file
List of names:        $names_file
__EOF__

echo "$SETUP_INFO"
echo ""
page_no=1

# copy the template create file
cp "$template_create" "$create_file"

# loop through names and add to JSON, outputing to $create_file
while read -r name; do
    if [[ $name == "" ]] || [[ $name =~ \# ]]; then
        continue
    fi
    read -r -d '' CONTENT <<__EOF__
{
    "$page_no": {
        "content": {
            "text": [
                {
                    "name": "\$studentName",
                    "value": "$name"
                }
            ]
        }
    }
}
__EOF__
    jq ".pages += $CONTENT" <"$create_file" >>tmp.json
    mv tmp.json "$create_file"
    page_no="$((page_no = page_no + 1))"
done <"$names_file"

# check that the correct number of names were added
got_length="$(jq '.pages|length' <"$create_file")"
expected_length="$(cat "$names_file" | grep -v '^$' | grep -v '#' | wc -l)"

if [[ $got_length != "$expected_length" ]]; then
    echo "ERROR: expected $expected_length entries in $create_file but only got $got_length"
    exit 1
fi
echo "Added $got_length to $create_file"

# use the generated outfile to create a single pdf with all names
pdfcpu create -q "$create_file" "$template_pdf" "$output_pdf"
echo "Wrote $output_pdf"
