# GoGoGo

Android 横屏优先的高位斜俯视第三人称 PvE 射击游戏，使用 Godot 4 开发。

完整冻结设计见 [`docs/design/GDD-MVP-v0.1.md`](docs/design/GDD-MVP-v0.1.md)。

## 当前实现

第一条核心垂直切片已经包含：

- Godot 4 Mobile 工程与 1280×720 横屏基准。
- 固定方位高位斜俯视镜头。
- 4.5 m/s 玩家平面移动与独立朝向。
- Android 左移动摇杆、右瞄准摇杆和可拖动调向的独立射击键。
- 键鼠调试输入：WASD、鼠标瞄准、左键射击。
- 标准手枪 WeaponDefinition、6 发弹匣、0.45 秒射击间隔、1.2 秒自动换弹。
- 16 米即时射线、真实碰撞截断与常驻分段瞄准线。
- 5 点耐久的独立木墙模块，命中 5 次后移除。
- 玩家生命和基础 HUD。
- 无第三方框架的 headless 自动测试。

## 运行

使用 Godot 4.7 或兼容 Godot 4 版本打开项目，然后运行主场景：

```sh
godot --path . --editor
```

桌面调试操作：

- `WASD`：移动
- 鼠标：瞄准
- 鼠标左键：标准手枪单发

触控控件在主场景中常驻显示；移动端会自动禁用键鼠调试输入。

## 验证

```sh
godot --headless --xr-mode off --path . --check-only --quit
godot --headless --xr-mode off --path . --script res://tests/test_runner.gd
```

当前自动测试验证武器数据、生命组件、主场景结构、Android 触控节点，以及标准手枪射线对木墙造成伤害的完整链路。

## 下一条切片

按照冻结 GDD，下一阶段应实现玩家 120° 视野遮罩、砖墙遮挡、手枪警卫感知状态机和攻击暴露。
