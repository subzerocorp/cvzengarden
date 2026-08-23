# Elena — round 0

**Walked:** http://127.0.0.1:4320/ , http://127.0.0.1:4320/?theme=quarto , ?theme=switchyard , ?theme=Quarto , ?theme=banana , ?theme=quarto&view=print , http://127.0.0.1:4320/sandbox.html (found in devtools), http://127.0.0.1:4320/themes/quarto.css ; repo file /Users/nathansculli/src/subzero/cvzengarden/README.md (opened on my own — the site never pointed me there)
**Time on task:** ~25 minutes
**Walk-away:** no — none. My trigger is a cryptic JSON error, and I never saw one, because there is nowhere on the site to type anything at all. I would still have closed the tab after about ten minutes, just quietly, because there was nothing for me to do except look at Jordan Hale.
**Goal reached:** no — I could pick a theme and text a friend a link to it, but I could not get my own résumé into it, and there is no hosting, sign-up, or price anywhere, so "hosted page I can link from my portfolio" was impossible.

## Complaints

Ordered by severity. Each one is something the persona would say out loud.

| # | Severity | What happened | What I expected | Where |
| --- | --- | --- | --- | --- |
| 1 | blocker | There is no way to put my own résumé in. The whole page is a sidebar (THEMES / VIEW / CHROME) and Jordan Hale's résumé. Zero inputs, textareas, or editable areas on the page (I counted with the browser: 0). No "Paste", "Upload", "Import", "Edit", "New", or "Start" anywhere. The README says "Paste a JSON Resume, pick a theme, ship a résumé" but the site has no paste box. I couldn't even make my trailing-comma mistakes because there was nothing to type into. | A button like "Use this sample as a starting point" or "Paste your résumé" next to the themes, so I could change "Jordan Hale" to my name and start deleting the parts I don't have. | http://127.0.0.1:4320/ — sidebar, every theme |
| 2 | blocker | Nowhere to host it and no price. I searched the page for "sign", "log in", "price", "$", "free", "host", "publish", "share", "download", "PDF": none of those words appear in the product chrome. /pricing, /about, /new, /edit all 404. So I can't compare it to "free in Google Docs" because I can't find out what it costs or whether a hosted page even exists. | A "Publish" or "Get a link" button, and a line like "Hosted page: $X/year" (or "free") so I could decide. | http://127.0.0.1:4320/ — sidebar; /pricing → 404 |
| 3 | major | "Start from the sample" only works if you cheat. The only route I found was View Source → save `sandbox.html` (18 KB of HTML with `rz-*` classes; the sample name/handle appears in 13 places) → edit it by hand. When I opened my edited copy the theme was gone: `themes/nightgarden.css net::ERR_FILE_NOT_FOUND`, plain Times New Roman with blue links (screenshot 04-my-resume-local.png). It only looked right after I guessed an absolute URL `http://127.0.0.1:4320/themes/quarto.css` (05-my-resume-hack.png). Is it supposed to do that? I assumed I broke it. | Either a real editor, or at least a "Download this résumé as HTML (theme included)" that works when I open it from my desktop. | http://127.0.0.1:4320/sandbox.html ; `<link id="theme-stylesheet" href="themes/nightgarden.css">` |
| 4 | major | The sidebar text made me feel dumb. "One Skeleton. Flip a Theme. Print stays print." then "Labels come from /* rz-target */. A print Theme is not judged on hover." then "Print preview emulates @media print. Browser print uses the active Theme's print CSS." I don't know what a rz-target is or who is judging what on hover. There is no "What is this?", no Help, no About, and no link to the README or GitHub, so I had nowhere to go to find out. | One plain sentence for people like me: "Pick a look for your résumé. Your content stays the same. Print it or share the link." and a Help/About link. | http://127.0.0.1:4320/ — `.theme-switcher` hint text, `.preview-controls__hint` |
| 5 | major | When a friend opens my link on their phone (390px wide) they see the whole control panel first — "Labels come from /* rz-target */" and all — and the résumé starts below the fold. They'd ask "where's the résumé?" (03-share-switchyard-phone.png) | On a phone, the résumé first, controls collapsed into a small "Theme" button. | http://127.0.0.1:4320/?theme=switchyard at 390x844 |
| 6 | minor | A mistyped link fails silently. `?theme=banana` just shows Nightgarden with "Nightgarden" highlighted and no message at all. If I typo the theme name in a text, my friend judges the wrong one and neither of us knows. | A small note: "No theme called 'banana' — showing Nightgarden." | http://127.0.0.1:4320/?theme=banana |
| 7 | minor | There is no "Copy link" / "Share" button. I only found out that the address bar changes to `?theme=quarto` by looking at it. I nearly took screenshots instead. | A "Copy link to this theme" button in the sidebar. | http://127.0.0.1:4320/ — VIEW section |
| 8 | minor | The Print / Screen view doesn't stick. `?theme=quarto&view=print` opens in Screen; after a reload while in Print preview it goes back to Screen. So I can't send someone a link to the print look. | The view in the URL like the theme is. | http://127.0.0.1:4320/?theme=quarto&view=print |
| 9 | minor | "Print" just pops the browser's print dialog with no hint that "Save as PDF" is how you get a PDF. There's no "Download PDF" button, and the sidebar line about it is the @media print sentence from #4. | A "Save as PDF" button, or a hint "Choose 'Save as PDF' in the dialog." | http://127.0.0.1:4320/ — button `.preview-controls__print` |
| 10 | minor | In the Switchyard PDF the bullet points lost their bullets — the job lines are just indented sentences (04-print-switchyard.pdf p.1). Quarto and Nightgarden PDFs keep their dashes/dots. | Bullets in print too. | http://127.0.0.1:4320/?theme=switchyard → Print |
| 11 | minor | The WEB / PRINT / BOTH badges and the Web / Print filter tabs made me think Nightgarden couldn't be printed. It actually prints fine (04-print-nightgarden.pdf, 2 clean pages). So what does "WEB" mean for me? | Plain words: "Looks best on screen" / "Looks best on paper" / "Both". | http://127.0.0.1:4320/ — theme list badges |
| 12 | minor | The sample is a Staff Design Engineer with Awards, Publications, and References. My résumé is one bootcamp, three projects, and a retail job. I can't tell what a thin résumé looks like in any of these themes, which is the thing I actually need to know before I'd pay for anything. | A second, junior-looking sample, or the ability to delete sections and see. | http://127.0.0.1:4320/sandbox.html content |

