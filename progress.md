# 进度日志

## 会话：2026-08-25

### 阶段 1：需求与仓库发现
- **状态：** complete
- 执行的操作：
  - 读取 planning-with-files-zh 完整规则与模板。
  - 检查 Git、仓库内容、项目说明与 `.gitignore`。
  - 确认冻结 GDD 是实现基线。
- 创建/修改的文件：
  - `.gitignore`
  - `task_plan.md`
  - `findings.md`
  - `progress.md`

### 阶段 2：工程骨架与架构
- **状态：** complete
- 执行的操作：
  - 创建 Godot 4.7 Mobile 工程配置与项目目录。
  - 建立 WeaponDefinition、HealthComponent、HitscanWeapon 等基础领域组件。
  - 创建玩家、可损坏木墙与主场景。
- 创建/修改的文件：
  - `project.godot`
  - `resources/weapons/standard_pistol.tres`
  - `scripts/resources/weapon_definition.gd`
  - `scripts/components/health_component.gd`
  - `scripts/weapons/hitscan_weapon.gd`
  - `scenes/actors/player.tscn`
  - `scenes/world/damageable_wall.tscn`
  - `scenes/main/main.tscn`

### 阶段 3：首条垂直切片
- **状态：** complete
- 执行的操作：
  - 实现固定方位高位跟随镜头。
  - 实现 4.5 m/s 独立移动、鼠标水平面瞄准和保持朝向。
  - 实现标准手枪射线、6 发弹匣、自动换弹与 16 米射程。
  - 实现常驻分段瞄准线和 5 点耐久木墙。
  - 添加 HUD 与键鼠调试说明。
- 创建/修改的文件：
  - `scripts/actors/player.gd`
  - `scripts/input/debug_player_input.gd`
  - `scripts/camera/fixed_follow_camera.gd`
  - `scripts/weapons/aim_line_3d.gd`
  - `scripts/world/damageable_wall.gd`
  - `scripts/main/main.gd`

### 阶段 4：测试与验证
- **状态：** complete
- 执行的操作：
  - 创建无第三方测试框架的 headless 测试入口。
  - 完成 Godot 全局类导入与语法检查。
  - 验证武器资源、生命组件、场景结构、触控节点和射线伤害链路。
- 创建/修改的文件：
  - `tests/test_runner.gd`

### 阶段 5：交付
- **状态：** complete
- 执行的操作：
  - 添加根目录 README、运行与验证说明。
  - 确认本轮切片完成，下一阶段为视野与警卫 AI。
- 创建/修改的文件：
  - `README.md`

### 阶段 6：对称视野与遮挡
- **状态：** complete
- 执行的操作：
  - 提交首条 Godot 核心切片：`b06c6ca`。
  - 复查玩家、武器、主场景与测试结构。
  - 确定共享 VisionSensor3D 与射线裁切视野网格方案。
  - 实现玩家和警卫共用的 120° / 16 米视觉传感器。
  - 实现受砖墙和木墙射线裁切的地面扇形网格。
- 创建/修改的文件：
  - `task_plan.md`
  - `findings.md`
  - `progress.md`
  - `scripts/perception/vision_sensor_3d.gd`
  - `scripts/perception/vision_cone_3d.gd`
  - `scenes/actors/player.tscn`

### 阶段 7：手枪警卫感知闭环
- **状态：** complete
- 执行的操作：
  - 实现 3 点生命、标准手枪和对称视野警卫。
  - 实现巡逻、预警、战斗、搜索状态与首枪时序。
  - 实现 2 秒攻击暴露、墙体遮挡和最后暴露位置标记。
- 创建/修改的文件：
  - `scripts/actors/pistol_guard.gd`
  - `scenes/actors/pistol_guard.tscn`
  - `scenes/main/main.tscn`
  - `scripts/main/main.gd`

### 阶段 8：感知与战斗验证
- **状态：** complete
- 执行的操作：
  - 自动验证视野角度、距离、墙体遮挡和双方对称性。
  - 自动验证 0.6 秒首枪造成伤害与 2 秒攻击暴露。
  - 自动验证背后显形、墙后隐藏与静止位置标记。
- 创建/修改的文件：
  - `tests/test_runner.gd`

