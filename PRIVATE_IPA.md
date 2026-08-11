# Install Potter privately without a paid developer account

This route is for installing Potter on your own iPhone. It does not publish the
app to the App Store and does not require a paid Apple Developer Program
membership.

The build has two stages:

1. GitHub Actions uses a hosted Mac to compile an unsigned IPA.
2. AltStore on your Windows PC signs that IPA locally with your Apple Account
   and installs it on your iPhone.

Never send your Apple Account password, verification code, or signing files to
anyone. Enter account details only into software running locally on your own
computer or iPhone.

## Stage 1: build the unsigned IPA

1. Create a GitHub repository for Potter and upload the contents of this
   project. The `.github` folder must be at the repository root.
2. Open the repository's **Actions** tab.
3. Choose **Build unsigned Potter IPA**.
4. Select **Run workflow**.
5. When the run is green, open the repository's **Releases** page and open the
   draft named **Potter 8.0 private IPA**. Draft releases are visible only to
   repository collaborators with write access.
6. Download `Potter-8.0-unsigned.ipa`. The run also keeps a zipped Actions
   artifact as a backup.

The workflow compiles with Xcode on GitHub's macOS runner. The resulting IPA is
not installable until stage 2 signs it for your iPhone.

## Stage 2: sign and install it from Windows

1. Follow AltStore's current
   [Windows installation guide](https://faq.altstore.io/altstore-classic/how-to-install-altstore-windows).
2. Connect your iPhone to the PC and install AltStore on the phone.
3. Transfer `Potter-8.0-unsigned.ipa` to the iPhone, for example with iCloud
   Drive or the Files app.
4. In AltStore, open **My Apps**, tap **+**, and choose the Potter IPA.
5. Keep AltServer available on the PC and refresh Potter before its signing
   period expires.

Apple's free Personal Team provisioning profiles expire after seven days. The
app must therefore be refreshed or reinstalled weekly. Apple also limits free
accounts to three installed development apps per device and ten App IDs per
seven-day period. See Apple's
[membership comparison](https://developer.apple.com/support/compare-memberships/).

## Run the Potter server on the Windows PC

The IPA is the iPhone interface. Potter's Python agent and OpenAI API key remain
on your computer.

In PowerShell from the project folder:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
py -m pip install -e .
$env:OPENAI_API_KEY="paste_your_key_here"
potter serve --host 0.0.0.0
```

Keep that PowerShell window open. Connect the iPhone and PC to the same trusted
Wi-Fi network, then enter the server URL and access token shown in PowerShell
into Potter's iPhone settings. Windows may ask whether Python can communicate
through the firewall; allow it for private networks only.