Severity: **blocker** = goal impossible or walk-away; **major** = goal reached only with real friction; **minor** = polish.

## What worked

- Picking a theme is instant, and the address bar changes to `?theme=quarto`. I opened that exact link in a brand-new browser and it came up with "Quarto" highlighted and the Quarto stylesheet loaded (03-share-quarto.png). Even `?theme=Quarto` with a capital worked. That is the link I would text my friends.
- Quarto genuinely looks more professional than I feel — serif, small caps, dates on the right (02-quarto.png). Switchyard is a good clean second (02-switchyard.png). Nightgarden looks like a dev portfolio in dark mode (03-dark-system.png).
- Print only prints the résumé. The Print button calls print inside the résumé frame, and even Cmd+P on the main page hid the sidebar (03-cmdp-print-media.png). Quarto "Save as PDF" gave me a 3-page PDF with beige paper and no product junk on it (04-print-quarto.pdf).
- Dark/Light chrome follows my system setting and the résumé itself doesn't get messed up by it.
- Nothing crashed, no console errors, no cryptic JSON — though only because there's nowhere to type.
- The phone layout doesn't break; it just puts the controls first (#5).

## Evidence

- /tmp/persona-lab/elena/01-land.png — landing page as seen, Nightgarden default.
- /tmp/persona-lab/elena/01-land.mjs output — 0 inputs/textareas/contenteditable on the page; 12 buttons, 0 links.
- /tmp/persona-lab/elena/02-quarto.png, 02-switchyard.png, 02-dark-nightgarden.png, 02-printpreview-quarto.png, 02-light-quarto.png — theme screenshots I'd send to friends.
- /tmp/persona-lab/elena/03-share-quarto.png, 03-share-Quarto-caps.png — fresh-context link test; DOM showed `theme-switcher__option--selected` on Quarto and frame stylesheet `themes/quarto.css`.
- /tmp/persona-lab/elena/03-share-banana.png — `?theme=banana` silently shows Nightgarden.
- /tmp/persona-lab/elena/03-share-switchyard-phone.png — 390px: résumé below the fold.
- /tmp/persona-lab/elena/03-share-print.mjs output — word search over chrome HTML: json/paste/upload/import/edit/sign/log in/price/$/free/publish/share/export/download/pdf/help/about all `false`.
- curl probes: /resume.json, /skeleton/resume.json, /example.html, /README.md, /pricing, /about, /edit, /new → 404; /sandbox.html and /themes/quarto.css → 200.
- /tmp/persona-lab/elena/03-cmdp-print-media.png, 03-cmdp-quarto.pdf — Cmd+P on main page; sidebar hidden, 3 pages.
- /tmp/persona-lab/elena/04-print-quarto.pdf (3 pages), 04-print-nightgarden.pdf (2 pages), 04-print-switchyard.pdf (3 pages, bullets missing).
- /tmp/persona-lab/elena/04-my-resume-local.png — saved-and-edited sandbox.html opened from disk: unstyled; request log `[failed] file:///tmp/persona-lab/elena/themes/nightgarden.css net::ERR_FILE_NOT_FOUND`.
- /tmp/persona-lab/elena/05-my-resume-hack.png — same file with absolute `http://127.0.0.1:4320/themes/quarto.css` href: styled correctly as "Elena Reyes — Junior Software Developer".
- /tmp/persona-lab/elena/05-printpreview-nightgarden.png, 05-printpreview-switchyard.png — Print preview view; after reload the view reset to Screen (`btn--secondary` on Screen, `btn--ghost` on Print preview).
- /tmp/persona-lab/elena/06-projects.mjs output — every section including Projects is `display:block` in all three themes on screen and print (so nothing is hidden; Projects is simply on page 3).