### 阶段 9：第二切片交付
- **状态：** complete
- 执行的操作：
  - 更新 README 和计划记录。
  - 完成语法、回归与 Git 差异检查。
- 创建/修改的文件：
  - `README.md`

### 阶段 10：声音事件领域层
- **状态：** complete
- 执行的操作：
  - 提交感知与警卫切片：`8a0a939`。
  - 确定 SoundEventHub、武器声音数据和警卫调查状态方案。
  - 实现集中式声音事件、武器枪声、玩家脚步声与木墙摧毁声。
- 创建/修改的文件：
  - `task_plan.md`
  - `findings.md`
  - `progress.md`
  - `scripts/audio/sound_event_hub.gd`
  - `scripts/resources/weapon_definition.gd`
  - `resources/weapons/standard_pistol.tres`
  - `scripts/weapons/hitscan_weapon.gd`
  - `scripts/actors/player.gd`
  - `scripts/world/damageable_wall.gd`

### 阶段 11：警卫听声调查
- **状态：** complete
- 执行的操作：
  - 为警卫增加 INVESTIGATE 状态、声源优先级替换和目视覆盖规则。
  - 实现前往声源、现场扫描、超时返回巡逻的闭环。
- 创建/修改的文件：
  - `scripts/actors/pistol_guard.gd`
  - `scenes/main/main.tscn`

### 阶段 12：声音切片验证
- **状态：** complete
- 执行的操作：
  - 自动验证标准手枪 24 米声音半径。
  - 自动验证警卫在半径内调查、半径外保持巡逻。
  - 完成语法检查与完整回归测试。
- 创建/修改的文件：
  - `tests/test_runner.gd`
  - `README.md`

### 阶段 13：二维格子导航层
- **状态：** complete
- 执行的操作：
  - 提交声音事件与警卫调查切片：`9806709`。
  - 复查 ADR-063、064、065、066、069，确定 2 米正交格与导航版本重算方案。
  - 实现 AStarGrid2D 世界服务、碰撞体占格、世界坐标转换和路径查询。
- 创建/修改的文件：
  - `task_plan.md`
  - `progress.md`
  - `scripts/navigation/grid_navigation_3d.gd`
  - `scenes/main/main.tscn`

### 阶段 14：动态开墙与警卫重算
- **状态：** complete
- 执行的操作：
  - 木墙进入场景时注册阻塞格，摧毁时同步注销并递增导航版本。
  - 警卫调查和搜索移动改为沿正交格点路径推进。
  - 警卫检测目标或导航版本变化并重新规划。
- 创建/修改的文件：
  - `scripts/world/damageable_wall.gd`
  - `scripts/actors/pistol_guard.gd`

### 阶段 15：导航验证
- **状态：** complete
- 执行的操作：
  - 验证完整木墙阻塞、路径绕行、摧毁后即时开格和路线缩短。
  - 验证导航版本变化后警卫使用新版本重算。
  - 完成语法检查与完整回归测试。
- 创建/修改的文件：
  - `tests/test_runner.gd`
  - `README.md`

### 阶段 16：安全掩体候选
- **状态：** complete
- 执行的操作：
  - 复查掩体、动态破坏和二维导航规则。
  - 确定以阻塞格四邻域生成候选，并以物理射线、路径可达性和路径长度筛选。
  - 实现 6 米内阻塞格候选、长墙两步探身点和最近路径选择。
- 创建/修改的文件：
  - `task_plan.md`
  - `findings.md`
  - `progress.md`
  - `scripts/ai/cover_service_3d.gd`
  - `scripts/navigation/grid_navigation_3d.gd`
  - `scenes/main/main.tscn`

### 阶段 17：警卫掩体战斗
- **状态：** complete
- 执行的操作：
  - 增加 MOVE_TO_COVER 与 IN_COVER 状态。
  - 实现沿格子路径进入掩体、隐藏计时、移动探身、0.2 秒锁向单发和回撤。
  - 导航或遮挡变化时立即复核掩体；失效后重选或回到移动战斗。
  - 无掩体时实现小于 8 米后退、大于 12 米接近、区间内横向移动。
- 创建/修改的文件：
  - `scripts/actors/pistol_guard.gd`

