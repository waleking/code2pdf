#!/bin/bash

# If no argument is provided, use current directory as default
R# Convert ROOT_DIR to absolute path immediately when setting it
ROOT_DIR=$(cd "${1:-.}" && pwd)

# Get vimrc path
VIMRC_PATH=$2

# These are the arguments passed from TypeScript
BLACKLISTED_FOLDERS_JSON=$3
BLACKLISTED_FOLDER_PATTERN=$4
WHITELISTED_FILE_EXTENSIONS_JSON=$5
WHITELISTED_FILE_NAMES_JSON=$6

vim --version >&2

# Count lines in all .ts files excluding those in node_modules and display file names
# find "$ROOT_DIR" -name "node_modules" -prune -o -name "*$EXTENSION" -type f -print | xargs wc -l
echo "printing all src files in $ROOT_DIR"

##########################################3
# Step 1. Print all src files into /tmp/ 
##########################################3

# Change src/components/Task.js to src____components____Task----js
generate_pdf_file_name () {
    orig_name=$1
    output=$( echo "$orig_name" | perl -pe 's/\//____/g and s/\./----/g' )
    echo "$output"
}

print_to_pdf () {
    file_name=$1
    echo "converting to a pdf file for $file_name"
    pdf_name=$( generate_pdf_file_name $file_name)
    vim -u "$VIMRC_PATH" -c "syntax on" "+set stl+=%{expand('%:~:.')}" "+hardcopy > /tmp/$pdf_name.ps" "+wq" $file_name
    ps2pdf /tmp/$pdf_name.ps /tmp/$pdf_name.pdf
}

print_files_in_a_folder() {
    folder=$1

    # Parse the JSON strings into bash arrays
    declare -a blacklisted_folders=($(echo "$BLACKLISTED_FOLDERS_JSON" | jq -r '.[]'))
    blacklisted_folder_pattern="$BLACKLISTED_FOLDER_PATTERN"
    declare -a whitelisted_file_extensions=($(echo "$WHITELISTED_FILE_EXTENSIONS_JSON" | jq -r '.[]'))
    declare -a whitelisted_file_names=($(echo "$WHITELISTED_FILE_NAMES_JSON" | jq -r '.[]'))

    # Check if the folder is in the blacklist
    folder_basename=$(basename "$folder")

    for blacklist in "${blacklisted_folders[@]}"
    do
        if [[ "$folder_basename" == "$blacklist" ]]; then
            return
        fi
    done

    # Handle env* pattern separately
    if [[ "$folder_basename" == $blacklisted_folder_pattern ]]; then
        return
    fi

    for entry in "$folder"/*
    do
        if [ -f "$entry" ]
        then
            base_name=$(basename "$entry")
            extension="${entry##*.}"
            process_file=false

            # Check if the file's extension is in the whitelist
            for allowed_extension in "${whitelisted_file_extensions[@]}"
            do
                if [ "$extension" == "$allowed_extension" ]; then
                    process_file=true
                    break
                fi
            done

            # Check if the file's name is in the whitelist
            for allowed_name in "${whitelisted_file_names[@]}"
            do
                if [ "$base_name" == "$allowed_name" ]; then
                    process_file=true
                    break
                fi
            done

            if [ "$process_file" = true ]; then
                print_to_pdf "$entry"

                # Emit progress info
                echo "PROGRESS: Processed $entry" >&2
            fi
        else
            # further visit the files or folders in the current folder
            print_files_in_a_folder "$entry"
        fi
    done
}

rm /tmp/*.ps
rm /tmp/*.pdf
print_files_in_a_folder $ROOT_DIR 


##########################################3
# Step 2. Generate the table of table_of_contents
##########################################3

# Change src____components____Task----js.pdf to src/components/Task.js
generate_orig_file_name () {
    pdf_name=$1
    output=$( echo "$pdf_name" | perl -pe 's/\.pdf//g and s/____/\//g and s/----/\./g' )
    echo "$output"
}

cd /tmp
rm table_of_contents
touch table_of_contents

echo "generating the table of contents"
for entry in *.pdf
do
    orig_file_name=$( generate_orig_file_name $entry )
    echo "$orig_file_name" >> table_of_contents
done
echo "Info: Contents of table_of_contents:" >&2
cat table_of_contents >&2

vim -u "$VIMRC_PATH" "+hardcopy > 00_table_of_contents.ps" "+wq" table_of_contents
ps2pdf 00_table_of_contents.ps 00_table_of_contents.pdf

##########################################3
# Step 3. Merge all /tmp/*.pdf into a single pdf
##########################################3
echo "Debug: Starting final merge step..." >&2
echo "Debug: Current working directory: $(pwd)" >&2
echo "Debug: ROOT_DIR value: $ROOT_DIR" >&2

# Clean up any existing merged PDF
echo "Debug: Removing any existing merged.pdf" >&2
rm -f "$ROOT_DIR/merged.pdf"

# Merge PDFs with explicit error checking
echo "merging all pdf files into a single file named merged.pdf" >&2
if ! gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=/tmp/merged.pdf /tmp/*.pdf >&2; then
    echo "Error: PDF merge failed" >&2
    exit 1
fi

# Check if merge was successful
if [ ! -f "/tmp/merged.pdf" ]; then
    echo "Error: Merged PDF was not created" >&2
    exit 1
fi

# Move with explicit error checking
echo "Debug: Moving merged PDF to final location" >&2
if ! mv "/tmp/merged.pdf" "$ROOT_DIR/merged.pdf"; then
    echo "Error: Failed to move merged PDF" >&2
    exit 1
fi

# Verify final file exists
if [ -f "$ROOT_DIR/merged.pdf" ]; then
    echo "Success: PDF created at $ROOT_DIR/merged.pdf" >&2
    ls -l "$ROOT_DIR/merged.pdf" >&2
else
    echo "Error: Final PDF not found at expected location" >&2
    exit 1
fi