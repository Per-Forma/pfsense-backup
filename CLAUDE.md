# CLAUDE.md — pfsense-backup

This file provides guidance for AI assistants working in this repository.

## Project Overview

`pfsense-backup` is a minimal Bash utility that automates XML configuration backups of pfSense firewall appliances. It replicates browser behaviour using MIME Multipart Media Encapsulation (via `curl`) because the official wget-based method documented by pfSense does not work across all supported versions.

## Repository Structure

```
pfsense-backup/
├── pfbkup.sh        # Orchestrator: reads pfhosts, iterates hosts, calls cURLpfbkup.sh
├── cURLpfbkup.sh    # Core logic: authenticates, detects version, downloads XML backup
├── pfhosts          # Configuration file: one host per line (hostname username password)
├── README.md        # User-facing documentation
└── CLAUDE.md        # This file
```

**Runtime-generated artefacts** (not committed):
- `cookies/` — Directory created on first run; holds per-host curl cookie files (deleted after each successful backup)
- `{hostname}.xml` — Downloaded backup files saved in the working directory

## Scripts

### `pfbkup.sh` (Entry Point)

- Changes into its own directory (`BASEDIR`) so cron scheduling works from any working directory.
- Creates `cookies/` if absent.
- Reads `pfhosts` line by line; skips comment lines (`#`) and blank/short lines.
- Splits each line into positional parameters and calls `./cURLpfbkup.sh $param0 $param1 $param2`.

### `cURLpfbkup.sh` (Core Backup Logic)

Receives three positional arguments: `$1` = hostname, `$2` = username, `$3` = password.

Execution flow:
1. Fetch `/diag_backup.php` to obtain the first CSRF token.
2. POST login credentials plus the first CSRF token to obtain a session cookie and second CSRF token.
3. Fetch `/index.php` to detect the pfSense version (parsed from `<strong>x.x.x</strong>`).
4. Branch on version:
   - `2.3.x` → button field name is `Submit`
   - `2.4.x` → button field name is `download`
   - Unknown major/minor version → prints error and exits.
5. Build the MIME Multipart body string (using `$'\r\n'` for Windows-style CRLF as required by the spec).
6. POST the multipart body to `/diag_backup.php`; write the response to `{hostname}.xml`.
7. Delete the session cookie file.

## Configuration File (`pfhosts`)

- **Format**: space-delimited, one appliance per line: `hostname username password`
- **Comments**: lines starting with `#` are skipped
- **Trailing newline required**: the last line must end with a newline or it will not be processed
- **No quoting support**: hostnames, usernames, and passwords must not contain spaces

Example:
```
# My pfSense firewalls
192.168.1.1 admin mysecretpassword
firewall2.local backupuser anotherpassword
```

## Running the Scripts

```bash
# Make executable (first time only)
chmod +x pfbkup.sh cURLpfbkup.sh

# Run manually
./pfbkup.sh

# Schedule via cron (example: daily at 2 AM)
0 2 * * * /path/to/pfsense-backup/pfbkup.sh
```

There is no build step, package manager, or dependency beyond standard Unix utilities: `bash`, `curl`, `grep`, `sed`, `tr`, `wc`.

## Conventions

### Shell Style
- Shebang is always `#!/bin/bash` (not `/bin/sh`).
- Variables are referenced with braces: `${host}`, `${user}`.
- `curl` is always called with `-s -S` (silent, but show errors) and `--insecure` (self-signed certs are common on pfSense).
- Regex extraction uses `grep -Po` (Perl-compatible, print only match).
- Version segments are parsed with lookbehind/lookahead regex patterns.
- The MIME boundary string is hardcoded: `---------------------------7e12e22ee971f00`.

### File Encoding
- All scripts must use **Unix LF line endings** (`\n`), not Windows CRLF.
- The `$'\r\n'` CRLF variable inside `cURLpfbkup.sh` is intentional — it is only used inside the MIME payload body, not in the script itself.

### Naming
- Script names follow the pattern `{scope}{action}.sh` (e.g., `pfbkup`, `cURLpfbkup`).
- Version variables follow the pattern `pf{major|minor|point}ver`: `pfmaver`, `pfmiver`, `pfptver`.
- Output XML files are named `{hostname}.xml`.

### Error Handling
- Failed login is detected by checking whether `csrf2` is empty after the login POST; an empty token means the credentials were rejected, so the script prints an error and exits `1` without writing a backup.
- The download response is written to `{hostname}.xml.tmp` and validated for the `<pfsense>` root element before being moved into place. A non-config (HTML) response leaves any existing `{hostname}.xml` untouched and exits `1`.
- Unknown pfSense versions cause the script to `exit 1` without saving a file; this is intentional to avoid saving garbage HTML as XML.
- All failure paths clean up the per-host cookie file and return a non-zero exit code.

## Security Considerations

- Credentials are stored **in plaintext** in `pfhosts`. Restrict file permissions (`chmod 600 pfhosts`) and ensure the file is not committed to public repositories.
- `--insecure` disables TLS certificate verification. This is intentional for appliances with self-signed certs, but be aware of the MITM risk in untrusted networks.
- Cookie files are removed after each backup run to minimise session exposure.

## Supported pfSense Versions

| Version | Status |
|---------|--------|
| 2.3.x   | Supported (button: `Submit`) |
| 2.4.x   | Supported (button: `download`) |
| 2.5+    | Not yet supported — requires version detection update |

When adding support for a new version, extend the `if/elif` block in `cURLpfbkup.sh` (lines 28–43) and update this table.

## Testing

There is no automated test suite. Testing is manual:
1. Populate `pfhosts` with a real or lab pfSense appliance.
2. Run `./pfbkup.sh` and verify that `{hostname}.xml` is created and is valid XML.
3. Confirm the cookie file is cleaned up from `cookies/`.

When verifying regex changes, use `echo '<test-string>' | grep -Po '<pattern>'` in a shell before modifying the script.

## Development Branch

Active development happens on feature branches. The `master` branch is the stable release branch. Keep commits focused and descriptive (see commit history style: `"Specify bash shell"`, `"Update to use secure transport"`).
