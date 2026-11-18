# Hosting the It’s Giving Privacy and Support pages

The static Apple App Store Connect pages are in `docs/`.

1. In GitHub, open **Settings → Pages** for this repository.
2. Under **Build and deployment**, choose **Deploy from a branch**.
3. Set branch to `main` and folder to `/docs`, then save. Do this after these changes are merged into `main`.
4. Wait for the Pages deployment to finish. GitHub will show the live site URL in the Pages settings.

Expected URLs after Pages is enabled:

- Landing page: `https://williamlebbie9-art.github.io/ItsGiving_AI/`
- Privacy Policy: `https://williamlebbie9-art.github.io/ItsGiving_AI/privacy.html`
- Support: `https://williamlebbie9-art.github.io/ItsGiving_AI/support.html`

Use the Privacy Policy URL in App Store Connect’s **Privacy Policy URL** field. Use the Support URL as your App Store Connect **Support URL**. Verify that both load publicly in a private/incognito browser after deployment before submitting the app.
