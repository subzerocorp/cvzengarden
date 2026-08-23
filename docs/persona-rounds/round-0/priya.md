# Priya — round 0

**Walked:** http://127.0.0.1:4320/ , http://127.0.0.1:4320/?theme=quarto , http://127.0.0.1:4320/?theme=switchyard , http://127.0.0.1:4320/?theme=nightgarden , http://127.0.0.1:4320/sandbox.html (the frame the résumé lives in). Guessed and hit `/about`, `/help`, `/docs`, `/new`, `/edit`, `/upload`, `/login`, `/privacy`, `/faq` — all 404. The site never linked me to the README, so I did not read it.
**Time on task:** 8 minutes before I gave up (budget was 20)
**Walk-away:** yes — there is no step where I can put my own résumé in. Not a confusing input step; there is no input step. The page only ever shows "Jordan Hale, Design Engineer".
**Goal reached:** no — I never got my content into a theme, so there was no URL for LinkedIn and no printout of *my* résumé for Thursday.

## Complaints

Ordered by severity. Each one is something the persona would say out loud.

| # | Severity | What happened | What I expected | Where |
| --- | --- | --- | --- | --- |
| 1 | blocker | I landed and it is somebody else's résumé. There is no "Start", "Upload", "Use my résumé", "Edit", no text box, no file picker, no drag-and-drop. I clicked Jordan's name and typed — nothing. I dragged my `Priya_Raman_Resume.pdf` onto the page — nothing. Right-clicked — just the browser menu. I guessed `/new`, `/edit`, `/upload` — 404. After six minutes of poking I concluded this is a demo, not a thing I can use, and left. | A big obvious button on the first screen: "Put your résumé in" that tells me in plain English what to give it (a file? a form? paste text?) with an example I can copy. | http://127.0.0.1:4320/ — the whole left sidebar; the résumé iframe (`title="Résumé preview"`) |
| 2 | blocker | Nothing on the page explains what format the résumé is in. The only hints are jargon: "One Skeleton. Flip a Theme. Print stays print." and "Labels come from `/* rz-target */`. A print Theme is not judged on hover." I do not know what a skeleton is, what `rz-target` is, or who is judging what. If the answer is "JSON Resume" it is never said, let alone explained. | One sentence like "Your résumé is a small text file that looks like this: {example}. Paste it here or upload it." | http://127.0.0.1:4320/ — tagline under "Garden", and the paragraph under "THEMES" |
| 3 | blocker | There is no hosted URL. The only URL that changes is `?theme=quarto`, which is a link to Jordan Hale's résumé. Nothing says "share", "publish", "copy link", "your page". So the thing I came for — a link for my LinkedIn and email signature — does not exist on this site as far as I can see. | A "Publish" / "Copy link" control that gives me `something.com/priya` once my content is in. | http://127.0.0.1:4320/?theme=quarto — nothing in sidebar |
| 4 | major | Zero privacy information. No "who can see this", no "delete", no "take down", no privacy link, no footer at all. I am nervous about a public résumé with my phone number on it, and this site does not say one word about it. (To be fair: it also asked me for nothing, so today there is nothing to take down.) | A short line near the share control: "Only people with the link can see it. Delete anytime here." plus a privacy link in a footer. | http://127.0.0.1:4320/ — no footer, `/privacy` is 404 |
| 5 | major | The printout of the Quarto theme is 3 pages for a résumé that is really 2. Page 1 stops after "Volunteer" with a big empty band at the bottom; page 3 has only "Projects" and is 80% blank. If that were my résumé I would be handing an interviewer a mostly-empty third sheet. | Sections that flow to fill the page, or at least a hint before I print that it will be N pages. | Print button (`.preview-controls__print`) with Quarto active — `/tmp/persona-lab/priya/04-quarto-print.pdf` pages 1 and 3 |
| 6 | major | Switchyard's printout loses its bullet markers. On screen the job bullets have a dash marker; on paper they are just indented lines with nothing in front of them, so it reads like a wall of text. | Bullets on paper match bullets on screen. | Print with Switchyard active — `/tmp/persona-lab/priya/04-switchyard-print.pdf` page 1, "Acme Studio" bullets |
| 7 | minor | Two buttons in the same sidebar are both labelled "Print". One (under THEMES: All / Web / Print) filters the theme list, the other (under VIEW) actually prints. I clicked the wrong one first and nothing happened. | Filter chips say "Print themes" or "For paper"; the action says "Print / Save as PDF". | http://127.0.0.1:4320/ — `THEMES` filter row vs `VIEW > Print` |
| 8 | minor | A section called "CHROME" with System / Light / Dark. I use Chrome the browser; I had to click it to learn it means the grey sidebar's colour. It does not touch the résumé. | Call it "Appearance" or "Sidebar". | http://127.0.0.1:4320/ — sidebar heading "CHROME" |
| 9 | minor | "Print preview emulates `@media print`. Browser print uses the active Theme's print CSS." I trust the preview — it matched the PDF — but the sentence is written for developers. | "What you see here is what the printer will print." | http://127.0.0.1:4320/ — note under the Print button |
| 10 | minor | The theme tags say WEB / PRINT / BOTH but nothing tells me what happens if I print a WEB theme. I tried it: Nightgarden prints fine on white. So the tag scared me for nothing. | Either hide Print for WEB themes, or say "prints on white". | Nightgarden card `WEB` badge; `/tmp/persona-lab/priya/04-nightgarden-print.pdf` |

