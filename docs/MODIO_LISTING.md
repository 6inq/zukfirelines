# mod.io listing answers: ZukFireLines

Copy each field into the mod.io "Create Plugin" form. You're making the listing image yourself (16:9, min 512x288, max 8MB).

---

## Basics

**Plugin name**
```
ZukFireLines
```

**Summary** (250 character max; this is 214)
```
Highlights TzKal-Zuk's fire lines on the floor as they sweep across the arena. Tiles follow the fire and vanish when it passes. 3 or 5 tiles wide, in any colour. Shows only what's on screen, no prediction. By 6ing.
```

**Homepage**
```
https://github.com/6inq/zukfirelines
```

**Profile URL**
```
https://mod.io/g/runescape/m/zukfirelines
```

**Community**
- Allow comments: **checked**
- Allow dependants: **unchecked**

---

## Description

Click the `<>` (source code) button in the editor toolbar and paste this:

```html
<p>ZukFireLines makes TzKal-Zuk's fire lines easier to see by highlighting the floor tiles they cover as they sweep across the arena.</p>

<h2>Features</h2>
<ul>
<li><strong>Follows the fire:</strong> tiles light up where a fire line is right now, move with it, and disappear the moment it passes.</li>
<li><strong>3 or 5 tiles wide:</strong> choose how wide each highlighted row is.</li>
<li><strong>Any colour you want</strong>, including transparency, so it reads clearly against the arena.</li>
</ul>

<h2>How to use</h2>
<ol>
<li>Enable the plugin.</li>
<li>Open the settings: pick 3 or 5 tiles and your colour.</li>
<li>Fight Zuk. Fire lines are highlighted as they cross the arena.</li>
</ol>

<h2>Fair play</h2>
<p>ZukFireLines only makes what is already on screen easier to see. It does not predict where fire lines will go, mark safe spots, or act for you in any way.</p>

<h2>Requires</h2>
<p><strong>PrettyUI</strong> (installed automatically).</p>

<p>Created by <strong>6ing</strong>. Feedback welcome in the comments.</p>
```

---

## Tag selection

**Gameplay**
- Combat: **checked**

**Theme**
- Accessibility: **checked**
- Interface: **checked**

**Technical**: none

**Permissions**: **none**

**Mobile**
- Mobile UI friendly: **unchecked**

---

## Visibility
Start with **Private**, then switch to **Public** after testing in the live client.

## Before you submit
- [ ] Find the fire-line ids with the Arena inspector, enter them in the settings, and confirm the tiles follow the fire.
- [ ] Add the confirmed ids to `src/data/fire_ids.lua` so it works for everyone without setup, then rebuild.
- [ ] Turn the Arena inspector off again.
- [ ] Build with `python tools/build.py` and upload `dist/zuk-fire-lines-1.0.0.zip`.
- [ ] Upload your listing image.
