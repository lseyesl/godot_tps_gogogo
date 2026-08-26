# 兵人概念图：真实提示词与风格规范

本文件同时保存概念图的真实生成提示词和最终成图特征，防止后续生成时发生风格漂移。

环境障碍物、交互物和地面模块的真实提示词另见 `ENVIRONMENT_GENERATION_PROMPTS.md`。

两者用途不同：

- **真实提示词**记录图片最初如何生成，作为不可改写的历史来源。
- **最终成图**才是角色外观、比例、材质和构图的视觉基准。生成模型并不一定完全执行提示词，因此提示词与成图不一致时，应明确记录差异。
- **后续复用规范**提取已经通过评审的稳定特征，用于生成新视角、新武器或敌人变体。

## 视觉基准

| 文件 | 用途 | 优先参考内容 |
|---|---|---|
| `player-front-side-pistol.png` | 玩家标准造型图 | 身体比例、头盔、装甲分块、背包、固定持枪姿势、底座、青绿色材质 |
| `tabletop-miniatures-weapon-modes.png` | 战场与武器模式概念图 | 地图气氛、敌我配色、视野表现、三类武器轮廓、战棋桌面构图 |

后续角色一致性任务必须附带 `player-front-side-pistol.png`；涉及战场、敌人或武器展示时，再追加 `tabletop-miniatures-weapon-modes.png`。

## 真实生成提示词

以下内容按实际生成时使用的提示词保存，仅调整为 Markdown 代码块，不修改原意。

### 战场与三种武器模式

生成结果：`tabletop-miniatures-weapon-modes.png`

```text
Use case: stylized-concept
Asset type: landscape game art-direction concept sheet for a mobile tactical third-person shooter
Primary request: premium concept art for tabletop wargame miniatures fixed permanently in side-standing combat poses on round bases.
Demonstrate exactly three swappable weapon configurations: pistol, rifle/machine gun, and rocket launcher.
Scene/backdrop: a modular dark industrial tabletop battlefield with brick partitions, wooden breakable walls, oil and gasoline barrels,
cover lanes, and a glowing objective beacon.
Subject: one teal player miniature and several red guard miniatures, all visibly attached to faction-colored round bases. Rigid sculpted
toy-soldier bodies; movement is represented by the whole base sliding and rotating, not leg animation. Weapons attach cleanly at hand
sockets.
Style/medium: polished stylized low-poly 3D render, collectible painted-resin board-game miniature aesthetic, chunky readable silhouettes
suitable for an Android phone screen, distinctive and feasible to model.
Composition/framing: 16:9 landscape concept board. Large three-quarter top-down gameplay vignette on the left/center. On the right, exactly
three clean full-body character callouts showing pistol pose, rifle pose, and rocket-launcher pose. Clearly show bases, weapon silhouettes,
muzzle attachment points, subtle base motion streaks, muzzle flash, hit flash, and a faint 120-degree vision cone. No written labels.
Lighting/mood: cool dramatic industrial lighting with warm muzzle flashes, tactical tension, high readability.
Color palette: charcoal terrain, muted brick and wood, teal player accents, red enemy accents, amber fire and explosions.
Materials/textures: matte painted resin miniatures, lightly worn base rims, low-poly weapons, subtle edge wear.
Constraints: every character fixed to a base; fixed side-standing poses; exactly three weapon callouts; weapons visibly swappable; no leg
animation implied; no logo, no text, no watermark.
Avoid: realistic military photography, running poses, floating figures, chibi style, fantasy armor, excessive surface detail, pixel art.
```

### 玩家正面与右侧面

生成结果：`player-front-side-pistol.png`

```text
Use case: stylized-concept
Asset type: orthographic 3D character modeling reference sheet
Input image: use the teal player miniature from the previous concept image as the exact style and character-design reference.
Primary request: isolate the teal player tabletop miniature and show the same character in two clean views: full-body front view and exact
full-body right-side profile view. The character is permanently fixed to the same round teal base and holds the pistol in the same rigid
two-handed side-standing combat pose.
Scene/backdrop: neutral dark gray studio background, no battlefield props.
Subject: one consistent teal armored low-poly collectible miniature shown twice, front and side; compact helmet with dark visor, chest
armor, small backpack, utility pouches, chunky boots, pistol, painted-resin round base.
Style/medium: polished stylized low-poly 3D character turnaround render, production-ready modeling reference, painted resin board-game
miniature.
Composition/framing: landscape sheet, front view on the left and right-side profile on the right, equal scale, feet and bases aligned,
complete silhouette visible with generous margins. Orthographic camera with no perspective distortion.
Lighting/mood: even soft three-point studio lighting, clear form separation, minimal shadows.
Color palette: teal armor and base, dark charcoal joints and visor, black pistol, subtle worn edges.
Constraints: preserve the previous player's proportions, helmet, armor language, teal palette and round base; same character and same pistol
pose in both views; fixed to base; no animation; no text, labels, measurements, logo, watermark, enemies, extra weapons, scenery, or cropped
parts.
Avoid: three-quarter camera, running pose, realistic human skin, fantasy armor, chibi proportions, differing designs between views, floating
character.
```

## 最终成图特征

### 已确认的统一风格

