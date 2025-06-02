# Encryption/Decryption Toolkit with Secure File Transfer

This project is a simple encryption and decryption toolkit for securely transferring files. It makes use of GPG for encryption, `sha256sum` for integrity checks, and `rclone` for remote cloud backup to Proton Drive. The toolkit also supports signature verification and includes automation scripts to streamline common tasks.

## Project Goals

* Encrypt files before uploading to the cloud.
* Decrypt files downloaded from the cloud.
* Verify the authenticity of signed files.
* Organize all activities with clear folder structure and logs.
* Automate repetitive encryption and decryption steps using scripts.

---

## Project Structure

### Local Directory Layout

```
/encryption_toolkit
├── decrypted_files/         # Decrypted output files (after decryption)
├── encrypted_files/         # Encrypted .gpg files
├── failed_uploads.log       # Log for failed transfers
├── keys/                    # GPG keys (private/public)
├── processed_files.log      # Log for files already processed
├── readme.md                # Project documentation
├── scripts/                 # Automation scripts (encrypt.sh, decrypt.sh, etc.)
├── signed_files/            # Verified signed documents (.asc)
```

### Remote Backup Layout (ProtonDrive)

```
ProtonDrive:/Backups
├── [Encrypted .gpg Files]
└── signatures/              # Signed files (.asc)
```

---

## Requirements

* Linux or WSL (Windows Subsystem for Linux)
* GPG (GNU Privacy Guard)
* rclone
* jq (for parsing JSON in Bash scripts)
* Proton Drive (configured with `rclone`)

---

## Basic Workflow

### 1. Prepare Your Plaintext File

Create or place your plaintext file in the project root. For example:

```
echo "This is top secret." > secrets.txt
```

You can also use files like `test_encrypt.txt` or `beast.txt` as examples.

---

### 2. Encrypt a File

To encrypt a file:

```bash
gpg -c secrets.txt
```

This creates a file called `secrets.txt.gpg`.

To encrypt with asymmetric keys:

```bash
gpg --output encrypted.gpg --encrypt --recipient recipient@example.com secrets.txt
```

---

### 3. Verify File Integrity

Before or after transfer, generate a hash and verify it:

```bash
sha256sum secrets.txt > secrets.hash
```

To verify:

```bash
sha256sum -c secrets.hash
```

---

### 4. Use the Automation Script for Encryption and Upload

Navigate to the `scripts` folder and run:

```bash
cd scripts
bash encrypt_and_upload.sh
```

This script:

* Encrypts the file.
* Signs it (optional).
* Uploads to Proton Drive using `rclone`.
* Logs the operation.
* Saves encrypted files to `../encrypted_files`.

---

### 5. Use the Automation Script for Decryption and Verification

Navigate to the `scripts` folder and run:

```bash
cd scripts
bash decrypt.sh
```

This script allows you to:

* Select encrypted files from Proton Drive.
* Download and decrypt them into `../decrypted_files`.
* Optionally view the contents.
* Verify any signed files from the `signatures` folder.

---

## Script Files

### encrypt\_and\_upload.sh

* Encrypts plaintext files.
* Signs them if configured.
* Uploads to Proton Drive using `rclone`.
* Skips files already processed (tracked in `processed_files.log`).
* Logs failures in `failed_uploads.log`.

### decrypt.sh

* Lists `.gpg` and `.asc` files from Proton Drive.
* Allows selecting multiple `.gpg` files to decrypt.
* Verifies `.asc` signed files.
* Outputs decrypted files into `decrypted_files`.
* Saves verified files into `signed_files`.

---

## GPG Key Management

Generate a new key:

```bash
gpg --full-generate-key
```

Export your public key:

```bash
gpg --armor --export you@example.com > keys/public_key.asc
```

Import someone’s public key:

```bash
gpg --import keys/public_key.asc
```

---

## Example Files

You can test with:

* `test_encrypt.txt` – A test plaintext file
* `beast.txt.gpg` – A previously encrypted file

---

## Setup rclone for Proton Drive

To configure `rclone` for Proton Drive:

```bash
rclone config
```

Follow the interactive steps to set up a remote named `protondrive`.

---

## Notes

* Always back up your private key securely.
* The toolkit assumes Proton Drive is configured as a remote named `protondrive`.
* Modify the scripts if your setup differs.

---

## Author
Victor C. Menyuah (Teckrypt)
Built for secure workflows & cybersecurity project portfolios.

---

## Disclaimer
This toolkit is meant for educational, testing, and personal backup purposes. Always ensure your GPG key pair is protected and private keys are securely stored.
--

## Want to Contribute?
Fork the repository, submit a pull request, or suggest shell scripting improvements! GUI wrappers, cross-platform support, and advanced logging features are welcome.


