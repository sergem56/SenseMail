# SenseMail

**An iOS mail client with end-to-end encryption built into the app.**

> **Status: discontinued.** SenseMail is no longer published or maintained, and the backend services it used are offline. The source is kept as a portfolio project and as a record of how it was built. It targets iOS 8–era SDKs and may need changes to build with current Xcode.

<!-- Add 2–3 screenshots here: inbox, compose with encryption, security settings -->

## What it was

SenseMail was a standalone iOS client for ordinary IMAP/SMTP mailboxes (and Gmail via OAuth2) that added a layer of encryption on top of regular email. Messages and attachments were encrypted on the device before sending, so the mail provider only ever saw ciphertext. Recipients using SenseMail could decrypt them with a shared key or certificate.

I designed and built it on my own: the mobile app, the encryption layer, the push notification integration, localization, the product website and the App Store release.

## Features

- IMAP/SMTP accounts, plus Gmail sign-in via OAuth2 without an embedded web view
- Encryption of message bodies and attachments on the device
- Certificate exchange between contacts and one-time certificates
- PIN-based app lock, with the PIN stored in the keychain and sessions cleared on lock
- Secure gallery and document attachments
- Address book with autocomplete
- Background mail checks triggered by push notifications
- Strict validation of mail server SSL certificates
- iPhone and iPad layouts
- Localized into several languages, including Spanish, French, Japanese and Russian

## Architecture

The app is written in Objective-C and organized into feature modules in a VIPER-style layout (View / Presenter / Interactor / Router), with a global router coordinating navigation between modules.

Main areas under `SRC/Latest/SenseMail2/`:

| Folder | Responsibility |
|---|---|
| `MessageList`, `MessageView`, `ComposeMessage` | Mail UI and its presenters/interactors |
| `MessageDataLevel` | IMAP/SMTP session handling, OAuth2, local message storage |
| `UserInfoDataLevel` | Accounts, settings and user data persistence (Core Data) |
| `EncryptionLevel` | Encryption, key derivation and integrity checks |
| `CertExchange`, `OneTimeCert` | Key and certificate exchange between contacts |
| `Pin`, `Settings`, `Settings2` | App lock and security/appearance settings |
| `AddressBook`, `Autocomplete` | Contacts |
| `GlobalRouter` | Navigation between modules |

Third-party code (Google's GTMAppAuth / GTMSessionFetcher / AppAuth classes, MailCore) is included in the source tree.

## Encryption design

The encryption module (`EncryptionLevel/Encryptor.m`) works roughly like this:

1. Plaintext is compressed (gzip).
2. An all-or-nothing transform (AONT) is applied to the compressed data.
3. The result is encrypted with AES-256.
4. An HMAC-SHA256 is appended (encrypt-then-MAC), and is verified before any decryption is attempted.

Keys are derived from the user's secret with PBKDF2 (HMAC-SHA256/SHA512). Separate keys are derived for encryption and for the HMAC. Random values come from `SecRandomCopyBytes`.

### Known limitations (written with hindsight)

This design dates from 2015 and I would not build it this way today:

- **Custom construction.** The AONT step and the chunked AES processing are my own design. Modern practice is to use a vetted authenticated cipher (AES-GCM or ChaCha20-Poly1305 via CryptoKit) and not combine primitives by hand. As the code comments themselves note, the AONT adds little protection, because a password guess can be checked against the HMAC without undoing it.
- **Key derivation cost.** Some PBKDF2 iteration counts are far below current recommendations. They were tuned for 2015 mobile CPUs and would need to be raised substantially, or replaced with a memory-hard function.
- **Logging.** The code contains many `NSLog` calls, which should be removed or gated in a security-sensitive app.
- **Tests.** Automated test coverage is minimal (a single encryption round-trip test).
- **Code size.** Several files (storage, common helpers, global router) grew too large and should be split.

I keep these notes here because they are useful lessons: choose boring, audited crypto, test it heavily, and keep modules small.

## Repository layout

```
SRC/Latest/          Xcode project and app source
SRC/Latest/SenseMail2/   App source (see Architecture)
SRC/Latest/SenseMail2Tests/   Unit tests
```

The remaining top-level folders contain the original product website and press kit.

## Building

Open `SRC/Latest/SenseMailShare.xcodeproj` in Xcode. The project is legacy code: expect to update deployment targets, signing settings and some deprecated APIs before it builds on a current toolchain. Push notifications and any server-side features no longer work.

## License

Apache License 2.0. See [LICENSE](LICENSE).
