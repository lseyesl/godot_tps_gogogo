# Blender 模型材质审计

- 审计日期：2026-08-27
- Blender：4.5.12 LTS
- 范围：`assets/models/prototypes` 下 10 个 GLB

## 结论

所有模型的单一 Principled BSDF 材质均使用了 `Metallic = 1.0` 与 `Roughness = 1.0`。这些资产表现的是砖、木材、布袋、涂漆容器和哑光树脂兵人，不应全部作为纯金属渲染。缺少天空反射贴图时，这一设置会让模型在 Godot Mobile 渲染器中明显偏暗。

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

## 验证

- Blender 复检：10 个模型均为单网格、单材质、`Metallic = 0`。
- 顶点数、三角形数和贴图亮度统计与修补前逐项一致。
- Godot 游戏内固定墙面探针：平均亮度由 0.1889 提升到 0.3663，局部对比度为 0.1289。
- 无需修改贴图像素或使用视野内自发光补丁；木色、砖缝和表面轮廓能够在环境光能量 1.6 下保持可读。
