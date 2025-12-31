# Hosting BatteryBoi Updates on GitHub

This guide details the best practice for hosting Sparkle updates for an open-source project using **GitHub Releases** and **GitHub Pages**.

## Strategy Overview

- **Binaries (`.zip`/`.dmg`)**: Hosted on **GitHub Releases**. This provides free, fast, and reliable storage for large files.
- **Appcast (`appcast.xml`)**: Hosted on **GitHub Pages**. This provides a permanent, direct link (HTTPS) that your app checks for updates.

## 1. Initial Setup

### Step 1: Create a `gh-pages` Branch
1.  Create a new orphan branch in your repository for hosting the website/appcast:
    ```bash
git checkout --orphan gh-pages
git rm -rf .
echo "# BatteryBoi Updates" > index.md
git add index.md
git commit -m "Initial commit for pages"
git push origin gh-pages
    ```
2.  Go to your GitHub Repository Settings -> **Pages**.
3.  Ensure "Build and deployment" source is set to **Deploy from a branch** and select `gh-pages`.

### Step 2: Define Your URLs
Update your `BatteryBoi/BBEnviroments.xcconfig` file with the permanent URLs.
- **ENV_APPCAST_URL**: `https://<YOUR_USERNAME>.github.io/<REPO_NAME>/appcast.xml`
- **ENV_SPARKLE_PUBLIC**: (Keep your existing public key)

---

## 2. Automated Workflow (Recommended)

You can fully automate the update process using **GitHub Actions**. This workflow will run whenever you publish a new Release on GitHub.

### Prerequisites
1.  **Export the Private Key**:
    -   Locate your Sparkle Private Key (generated earlier).
    -   Copy the content (Base64 string).
2.  **Add to GitHub Secrets**:
    -   Go to Repo Settings -> **Secrets and variables** -> **Actions**.
    -   Create a New Repository Secret named `SPARKLE_PRIVATE_KEY`.
    -   Paste your key.

### Create the Workflow File
Create a file at `.github/workflows/release.yml`:

```yaml
name: Publish Update

on:
  release:
    types: [published]

permissions:
  contents: write

jobs:
  update-appcast:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Download Release Assets
        uses: dsaltares/fetch-gh-release-asset@master
        with:
          version: tags/${{ github.event.release.tag_name }}
          file: "BatteryBoi.zip" # The name of the file you uploaded to the release
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Generate Appcast
        env:
          SPARKLE_PRIVATE_KEY: ${{ secrets.SPARKLE_PRIVATE_KEY }}
        run: |
          # Install Sparkle's generate_appcast tool if needed, or use a cached version
          # Here we assume a manual generation or use a helper tool
          # For simplicity in this guide, we use the specific action below:
          
          echo "$SPARKLE_PRIVATE_KEY" > sparkle_key
          
          # Generate appcast assuming the zip is in the current folder
          # NOTE: You might need to install Sparkle cli tool here or use a dedicated action
          # brew install sparkle
          
          /opt/homebrew/bin/generate_appcast . \
            --download-url-prefix "https://github.com/${{ github.repository }}/releases/download/${{ github.event.release.tag_name }}/" \
            --target-url "https://${{ github.repository_owner }}.github.io/${{ github.event.repository.name }}/appcast.xml"
            
          rm sparkle_key

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./ 
          keep_files: true # Keep existing files on the gh-pages branch
          include: "appcast.xml"
```

*Note: The above YAML is a template. For a truly robust setup, we recommend using a dedicated action like `lemnos/sparkle-action` or simply running the commands manually if you prefer control.*

---

## 3. Manual Workflow (Control Freak Mode)

If you prefer to manually manage releases:

1.  **Export & Notarize**: Follow the steps in `SPARKLE_GUIDE.md` to create `BatteryBoi.zip`.
2.  **Draft Release**: On GitHub, draft a new release (e.g., `v1.2.0`). Upload `BatteryBoi.zip`.
3.  **Get Link**: Publish the release. Right-click the uploaded asset to get its direct link (e.g., `https://github.com/.../releases/download/v1.2.0/BatteryBoi.zip`).
4.  **Update Appcast Local**:
    -   Run `generate_appcast /path/to/folder_with_zip`.
    -   **Critical**: Sparkle might not guess the GitHub link correctly. You may need to edit the generated `appcast.xml` and ensure the `url="..."` attribute inside `<enclosure>` points to the **GitHub Release Link** you copied in step 3, not a local file path.
5.  **Push Appcast**:
    -   Switch to your `gh-pages` branch locally.
    -   Copy the new `appcast.xml` there.
    -   Commit and push: `git add appcast.xml && git commit -m "Update appcast" && git push`.
