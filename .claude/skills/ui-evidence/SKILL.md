---
name: ui-evidence
description: Produce visual proof for any CornerTimer UI change when you can't see a Mac screen — render preview PNGs via macOS CI, download them, embed them in the PR, and write manual test steps for the owner. Use for any PR touching views, themes, windows, the menu bar, the icon or settings.
---

# UI evidence without a screen

Agents usually run on Linux and can't build or look at the macOS app. Reviewers still need to *see* UI changes, so every UI PR must carry rendered images and owner test steps.

## 1. Make the change renderable
- Views must render through the preview renderer (`CornerTimer --render-previews <dir>`, from #8) with a fixed fake `TimeSource`, so the images are deterministic.
- When you add a new state, theme, size or screen, add it to the renderer's list. Filenames follow `<theme>-<state>-<size>.png` (or `settings-<tab>.png`), and the case is added to `index.html`.
- `ImageRenderer` can't draw behind-window blur. Graphite uses its solid fallback in previews; say so where it matters.
- Until #8 lands, `make previews` exits 78 and CI skips it. For #13 the evidence is the PNGs from `make icon`.

## 2. Get the images from CI
Push the branch, wait for the `macos` job, then download the artifact:
```bash
gh pr checks <PR> --watch
run=$(gh run list --branch "$(git branch --show-current)" --workflow CI --limit 1 --json databaseId -q '.[0].databaseId')
gh run download "$run" -n ui-previews -D /tmp/ui-previews
ls /tmp/ui-previews
```
If the artifact is missing, check that the `make previews` (or `make icon`) step ran and wasn't skipped.

## 3. Look at the images
Open the key PNGs with your image-viewing tool (e.g. the Read tool on a `.png`). Check them against the issue's spec: layout, the theme tokens table, states, legibility at small sizes (16/32 px for the icon), and contrast. Fix and re-run before asking for review. Don't describe images you haven't actually opened.

## 4. Put them in the PR
Images in the PR description must be visible without downloading anything:
- Preferred: commit the curated images that are meant to live in the repo (`docs/images/...`, each with a Provenance row) and reference them by their raw URL on the branch:
  `![graphite running](https://raw.githubusercontent.com/AhmosGUC/<repo>/<branch>/docs/images/graphite-running-medium.png)`
- For throwaway review images, don't commit them. Link the `ui-previews` artifact from the run and list the files the reviewer should open.
- Always say which acceptance criteria each image proves.

## 5. Owner test steps
Some behavior can only be checked on a real Mac: floating over full-screen apps, focus not being stolen, Spaces, multiple displays, notifications, global shortcuts, VoiceOver, launch at login. For these, add a section to the PR:

```markdown
## Owner check on a Mac
1. `git fetch && git checkout <branch> && make run` (or download the `app-build` artifact)
2. <exact steps>
3. Expected: <exact result>
```
Also make sure the same check appears in #17's checklist (`docs/QA_CHECKLIST.md` once it exists).

## Rules
- Only images of **CornerTimer**. Never screenshots or images of any other app or website, not even for comparison.
- Never claim "looks correct" without having opened the image.