- 低多边形、硬表面、收藏级战棋兵人造型，不是真实军事人物或动画角色。
- 身材紧凑厚重，采用易在 Android 手机屏幕上辨认的夸张轮廓。
- 全封闭多面体头盔、窄黑色面罩、宽肩甲、分块胸甲、粗壮手套和靴子、小型背包与腰包。
- 人物固定为双手持枪的侧身站立姿势；移动和转向由整个底座平移、旋转表现，不制作腿部移动动画。
- 每个角色永久连接厚圆形底座，底座颜色跟随阵营。
- 材质为哑光手绘树脂，边缘有克制的磨损与轻微划痕，不能变成光亮塑料或高频写实材质。
- 玩家使用青绿色装甲和底座，敌人使用暗红色装甲和底座；阵营只改变颜色，不改变身体模型。
- 面罩和关节接近黑色，枪械使用深灰或黑色，保持清晰的武器轮廓。
- 玩家参考主色约为 `#2DC6B4`，敌人参考主色约为 `#CC3830`；色值由成图归纳，并非真实提示词中的硬编码参数。

### 战场概念图实际表现

- 16:9 横向画板，左侧约三分之二为三分之四俯视战场，右侧为三个纵向武器展示格。
- 战场包含深色模块化地砖、砖墙、可破坏木墙、油桶/汽油桶、掩体通道和发光目标点。
- 玩家为青绿色兵人，警卫为暗红色兵人，所有角色都清楚固定在阵营色圆形底座上。
- 青绿色半透明扇形与虚线边界表现玩家有限视野和射程；底座附近用弧形线表现整体转向或移动。
- 枪口使用暖黄色闪光，与冷色工业环境形成对比。
- 右侧按手枪、机枪、火箭枪从上到下展示；每格还出现了独立武器侧视图和青绿色连接标记。

真实提示词与成图的差异：

- 真实提示词只要求武器轮廓、枪口连接点和可更换关系；独立武器侧视图与青绿色连接线是生成结果产生的有效扩展。
- 真实提示词使用 `rifle/machine gun`，项目设计已确定为机枪；后续提示词统一写 `compact machine gun`，避免生成步枪。
- 提示词要求命中闪光，但成图中最明确的是枪口闪光；后续若专门表现受击反馈，需要单独强调命中位置与红色受击高亮。

### 玩家双视图实际表现

- 同一个青绿色兵人出现两次，比例、装甲、底座、磨损和手枪造型基本一致。
- 左侧是偏正面的三分之四视图，而不是严格正面。
- 右侧接近右侧面，但仍保留少量透视和胸甲可见面，并非严格工程正投影。
- 两个角色都朝画面右侧双手持枪，完整身体与完整底座可见，底座大致对齐。
- 背景为暗灰色棚拍环境，光线柔和但仍有方向性、高光和落影。

真实提示词与成图的差异：

- 提示词明确要求严格正面、严格右侧面、正交相机，并要求避免三分之四视角；最终图片没有完全执行这些要求。
- 因此这张图适合作为美术风格和大体比例参考，不应被当作精确的正交建模三视图。
- 若后续需要直接辅助建模，应重新生成或由建模人员绘制严格正面、右侧面和背面，并校正各视图的装甲对应关系。

## 后续复用规范

### 不允许漂移的特征

1. 头盔、面罩、肩甲、胸甲、背包、腰包、手套、靴子和身体比例。
2. 固定在圆形底座上的侧身双手持枪姿势。
3. 低多边形硬表面与哑光做旧树脂材质。
4. 玩家青绿、敌人暗红、武器深灰黑的配色关系。
5. 玩家和普通警卫使用同一身体，只通过程序或材质改变阵营色。
6. 手枪、机枪、火箭枪三种武器类别及其清晰可读的轮廓。

### 允许按任务变化的特征

- 角色展示图使用暗灰棚拍背景；战场图使用暗色工业桌面背景。
- 展示角色时可以使用均匀柔光；战斗场景可以使用冷色电影光和暖色枪口闪光。
- 只有明确设计新警卫类型时，才允许改变轮廓或附加装备，并必须记录与基础兵人的差异。
- 武器变体只更换武器及必要的握持位置，不改变人物装甲、底座和基础姿势。

### 通用风格块

后续新提示词可在真实提示词基础上追加以下稳定描述：

```text
Use the attached approved concept images as the exact visual reference. Preserve the same compact chunky proportions, angular enclosed helmet, narrow black visor, segmented hard-surface armor, backpack, belt pouches, rigid two-handed side-standing pose, thick circular base, matte hand-painted resin material, restrained edge wear, and readable low-poly silhouette. The character is a molded tabletop miniature permanently fixed to the base; movement is represented by sliding and rotating the whole base, never by leg animation. Keep the player teal, guards dark red, and weapons charcoal gray. Do not redesign the body when changing faction color or weapon.
```

### 按场景使用的负面约束

角色标准图：

```text
Avoid photorealistic humans, exposed faces, anime styling, realistic military uniforms, cloth-heavy clothing, thin anatomy, glossy plastic, pristine surfaces, dynamic running or crouching poses, floating characters, missing or square bases, changed helmet or backpack, inconsistent armor between views, extra weapons, scenery, text, labels, measurements, logos and watermarks.
```

战场或武器模式图：

```text
Avoid photorealistic military photography, exposed faces, anime or fantasy armor, running poses, leg animation, floating figures, missing bases, different body models between factions, excessive surface detail, pixel art, written labels, logos and watermarks. Do not add weapons beyond the explicitly requested character and isolated weapon callouts.
```

## 生成与归档流程

1. 选择最接近任务的真实提示词作为基础，并附带对应视觉基准图。
2. 加入通用风格块，再明确本次允许变化的内容，例如武器、阵营色或视角。
3. 根据任务选择角色标准图或战场图负面约束，避免不同用途的约束相互冲突。
4. 对比最终图片和提示词，记录模型未遵循的部分；不要把生成偏差误写成最初需求。
5. 新图片通过评审后，在本文件追加图片路径、真实最终提示词、已确认成图特征和允许变化项。
