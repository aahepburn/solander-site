# Moving Solander to its own subdomain

> **Status, 24 September 2026:** steps 1–5 are done. The subdomain is live over HTTPS, and
> `quietsignalslab.com/solander/*` and `/privacy/solander.html` are redirect stubs. Only
> step 6, submitting to Paddle, is left.

Why: Paddle's domain review says to submit only domains *directly related to the product you're
selling*, and warns that unrelated products on the same domain raise buyer confusion and
chargeback risk. `quietsignalslab.com` also carries a consulting **Services** section, and
Paddle's Acceptable Use Policy restricts pure human services. `PRO_APP_SPEC.md` §13.4 already
called for a dedicated product site; this is it.

A GitHub Pages site can have exactly **one** custom domain, and `aahepburn.github.io` already
serves `quietsignalslab.com`. So this has to be a second repository. That is the only reason
it is one.

## Order matters

**Do steps 1–4 before step 5.** Step 5 replaces the live `/solander/` pages with redirects. Run
it early and those pages point at a subdomain that does not resolve yet, so the live site breaks
until DNS propagates.

---

## 1. Create the repository

Push this directory to a new repo, e.g. `aahepburn/solander-site`. It must be **public**, or on
a paid plan — GitHub Pages on a private repo needs Pro/Team/Enterprise.

```sh
cd /Users/aahepburn/Projects/solander-site
git init && git add -A && git commit -m "Solander product site, split from quietsignalslab.com"
git branch -M main
git remote add origin https://github.com/aahepburn/solander-site.git
git push -u origin main
```

## 2. DNS

Wherever `quietsignalslab.com`'s DNS lives, add:

| Type | Name | Value |
|---|---|---|
| CNAME | `solander` | `aahepburn.github.io.` |

**The target is `aahepburn.github.io`, not `quietsignalslab.com`.** Pointing a subdomain at the
apex is the usual way this fails.

Check it before moving on — DNS can take anywhere from a minute to a few hours:

```sh
dig +short solander.quietsignalslab.com CNAME
```

## 3. Turn on Pages

In the new repo: **Settings → Pages**.

- Source: **GitHub Actions** (the workflow in `.github/workflows/static.yml` deploys it, and
  runs the three gates in `ci/` first).
- Custom domain: `solander.quietsignalslab.com`. The `CNAME` file in this repo already contains
  it, so this should populate on its own once the deploy runs.
- **Enforce HTTPS**: tick it once the box is available. GitHub provisions the certificate after
  DNS resolves — usually minutes, occasionally up to 24 hours. Paddle requires HTTPS, so do not
  submit for review until this is on.

## 4. Check it

```sh
curl -sSI https://solander.quietsignalslab.com/ | head -3
```

Then click through Terms, Refunds and Privacy from the footer of each page, and confirm nothing
navigates back to the consulting site — that is the whole point of the move.

## 5. Redirect the old paths

Only now. GitHub Pages has no server-side redirects, so these are meta-refresh stubs with a
visible link for anyone whose browser blocks the refresh.

Run this in the **website** repo (`aahepburn.github.io`):

```sh
cd /Users/aahepburn/Projects/aahepburn.github.io
for pair in "solander/index.html:" "solander/terms.html:terms.html" \
            "solander/refunds.html:refunds.html" "privacy/solander.html:privacy.html"; do
  file="${pair%%:*}"; target="${pair##*:}"
  cat > "$file" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Solander has moved</title>
<link rel="canonical" href="https://solander.quietsignalslab.com/${target}">
<meta http-equiv="refresh" content="0; url=https://solander.quietsignalslab.com/${target}">
</head>
<body>
<p>Solander now lives at
<a href="https://solander.quietsignalslab.com/${target}">solander.quietsignalslab.com</a>.</p>
</body>
</html>
HTML
done
./ci/markup-sanity.sh && git add -A && git commit -m "Solander pages moved to solander.quietsignalslab.com"
```

Leave the root `index.html`'s Solander card and footer links alone — they already point at
`/solander/`, which now redirects. Change them to the new host whenever convenient.

## 6. Submit to Paddle

Submit `solander.quietsignalslab.com`. Only one approved domain is needed to proceed with
verification. Have ready, in case they ask:

- **A custom/enterprise pricing sheet.** The Organisations tier says "Talk to us… we will
  quote", which is custom pricing. Paddle wants it as a downloadable PDF on request.
- A processing statement — you will not have one as a new business, and Paddle says they take
  that into account.

## What is not here

- **`appcast.xml`.** Sparkle's feed is generated at release time from `release/appcast.xml` in
  the Solander repo and uploaded to this site's root. `SUFeedURL` in the app's `Info.plist`
  points at `https://solander.quietsignalslab.com/appcast.xml`. **A redirect stub cannot serve
  it** — a meta refresh is HTML and Sparkle needs XML — which is exactly why the feed moved
  here with the pages rather than staying behind.
- **`fonts/`.** These pages use system font stacks only; the web fonts belong to `writing/`.
