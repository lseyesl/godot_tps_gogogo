# 原型模型

此目录用于存放尚未定稿的 3D 原型模型。

- 推荐格式：`.glb`
- 单位：米
- 坐标：Y 轴向上，角色正面朝向 `-Z`
- 模型原点：角色位于底座中心，环境模块位于网格中心
- 武器挂点：`Grip`、`Muzzle`
- 文件名使用小写蛇形命名，例如 `player_pistol_prototype.glb`

当前环境原型沿用美术交付文件名：`BrickWall.glb`、`WoodenWall.glb`、`WoodenCrate.glb`、`Sandbag.glb`、`OilDrum.glb`、`FuelCan.glb`、`Medkit.glb`、`MissionTerminal.glb` 和 `ExtractionBeacon.glb`。Godot 包装场景位于 `scenes/visuals/environment/`，负责贴地、缩放和复用；不要直接在玩法地图中拉伸 GLB。

正式模型通过评审后再移动到对应的正式资源目录。
