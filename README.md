# DYO map – deep-zoom viewer

Every hour, GitHub Actions checks the Dan yr Ogof survey repo
(<https://www.cave-registry.org.uk/svn/DYOcatchment/DYO>) for a new revision.
When it finds one, it:

1. exports that revision with `svn export`
2. runs Therion (`dyo-thconfig.thconfig`) to build `map.pdf`
3. turns the PDF into a deep-zoom viewer (OpenSeadragon tiles) with `make-mapviewer.sh`
4. publishes the viewer, `map.pdf` and `revision.txt` to GitHub Pages

The survey data itself is not stored here.

## Rebuild manually

Actions → **Build DYO map** → *Run workflow*. Tick **force** to rebuild even
when the revision hasn't changed (e.g. after editing the script or workflow).

## Run locally

```sh
./make-mapviewer.sh path/to/map.pdf 600 out/   # out/map.html
HTML_NAME=index.html REVISION=95 ./make-mapviewer.sh map.pdf 600 site/
```

Needs `vips` (with PDF/poppler support) and `python3`.

## Notes

- Therion is built from source (pinned to `THERION_VERSION` in the workflow)
  and cached. Bump the version there to upgrade.
- Pages source must be set to **GitHub Actions** (Settings → Pages).
- The scheduled run includes a keepalive step, so GitHub won't disable the
  schedule after 60 days without commits.
