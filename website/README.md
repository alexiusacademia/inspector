# inspector's website

The page for the inspector library, live at https://inspector-package.syncster.dev.

Author: Alexius Academia · Started 2026-10-25

A static page: no build step, no dependencies. Netlify (project
`inspector-package`, team syncster.dev)
deploys this folder by itself whenever
`main` is pushed to GitHub.

```
index.html             # the page
styles.css             # chart's and csv's design, in purple
assets/app*.png        # the example app (../examples) snapshotted headless, light and dark
assets/units.png, mixed.png, choice.png, search.png   # close-ups cropped from such snapshots
assets/share.png       # the picture shown when a link to the site is shared (1200 x 630)
assets/favicon.svg
netlify.toml           # no build; HTML isn't cached
```

To look at it locally: `python3 -m http.server 8080 -d website`, then
http://localhost:8080/.

The pictures come from `TESSEL_SCRIPT="…; snapshot file.png" tessel run examples`; retake them after the rows change.
