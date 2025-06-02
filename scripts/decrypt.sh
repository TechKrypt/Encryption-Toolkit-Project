#!/bin/bash

# ======= Configuration =======
ENCRYPTED_DIR="../encrypted_files"
DECRYPTED_DIR="../decrypted_files"
SIGNED_DIR="../signed_files"
REMOTE_NAME="protondrive"
REMOTE_DIR="Backups"

mkdir -p "$ENCRYPTED_DIR" "$DECRYPTED_DIR" "$SIGNED_DIR"

function list_remote_files() {
    local EXT="$1"
    rclone lsjson "$REMOTE_NAME:$REMOTE_DIR" | jq -r ".[] | select(.Path | endswith(\"$EXT\")) | .Path"
}

function pretty_header() {
    echo -e "\n======================================="
    echo -e "  $1"
    echo -e "=======================================\n"
}

function decrypt_files() {
    pretty_header "Decrypt Encrypted Files"

    FILES=$(list_remote_files ".gpg")
    if [ -z "$FILES" ]; then
        echo "No encrypted files (.gpg) found."
        return
    fi

    declare -A OPTIONS
    i=1
    for FILE in $FILES; do
        echo "  [$i] $FILE"
        OPTIONS[$i]="$FILE"
        ((i++))
    done

    echo -e "\nYou may choose up to 3 files to decrypt (comma-separated, e.g. 1,2,3):"
    read -p "Enter your choices: " CHOICE_LINE
    IFS=',' read -ra CHOICES <<< "$CHOICE_LINE"
    if [ "${#CHOICES[@]}" -gt 5 ]; then
        echo "Limit is 5 files."
        return
    fi

    for CHOICE in "${CHOICES[@]}"; do
        SELECTED="${OPTIONS[$CHOICE]}"
        if [ -z "$SELECTED" ]; then
            echo "Skipping invalid selection [$CHOICE]."
            continue
        fi

        echo "\n⬇️ Downloading '$SELECTED'..."
        rclone copy "$REMOTE_NAME:$REMOTE_DIR/$SELECTED" "$ENCRYPTED_DIR"

        BASENAME=$(basename "$SELECTED" .gpg)
        INFILE="$ENCRYPTED_DIR/$(basename "$SELECTED")"
        OUTFILE="$DECRYPTED_DIR/$BASENAME"

        echo "Decrypting '$BASENAME'..."
        if gpg --yes --batch --output "$OUTFILE" --decrypt "$INFILE"; then
            echo "Decryption successful: $OUTFILE"
            read -p "Do you want to view the contents of '$BASENAME'? [y/n]: " yn
            if [[ "$yn" =~ ^[Yy]$ ]]; then
                echo -e "\n--- BEGIN: $BASENAME ---"
                cat "$OUTFILE"
                echo -e "--- END: $BASENAME ---\n"
            else
                echo "Saved to decrypted folder."
            fi
        else
            echo "Failed to decrypt $BASENAME"
        fi
    done
}

function verify_signed_files() {
    pretty_header "Verify Signed Files"

    FILES=$(list_remote_files ".asc")
    if [ -z "$FILES" ]; then
        echo "No signed files (.asc) found."
        return
    fi

    declare -A OPTIONS
    i=1
    for FILE in $FILES; do
        echo "  [$i] $FILE"
        OPTIONS[$i]="$FILE"
        ((i++))
    done

    read -p "Enter the number of the signed file to verify: " CHOICE
    SELECTED="${OPTIONS[$CHOICE]}"
    if [ -z "$SELECTED" ]; then
        echo "Invalid choice."
        return
    fi

    echo "\n⬇️ Downloading signed file '$SELECTED'..."
    rclone copy "$REMOTE_NAME:$REMOTE_DIR/$SELECTED" "$SIGNED_DIR"
    LOCAL_FILE="$SIGNED_DIR/$(basename "$SELECTED")"

    echo "🖋 Verifying signature..."
    if gpg --verify "$LOCAL_FILE" 2>&1; then
        echo "Signature is valid."
        echo -e "\nWould you like to read the signed content? (clear-signed only)"
        read -p "[y/n]: " yn
        if [[ "$yn" =~ ^[Yy]$ ]]; then
            echo -e "\n--- START OF SIGNED CONTENT ---"
            cat "$LOCAL_FILE"
            echo -e "\n--- END OF SIGNED CONTENT ---"
        fi
    else
        echo "Signature verification failed."
    fi
}

# ======= Menu =======
clear
pretty_header "Proton Drive Secure File Handler"
echo "What would you like to do?"
echo "  1) Decrypt encrypted files"
echo "  2) Verify signed files"
echo "  3) Exit"
read -p "Enter choice [1-3]: " MENU

case $MENU in
    1) decrypt_files;;
    2) verify_signed_files;;
    3) echo "Goodbye!"; exit 0;;
    *) echo "Invalid option."; exit 1;;
esac

