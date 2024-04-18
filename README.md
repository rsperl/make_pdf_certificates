# Make Certificates

Uses [`pdfcpu`](https://www.pdfcpu.io) to create a single pdf from a template and a JSON specification.

Customize [`create.json`](./create.json) (font, size, position). When the script is run, it will populate `.pages`.

The list of names to add to the certificates should be one name per line. Blank lines and lines containing `#` will be omitted.

Create the certificates like

```shell
./create_all.sh template.pdf ./create.json list_of_names.txt
```

This will create `list_of_names.pdf` with one page per certificate. Each page will look like `template.pdf` but with a name on it.

To troubleshoot, see the generated `list_of_names.json`. This file will look the same as `create.json` but with `.pages` populated.