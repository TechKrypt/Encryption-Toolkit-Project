#!/bin/bash

# ========== Configuration ==========
SOURCE_DIR="../"
ENCRYPTED_DIR="../encrypted_files"
SIGNED_DIR="../signed_files"
PROCESSED_LOG="../processed_files.log"
FAILED_LOG="../failed_uploads.log"
REMOTE_NAME="protondrive"
REMOTE_DIR="Backups"
REMOTE_SIG_DIR="$REMOTE_DIR/signatures"
RECIPIENT_EMAIL="hellovictor300@gmail.com"
SIGNING_KEY="hellovictor300@gmail.com"
TIMESTAMP=$(date "+%Y-%m-%d_%H-%M-%S")

# ========== Options ==========
DRY_RUN=false

# Check if --dry-run passed
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo -e "\n DRY RUN MODE ENABLED — No actual encryption or upload will happen.\n"
fi

# ========== Setup ==========
mkdir -p "$ENCRYPTED_DIR" "$SIGNED_DIR"
touch "$PROCESSED_LOG" "$FAILED_LOG"

echo -e "\nEncrypting and Signing up to 10 files for upload [$TIMESTAMP]..."
echo "========================================================="

# ========== Gather Eligible Files ==========
FILES_TO_PROCESS=()
while IFS= read -r FILE; do
    BASENAME=$(basename "$FILE")
    if ! grep -q "$BASENAME" "$PROCESSED_LOG"; then
        FILES_TO_PROCESS+=("$FILE")
    fi
done < <(find "$SOURCE_DIR" -maxdepth 1 -type f \( -iname "*.txt" -o -iname "*.pdf" -o -iname "*.docx" \))

TOTAL=${#FILES_TO_PROCESS[@]}

# ========== File Count Control ==========
if [ $TOTAL -lt 1 ]; then
    echo " No new files found. Skipping."
    exit 0
elif [ $TOTAL -gt 10 ]; then
    echo "ore than 10 files found. Processing only first 10."
    FILES_TO_PROCESS=("${FILES_TO_PROCESS[@]:0:10}")
fi


# ========== Track Status ==========
EMAIL_BODY="Encryption and Upload Report [$TIMESTAMP]\n"
EMAIL_BODY+="==================================================\n"

# ========== Process Files ==========
for FILE in "${FILES_TO_PROCESS[@]}"; do
    BASENAME=$(basename "$FILE")
    SIGNED_FILE="$SIGNED_DIR/$BASENAME.sig"
    ENCRYPTED_FILE="$ENCRYPTED_DIR/$BASENAME.gpg"

    echo -e "\n Processing: $BASENAME"

    if $DRY_RUN; then
        echo "  Would sign: $SIGNED_FILE"
        echo "  Would encrypt: $ENCRYPTED_FILE"
        echo "  Would upload to: $REMOTE_NAME:$REMOTE_DIR"
        echo "  Would upload signature to: $REMOTE_NAME:$REMOTE_SIG_DIR"
        continue
    fi

    # --- Sign the file ---
    echo "✍️ Signing..."
    gpg --yes --batch --output "$SIGNED_FILE" --local-user "$SIGNING_KEY" --detach-sign "$FILE"
    if [ $? -ne 0 ]; then
        echo "Signing failed for $BASENAME"
        echo "$BASENAME | Signing failed | $TIMESTAMP" >> "$FAILED_LOG"
        EMAIL_BODY+="$BASENAME - Signing Failed\n"
        continue
    fi

    # --- Encrypt the file ---
    echo "Encrypting..."
    gpg --yes --batch --output "$ENCRYPTED_FILE" --encrypt --recipient "$RECIPIENT_EMAIL" "$FILE"
    if [ $? -ne 0 ]; then
        echo "Encryption failed for $BASENAME"
        echo "$BASENAME | Encryption failed | $TIMESTAMP" >> "$FAILED_LOG"
        EMAIL_BODY+="$BASENAME - Encryption Failed\n"
        continue
    fi

    # --- Upload both files ---
    echo "Uploading encrypted file..."
    rclone copy "$ENCRYPTED_FILE" "$REMOTE_NAME:$REMOTE_DIR" --verbose
    if [ $? -ne 0 ]; then
        echo "Upload failed for $ENCRYPTED_FILE"
        echo "$BASENAME | Encrypted upload failed | $TIMESTAMP" >> "$FAILED_LOG"
        EMAIL_BODY+="$BASENAME - Encrypted Upload Failed\n"
        continue
    fi

    echo "ploading signature..."
    rclone copy "$SIGNED_FILE" "$REMOTE_NAME:$REMOTE_SIG_DIR" --verbose
    if [ $? -ne 0 ]; then
        echo "Upload failed for $SIGNED_FILE"
        echo "$BASENAME | Signature upload failed | $TIMESTAMP" >> "$FAILED_LOG"
        EMAIL_BODY+="$BASENAME - Signature Upload Failed\n"
        continue
    fi

    echo "$BASENAME" >> "$PROCESSED_LOG"
    EMAIL_BODY+="$BASENAME - Success\n"
    echo "Done: $BASENAME"
done

# ========== Send Email Report ==========
if ! $DRY_RUN; then
    echo -e "\n Sending email report..."
    echo -e "$EMAIL_BODY" | mail -s "✅ Encryption & Upload Report [$TIMESTAMP]" "$RECIPIENT_EMAIL"
fi

echo -e "\nDone with session [$TIMESTAMP]"

