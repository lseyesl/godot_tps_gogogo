# 概念图生成提示词

本文件记录当前兵人概念图的可复用提示词。后续生成角色、武器或场景概念图时，优先把现有图片作为视觉参考，并将下面的“固定风格块”原样加入提示词；不要只写“战棋兵人风格”。

## 视觉参考

- `player-front-side-pistol.png`：玩家造型、比例、材质与标准手枪的主要参考。
- `tabletop-miniatures-weapon-modes.png`：地图气氛、敌我配色和三类武器展示方式的参考。

## 固定风格块

```text
Stylized low-poly 3D tabletop miniature for a dark tactical action game. A compact, chunky sci-fi armored soldier permanently fixed to a thick circular miniature base. Fully enclosed angular helmet with a narrow black visor, broad shoulder plates, segmented chest armor, blocky gloves and boots, small backpack and belt pouches. Rigid side-on two-handed aiming pose like a molded board-game piece; no animation pose. Simplified readable silhouette, consistent heroic proportions, beveled hard-surface armor panels, hand-painted resin material, matte paint with restrained edge wear and small scratches. Dark charcoal studio background, soft cinematic key light and subtle rim light, high contrast but readable details, premium game concept render. Keep the same helmet, armor panel layout, backpack, body proportions, pose and circular base across every image.
```

固定阵营色：

- 玩家：青绿色装甲与同色圆形底座，主色约 `#2DC6B4`，黑色面罩，深灰武器。
- 敌人：暗红色装甲与同色圆形底座，主色约 `#CC3830`，黑色面罩，深灰武器。
- 阵营只改变装甲和底座主色，不改变模型、身材、装备布局或姿势。

## 玩家正面与侧面标准图

对应 `player-front-side-pistol.png`：

```text
[固定风格块]

Character turnaround concept sheet of exactly the same teal player miniature shown twice: one front three-quarter view on the left and one clean right-side profile on the right. Both figures stand on identical thick teal circular bases and hold the same oversized dark-gray semi-automatic pistol in a rigid two-handed aiming pose toward screen right. Preserve identical armor geometry, helmet, visor, backpack, pouches, proportions, paint color and surface wear in both views. Full body and full base visible with comfortable margins. Symmetrical two-column composition, dark neutral seamless studio background, no divider, no labels, no scenery, no additional equipment.
```

## 三种武器模式概念图

对应 `tabletop-miniatures-weapon-modes.png`：

```text
[固定风格块]

Wide 16:9 game concept board. Left two-thirds: an isometric dark industrial tabletop arena made from square floor tiles, short brick walls, wooden barricades, oil drums and a glowing objective beacon. One teal player miniature aims through a translucent teal 120-degree vision cone with a dashed range arc; several red enemy miniatures use cover and fire back. Keep all characters as identical molded tabletop soldiers on thick colored circular bases. Right one-third: three equal stacked studio panels showing the same teal player miniature in the same fixed side-on stance, equipped respectively with (top) a chunky semi-automatic pistol, (middle) a compact machine gun, and (bottom) a large shoulder-fired rocket launcher. Beside each figure, show a clean isolated side-view of the matching weapon connected by a small teal glowing dot and short line. Cohesive low-poly hard-surface design, worn painted resin, dark charcoal background, cinematic tabletop lighting, no text or labels.
```

## 单独武器变体模板

将 `{WEAPON}` 替换为 `semi-automatic pistol`、`compact machine gun` 或 `large shoulder-fired rocket launcher`：

```text
[固定风格块]

The same teal player miniature holding {WEAPON}. Preserve the character mesh, fixed side-on two-handed aiming pose, armor, helmet, backpack, proportions, circular base, camera height, lighting and material exactly as in the reference player concept. Only replace the weapon and make the minimum hand placement adjustment required to grip it. Full body and base visible, isolated on a dark charcoal studio background, no text, no props.
```

## 负面约束

```text
Avoid photorealistic humans, exposed faces, anime styling, realistic military uniforms, cloth-heavy clothing, thin realistic anatomy, organic curves, glossy plastic, pristine surfaces, bright colorful backgrounds, dynamic running or crouching poses, animation keyframes, floating characters, missing base, square base, different armor between factions, changed helmet or backpack, oversized scenery in character sheets, extra weapons, extra limbs or fingers, malformed hands, text, captions, logos, UI labels and watermarks.
```

## 后续生成规则

1. 角色一致性任务必须附带 `player-front-side-pistol.png` 作为参考图；场景一致性任务再追加 `tabletop-miniatures-weapon-modes.png`。
2. 每次提示词都包含固定风格块、阵营色、具体构图和负面约束。
3. 新敌人默认只换为暗红色，不重做身体；不同警卫类型确实需要轮廓差异时，再单独记录变更项。
4. 武器变体只允许更换武器及必要的握持位置，不改变角色姿势、装甲和底座。
5. 生成出通过评审的新标准图后，将其文件名、最终提示词和明确允许变化的部分继续补充到本文件。