### 阶段 18：掩体切片验证
- **状态：** complete
- 执行的操作：
  - 验证安全候选、可达性、探身清晰射线和锁向单发。
  - 验证木墙摧毁后候选同逻辑帧失效且警卫放弃无替代掩体。
  - 验证近距后退、远距接近和 8–12 米横移。
  - 完成语法检查与完整回归测试。
- 创建/修改的文件：
  - `tests/test_runner.gd`
  - `README.md`

### 阶段 19：环境反应领域层
- **状态：** complete
- 执行的操作：
  - 提交警卫掩体战斗切片：`e85b8f7`。
  - 复查 ADR-020 至 024、049 至 053、061，冻结首轮燃烧、爆炸、声音和连锁数值。
  - 确定爆炸 FIFO 队列、预伤害遮挡快照和 2 米严格火焰邻接方案。
  - 实现无阵营爆炸目标快照、线性衰减、墙体遮挡和 40 米爆炸声音。
  - 实现严格邻接火焰队列、每秒 1 点角色伤害和 8 米燃烧声音。
- 创建/修改的文件：
  - `task_plan.md`
  - `findings.md`
  - `progress.md`
  - `scripts/world/environment_reaction_hub.gd`
  - `scripts/actors/player.gd`
  - `scripts/actors/pistol_guard.gd`

### 阶段 20：石油与汽油滚筒模块
- **状态：** complete
- 执行的操作：
  - 创建共享环境模块基类，统一导航、碰撞、视觉和活动状态生命周期。
  - 木墙增加 3 秒燃烧、火区伤害和邻接传播。
  - 石油滚筒实现 4 耐久、4 秒燃烧与燃尽开格。
  - 汽油滚筒实现 3 耐久、接火即爆、3 米衰减爆炸与即时开格。
  - 在主场景加入石油→木墙→汽油的可观察连锁排列。
- 创建/修改的文件：
  - `scripts/world/environment_module_3d.gd`
  - `scripts/world/damageable_wall.gd`
  - `scripts/world/oil_barrel_wall.gd`
  - `scripts/world/gasoline_barrel_wall.gd`
  - `scenes/world/damageable_wall.tscn`
  - `scenes/world/oil_barrel_wall.tscn`
  - `scenes/world/gasoline_barrel_wall.tscn`
  - `scenes/main/main.tscn`

### 阶段 21：环境连锁验证
- **状态：** complete
- 执行的操作：
  - 验证石油点燃木墙、木墙触发汽油爆炸的确定性链。
  - 验证斜角不传播、火区每秒 1 点伤害、3/4 秒燃尽和即时开格关碰撞。
  - 验证中心/边缘爆炸伤害、玩家自伤、警卫受伤、砖墙遮挡和同次不穿透。
  - 完成语法检查与完整回归测试。
- 创建/修改的文件：
  - `tests/test_runner.gd`
  - `README.md`

## 测试结果
| 测试 | 输入 | 预期结果 | 实际结果 | 状态 |
|------|------|---------|---------|------|
| 仓库检查 | Git 状态与文件列表 | 确认初始状态 | Git 已初始化，仅 docs 未跟踪 | 通过 |
| Godot 版本 | `godot --version` | Godot 4 可用 | 4.7 stable | 通过 |
| GDScript 语法 | `--check-only --quit` | 无解析错误 | 无错误输出 | 通过 |
| 核心场景测试 | `tests/test_runner.gd` | 资源、场景和组件可运行 | `PASS: core slice tests` | 通过 |
| 射线集成 | 玩家向木墙射击一次 | 弹药 6→5、耐久 5→4 | 符合预期 | 通过 |
| 对称视野 | 玩家与警卫互相观察 | 同为 120°、16 米、受墙遮挡 | 符合预期 | 通过 |
| 警卫首枪 | 等待 0.6 秒预警 | 玩家受 1 点伤害 | 符合预期 | 通过 |
| 攻击暴露 | 背后开火、随后进入墙后 | 显形、墙后隐藏、静止标记 | 符合预期 | 通过 |
| 声音调查 | 半径内、半径外各发出 24 米枪声 | 近处警卫调查、远处警卫保持巡逻 | 符合预期 | 通过 |
| 动态格子导航 | 查询完整墙路线后摧毁单个模块 | 初始绕行、开格后路线缩短、警卫重算 | 符合预期 | 通过 |
| 警卫掩体战斗 | 选择长墙掩体、探身射击、摧毁墙体 | 最近安全候选、单发后回撤、失效后放弃或重选 | 符合预期 | 通过 |
| 无掩体移动 | 分别设置 5 米、15 米、10 米距离 | 后退、接近、横向移动 | 符合预期 | 通过 |
| 环境火焰 | 石油点燃、正交/斜角模块与角色入火区 | 正交连锁、斜角不传播、每秒 1 点、燃尽开格 | 符合预期 | 通过 |
| 汽油爆炸 | 中心玩家、边缘警卫、砖墙后玩家 | 3/1 点衰减、无阵营自伤、墙后免伤 | 符合预期 | 通过 |
| 爆炸遮挡快照 | 爆炸同时摧毁弱化木墙 | 墙后玩家不受同次爆炸伤害 | 符合预期 | 通过 |

