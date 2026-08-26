# 环境道具概念图：真实生成提示词

本文件保存环境道具概念图的实际生成提示词。所有图片均使用以下两张已确认概念图作为风格参考：

- `player-front-side-pistol.png`：手绘树脂材质、低多边形硬表面风格。
- `tabletop-miniatures-weapon-modes.png`：战场色板、道具比例、工业桌面氛围。

## 障碍物概念板

生成结果：`environment-cover-props.png`

```text
Use case: stylized-concept
Asset type: modular game environment prop concept sheet for a mobile tactical third-person shooter
Input images: Image 1 is the exact approved material and render-style reference; Image 2 is the exact approved battlefield, cover, scale, palette, and tabletop-miniature reference. Generate a new prop sheet; do not edit or reproduce the input compositions.
Primary request: create one polished cover-prop concept sheet containing exactly seven separated design slots: one modular red-brown brick wall; the same wooden wall shown in exactly three states—intact, heavily damaged with broken and missing planks, and collapsed charred debris; one reinforced wooden crate; one modular concrete low wall; and one stacked sandbag wall. No other props.
Scene/backdrop: neutral dark-charcoal studio backdrop with a subtle floor, isolated assets, no battlefield scene and no characters.
Style/medium: polished stylized low-poly 3D render, collectible hand-painted resin board-game terrain, chunky Android-readable silhouettes, beveled hard-surface shapes, matte paint, restrained edge wear and small scratches, matching the approved references exactly.
Composition/framing: wide landscape concept board, orderly grid, each asset fully visible and separated with generous spacing, consistent orthographic three-quarter top-down camera, scale, and lighting. The three wooden-wall states share the identical footprint, support frame, color, and plank layout so they clearly read as successive damage states of one asset.
Lighting/mood: cool soft studio lighting with subtle rim light and clear shape separation.
Color palette: charcoal floor, muted red-brown brick, dark warm wood, gray concrete, dusty olive-tan sandbags, dark metal brackets.
Materials/textures: painted resin and low-poly game-prop materials, subtle worn edges, readable at mobile scale.
Constraints: exactly seven slots; feasible game-model geometry; every wall module sits flat; no text, labels, numbers, UI, arrows, characters, weapons, barrels, logos, or watermark.
Avoid: photorealism, military photography, fantasy ornament, excessive rubble, high-frequency texture noise, floating or cropped props, mismatched camera angles, different designs between wooden-wall states.
```

成图包含砖墙、完整木墙、重度损坏木墙、倒塌木墙、木箱、混凝土矮墙和沙袋墙。三种木墙状态保持了相同支柱、底座和木板语言，可直接作为连续损坏状态参考。

## 交互物概念板

生成结果：`environment-interactive-props.png`

```text
Use case: stylized-concept
Asset type: interactive game-prop concept sheet for a mobile tactical third-person shooter
Input images: Image 1 is the approved painted-resin material and render-style reference; Image 2 is the approved battlefield palette, prop scale, objective beacon, and tabletop-miniature reference. Generate a new prop sheet; do not edit or reproduce the input compositions.
Primary request: create one polished concept sheet containing exactly five separated game props: (1) one heavy oil barrel designed to burn and disappear, (2) one volatile gasoline barrel designed to explode and disappear, (3) one compact medical kit pickup, (4) one mission activation terminal, and (5) one extraction beacon. No other props.
Scene/backdrop: neutral dark-charcoal studio backdrop with subtle floor, isolated props, no battlefield and no characters.
Subject details: oil barrel is dark olive green with a wide black band, oily grime, and a recessed cap; gasoline barrel is vivid weathered red with pale hazard striping, reinforced rim, and a small fuel cap, clearly different even in silhouette; medkit is a rugged teal-and-off-white hard case with a simple raised cross-shaped medical symbol but no letters; mission terminal is a waist-high charcoal industrial pedestal with amber illuminated screen, chunky buttons, armored base, and upward objective glow; extraction beacon is a low circular mechanical platform with teal/cyan concentric light rings and a short central holographic beam, visually distinct from the amber mission terminal.
Style/medium: polished stylized low-poly 3D render, collectible hand-painted resin board-game props, chunky Android-readable silhouettes, beveled game-model-feasible geometry, matte paint, restrained edge wear and scratches, matching the references exactly.
Composition/framing: wide landscape concept board, five evenly spaced slots, every prop fully visible, consistent orthographic three-quarter top-down camera, scale family, and lighting; mission terminal and extraction beacon may be taller/brighter but must not overlap other props.
Lighting/mood: cool soft studio lighting; controlled amber and teal emissive accents; clear silhouettes.
Color palette: charcoal, dark olive, weathered red, teal, off-white, amber objective light, cyan extraction light.
Constraints: exactly five props; distinguish oil and gasoline by both color and form; no written labels, words, numbers, UI overlays, arrows, characters, weapons, walls, floor tiles, logos, or watermark.
Avoid: photorealism, modern consumer-product styling, fantasy magic, excessive glow obscuring geometry, generic identical barrels, floating or cropped props, mismatched perspectives, clutter.
```

成图通过暗绿黑带和红色警示纹区分石油桶与汽油桶；任务终端使用琥珀色竖向光柱，撤离信标使用青绿色圆形光环，功能识别不依赖文字。