Severity: **blocker** = goal impossible or walk-away; **major** = goal reached only with real friction; **minor** = polish.

## What worked

- No account, no sign-up, no paywall. Nothing asked for my email. That is the opposite of every résumé builder I have tried this month and I noticed it immediately.
- Picking a theme took under a minute. Three cards, one click each, the résumé re-skins instantly. I chose Quarto (the cream serif one tagged PRINT) on sight; Switchyard was my backup.
- The theme choice lands in the URL (`?theme=quarto`), so a reload keeps it.
- "Print preview" is honest: what it showed me in the frame is exactly what came out of the Print button (`/tmp/persona-lab/priya/03-printpreview.png` vs `04-quarto-print.pdf` page 1).
- Quarto on paper looks like a real, grown-up résumé — name, contact line, ruled section heads, dates flush right. If it were my content I would hand page 1 to an interviewer.
- Nightgarden, a screen-only theme, still prints readably on white instead of dumping a dark background onto paper.
- The page loaded fast and nothing broke while I clicked around.

## Evidence

- `/tmp/persona-lab/priya/01-land.png` — first screen: sidebar + Jordan Hale in Nightgarden; no input controls.
- `/tmp/persona-lab/priya/01-land.mjs` output — page has zero `<a>` links, zero `<input>/<textarea>/<select>`; only buttons are theme/filter/view/chrome.
- `/tmp/persona-lab/priya/02-theme-Quarto.png`, `02-theme-Switchyard.png`, `02-theme-Nightgarden.png` — the three themes; URL became `?theme=<name>` on each click.
- `/tmp/persona-lab/priya/02-themes.mjs` output — keyword scan of body text for "upload / import / json / edit / your / sign / login / account / share / privacy / delete / help" all returned `none`; no `footer`/`nav`/`dialog`; no `contenteditable`, `[type=file]`, or `[draggable]` elements.
- `/tmp/persona-lab/priya/03-tryinput.mjs` output — clicking `h1` and typing "Priya" left it as "Jordan Hale"; `contenteditable in frame: 0`; `inputs in frame: 0`; dropping a PDF on `body` changed nothing; Print button calls `print()` on the iframe (`window.print calls: 10`).
- Route probes via curl: `/about /docs /help /new /edit /editor /upload /resume /login /signin /signup /privacy /faq /README.md` all `404`.
- `/tmp/persona-lab/priya/03-printpreview.png` — Quarto print preview inside the garden.
- `/tmp/persona-lab/priya/04-quarto-print.pdf` (3 pages), `04-switchyard-print.pdf` (2 pages, no bullet markers), `04-nightgarden-print.pdf` (2 pages, white background). Print-media document heights: quarto 1879px, switchyard 1844px, nightgarden 1802px vs ~1056px per Letter page.
- Sidebar text quoted verbatim: "One Skeleton. Flip a Theme. Print stays print." / "Labels come from /* rz-target */. A print Theme is not judged on hover." / "Print preview emulates @media print. Browser print uses the active Theme's print CSS." / heading "CHROME".