## 错误日志
| 时间戳 | 错误 | 尝试次数 | 解决方案 |
|--------|------|---------|---------|
| 2026-08-25 | 用户所述 `.gitignore` 实际不存在 | 1 | 创建标准 Godot `.gitignore` |
| 2026-08-25 | 首次 `--check-only` 无法解析跨脚本 `class_name` 类型 | 1 | 改为先用 headless 编辑器导入生成类缓存，再复查 |
| 2026-08-25 | macOS headless 启动主场景时 `user://logs` 不可写并 signal 11 | 3 | 三种方式均复现，停止重复；改以 check-only、场景测试和后续真机验证覆盖 |
| 2026-08-25 | 自定义 VirtualJoystick 隐藏 Godot 4.7 原生类 | 1 | 三个触控类统一增加 Game 前缀，避免引擎命名冲突 |
| 2026-08-25 | 沙箱内 git add 无法写 `.git/index.lock` | 1 | 改用明确授权的 escalated Git 暂存与提交 |
| 2026-08-25 | ImmediateMesh 视野网格触发 macOS headless 渲染崩溃 | 1 | headless 跳过纯视觉网格，保留感知和 AI 自动测试 |
| 2026-08-25 | 连续 Godot 验证进程再次触发沙箱/MoltenVK 崩溃 | 1 | 拆分为独立测试进程并显式使用兼容后端 |
| 2026-08-25 | 新增 GameGridNavigation3D 后首次 check-only 未识别全局类 | 1 | 先独立执行 Godot 编辑器导入以刷新脚本类缓存，再复查 |
| 2026-08-25 | Godot 无法推断四邻域数组字面量的循环变量类型 | 1 | 使用显式 `Array[Vector2i]` 常量和变量类型标注 |
| 2026-08-25 | 掩体测试在连续长墙上找不到一格探身点 | 1 | 扩展为掩体格周围两步内的最近可达清晰点，保留全部安全筛选 |
| 2026-08-25 | 已摧毁木墙的碰撞在帧末前仍使掩体射线命中 | 1 | 射线忽略导航已注销的碰撞体并继续检测，实现同逻辑帧失效 |
| 2026-08-25 | 后退测试沿用探身结束位置而落入横移距离带 | 1 | 断言前复位警卫到 5 米距离，单独验证近距后退分支 |
| 2026-08-25 | 火焰队列 pop_front 的 Variant 推断被严格类型检查拦截 | 1 | 显式转换为 Node3D，保留类型安全 |
| 2026-08-25 | 环境连锁新增木墙后旧测试数量断言失败 | 1 | 更新为 5 段并补充两类滚筒及环境 Hub 场景断言 |

## 五问重启检查
| 问题 | 答案 |
|------|------|
| 我在哪里？ | 阶段 21：环境燃烧、爆炸与连锁切片完成 |
| 我要去哪里？ | 下一阶段实现机枪、火箭枪和地图武器拾取 |
| 目标是什么？ | 开始实现冻结 MVP，并交付可运行、可测试的核心切片 |
| 我学到了什么？ | 见 findings.md |
| 我做了什么？ | 已完成感知、声音、导航、掩体战斗、燃烧、爆炸、遮挡与确定性连锁 |

---
*每个阶段完成后或遇到错误时更新此文件*
