[![cryptomator](cryptomator.png)](https://github.com/SuGotLand/Cryptomator_crack)
[![Latest Release](https://img.shields.io/github/v/release/SuGotLand/Cryptomator_crack.svg)](https://github.com/SuGotLand/Cryptomator_crack/releases)
[![Community](https://img.shields.io/badge/help-Community-orange.svg)](https://community.cryptomator.org)

## Supporting Cryptomator_crack

The origin cryptomator has a supporter supporter certificate controller, in this version we remove the annoying controller.

---
## Introduction

Cryptomator offers multi-platform transparent client-side encryption of your files in the cloud.

Download native binaries of Cryptomator on [GitHub release page](https://github.com/SuGotLand/Cryptomator_crack/releases) or clone and build Cryptomator using Maven (instructions below).

## Features

- Works with Dropbox, Google Drive, OneDrive, MEGA, pCloud, ownCloud, Nextcloud and any other cloud storage service which synchronizes with a local directory
- Open Source means: No backdoors, control is better than trust
- Client-side: No accounts, no data shared with any online service
- Totally transparent: Just work on the virtual drive as if it were a USB flash drive
- AES encryption with 256-bit key length
- File names get encrypted
- Folder structure gets obfuscated
- Use as many vaults in your Dropbox as you want, each having individual passwords
- Four thousand commits for the security of your data!! :tada:

### Privacy

- 256-bit keys (unlimited strength policy bundled with native binaries)
- Scrypt key derivation
- Cryptographically secure random numbers for salts, IVs and the masterkey of course
- Sensitive data is wiped from the heap asap
- Lightweight: [Complexity kills security](https://www.schneier.com/essays/archives/1999/11/a_plea_for_simplicit.html)

### Consistency

- Authenticated encryption is used for file content to recognize changed ciphertext before decryption
- I/O operations are transactional and atomic, if the filesystems support it
- Each file contains all information needed for decryption (except for the key of course), no common metadata means no [SPOF](http://en.wikipedia.org/wiki/Single_point_of_failure)

### Security Architecture

For more information on the security details visit [cryptomator.org](https://docs.cryptomator.org/en/latest/security/architecture/).

## Building

### Dependencies

* JDK 22 (e.g. temurin)
* Maven 3

### Run Maven

```
mvn clean install
```

This will build all the jars and bundle them together with their OS-specific dependencies under `target`. This can now be used to build native packages.

### Run Scripts

```powershell
.\dist\win\build.bat
```

## License

This project is dual-licensed under the GPLv3 for FOSS projects as well as a commercial license for independent software vendors and resellers. If you want to modify this application under different conditions, feel free to contact our support team.
