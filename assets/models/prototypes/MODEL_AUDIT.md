# Blender 模型材质审计

- 审计日期：2026-08-27
- Blender：4.5.12 LTS
- 范围：`assets/models/prototypes` 下 16 个 GLB

## 结论

所有模型的单一 Principled BSDF 材质最初均使用了 `Metallic = 1.0` 与 `Roughness = 1.0`。这些资产表现的是砖、木材、布袋、涂漆容器、哑光树脂兵人和涂装武器，不应全部作为纯金属渲染。缺少天空反射贴图时，这一设置会让模型在 Godot Mobile 渲染器中明显偏暗。

本轮将 10 个 GLB 的 `metallicFactor` 统一修正为 `0`，保留 `Roughness = 1.0`。修补只修改 GLB 的材质 JSON；BIN 网格、UV、法线、索引与嵌入贴图字节保持不变。

## 原始贴图亮度

以下数值由 Blender 读取 1024×1024 sRGB 嵌入贴图后在线性空间统计：

| 模型 | 平均亮度 | 中位亮度 | 低于 0.04 的像素 | 处理 |
| --- | ---: | ---: | ---: | --- |
| BrickWall | 0.0756 | 0.0699 | 29.5% | Metallic 1→0 |
| ExtractionBeacon | 0.1563 | 0.1046 | 14.8% | Metallic 1→0 |
| FuelCan | 0.1279 | 0.1016 | 20.3% | Metallic 1→0 |
| Medkit | 0.2749 | 0.2196 | 4.1% | Metallic 1→0 |
| MissionTerminal | 0.0996 | 0.0815 | 24.4% | Metallic 1→0 |
| OilDrum | 0.1888 | 0.1618 | 5.8% | Metallic 1→0 |
| Sandbag | 0.0916 | 0.0495 | 47.0% | Metallic 1→0 |
| WoodenCrate | 0.2234 | 0.2122 | 0.9% | Metallic 1→0 |
| WoodenWall | 0.1164 | 0.0790 | 32.8% | Metallic 1→0 |
| player | 0.1430 | 0.1010 | 29.4% | Metallic 1→0 |
| player-rifle | 0.1411 | 0.0930 | 34.6% | Metallic 1→0 |
| player-rocket | 0.1398 | 0.0938 | 24.7% | Metallic 1→0 |
| weapon-pistol | 0.1098 | 0.1095 | 20.0% | Metallic 1→0 |
| weapon-rifle | 0.1303 | 0.1252 | 18.2% | Metallic 1→0 |
| weapon-rocket-launcher | 0.1281 | 0.1235 | 13.2% | Metallic 1→0 |
| weapon-rocket-projectile | 0.1353 | 0.1171 | 8.2% | Metallic 1→0 |

## 角色与武器网格结构

- `player.glb`、`player-rifle.glb` 和 `player-rocket.glb` 都只有一个 `geometry_0` 网格和一个材质；枪械不是独立节点，不能在 Godot 中单独隐藏。
- 三套 player 模型没有相同的顶点拓扑或可直接复用的精确顶点。按空间范围删除内嵌枪械可能同时破坏手指、手套或身体，未采用这种做法。
- 运行时按当前武器切换三套完整兵人：手枪和重手枪使用 `player.glb`，机枪使用 `player-rifle.glb`，火箭枪使用 `player-rocket.glb`。
- `weapon-pistol.glb`、`weapon-rifle.glb` 和 `weapon-rocket-launcher.glb` 用于地图武器拾取物；`weapon-rocket-projectile.glb` 用于飞行中的火箭弹。

## 验证

- Blender 复检：16 个模型均为单网格、单材质、`Metallic = 0`。
- 顶点数、三角形数和贴图亮度统计与修补前逐项一致。
- Godot 游戏内固定墙面探针：平均亮度由 0.1889 提升到 0.3663，局部对比度为 0.1289。
- 无需修改贴图像素或使用视野内自发光补丁；木色、砖缝和表面轮廓能够在环境光能量 1.6 下保持可读。