## 地面模块共同规则

三种地面模块分别生成，均遵守：正方形画布、相机完全垂直向下、正交投影、四边水平垂直、无可见侧面、无四分之三视角。它们是模块外观概念图，不是已处理好的无缝 PBR 贴图。

### 装甲钢板

生成结果：`ground-tile-armored-steel.png`

```text
Use case: stylized-concept
Asset type: square modular ground-tile concept image for a mobile tactical third-person shooter
Input image: Image 1 is the exact approved dark industrial tabletop palette, low-poly geometry, painted-resin material, and wear reference. Generate a new ground module, not an edit.
Primary request: one single square dark armored-steel floor module, suitable as the common base terrain tile.
Subject: a square charcoal steel plate made from large readable low-poly panels, beveled outer frame, a few recessed bolts, restrained seams, subtle edge wear and tiny rust marks. Feasible as a simple game model and readable on Android.
Style/medium: polished stylized low-poly 3D game asset, hand-painted matte resin/metal appearance matching the reference.
Composition/framing: square image; exact 90-degree vertical top-down orthographic view; all four tile edges perfectly horizontal and vertical; centered and symmetrical; the square module fills nearly the entire canvas with a narrow even dark margin. Absolutely no three-quarter angle, no visible side faces, no perspective distortion, no horizon.
Lighting/mood: neutral soft overhead lighting, even material readability, no cast shadow obscuring edges.
Color palette: charcoal black and gunmetal gray with restrained cool highlights and tiny muted rust accents.
Constraints: exactly one square ground module, no other objects, no scenery, no characters, no walls, no text, no symbol, no UI, no logo, no watermark.
Avoid: isometric view, diagonal tile rotation, perspective, visible thickness, photorealism, busy micro-detail, circular focal design, cracks large enough to imply damage.
```

### 混凝土板

生成结果：`ground-tile-concrete.png`

```text
Use case: stylized-concept
Asset type: square modular ground-tile concept image for a mobile tactical third-person shooter
Input image: Image 1 is the exact approved dark industrial tabletop palette, low-poly geometry, painted-resin material, and wear reference. Generate a new ground module, not an edit.
Primary request: one single square worn industrial-concrete floor module, visually distinct from the common armored-steel tile.
Subject: a square medium-dark gray concrete slab divided into a few large readable poured sections, beveled reinforced outer frame, sparse embedded metal corner plates, two or three restrained shallow cracks, small chips and muted grime. Feasible as a simple game model and readable on Android; still compatible beside a dark steel battlefield tile.
Style/medium: polished stylized low-poly 3D game asset, hand-painted matte resin/concrete appearance matching the reference.
Composition/framing: square image; exact 90-degree vertical top-down orthographic view; all four tile edges perfectly horizontal and vertical; centered and symmetrical; the square module fills nearly the entire canvas with a narrow even dark margin. Absolutely no three-quarter angle, no visible side faces, no perspective distortion, no horizon.
Lighting/mood: neutral soft overhead lighting, even material readability, no cast shadow obscuring edges.
Color palette: cool medium-dark concrete gray, charcoal seams, muted steel corner plates, restrained dust and tiny rust accents.
Constraints: exactly one square ground module, no other objects, no scenery, no characters, no walls, no text, no symbol, no UI, no logo, no watermark.
Avoid: isometric view, diagonal tile rotation, perspective, visible thickness, photorealism, busy small rubble, severe structural damage, circular focal design, vegetation.
```

### 排水格栅板

生成结果：`ground-tile-drainage-grate.png`

```text
Use case: stylized-concept
Asset type: square modular ground-tile concept image for a mobile tactical third-person shooter
Input image: Image 1 is the exact approved dark industrial tabletop palette, low-poly geometry, painted-resin material, and wear reference. Generate a new ground module, not an edit.
Primary request: one single square industrial drainage-grate floor module, visually distinct from the armored-steel and concrete modules.
Subject: a square charcoal metal floor tile with one broad central rectangular drainage grate, thick widely spaced bars readable on Android, simple beveled outer frame, a few large plate sections and recessed bolts, restrained grime and tiny rust at grate edges. The grate is dark beneath but not a deep hole. Feasible as a simple game model.
Style/medium: polished stylized low-poly 3D game asset, hand-painted matte resin/metal appearance matching the reference.
Composition/framing: square image; exact 90-degree vertical top-down orthographic view; all four tile edges and grate bars perfectly horizontal and vertical; centered and balanced; the square module fills nearly the entire canvas with a narrow even dark margin. Absolutely no three-quarter angle, no visible side faces, no perspective distortion, no horizon.
Lighting/mood: neutral soft overhead lighting, even material readability, no cast shadow obscuring edges.
Color palette: charcoal black, gunmetal gray, near-black grate recesses, restrained cool highlights and muted rust.
Constraints: exactly one square ground module with exactly one main grate; no other objects, no scenery, no characters, no walls, no text, no hazard letters or symbols, no UI, no logo, no watermark.
Avoid: isometric view, diagonal tile rotation, perspective, visible thickness, photorealism, thin noisy mesh, multiple tiny drains, water, sewage, strong glowing light, circular focal design.
```
