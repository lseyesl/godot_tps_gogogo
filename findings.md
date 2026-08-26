# 发现与决策

## 需求
- 按已冻结的 `docs/design/GDD-MVP-v0.1.md` 开始实现游戏。
- Godot 4 + Mobile 渲染器，Android 横屏优先。
- 当前首要目标是可运行、可验证的核心垂直切片，而非一次性堆完全部 MVP 内容。
- 用户要求提交已完成切片并继续；首次提交为 `b06c6ca`。
- 当前继续范围是 120° 视野遮挡、手枪警卫感知和攻击暴露。
- 对称视野与警卫 AI 已提交为 `8a0a939`；继续实现声音事件与听声调查。
- 声音事件与警卫调查已提交为 `9806709`；继续实现二维格子导航和动态开墙。
- 格子导航与动态开墙已提交为 `14ffd2e`；继续实现警卫掩体战斗。
- 警卫掩体战斗已提交为 `e85b8f7`；继续实现燃烧、爆炸与环境连锁。
- 环境燃烧与爆炸已提交为 `bce524d`；继续实现多武器、实体火箭和地图拾取。
- 多武器、地图拾取与实体火箭已提交为 `a5d58eb`；继续实现任务激活、全体警戒、返回出生点撤离与结算。
- 任务激活、全体警戒、撤离与结算已提交为 `fc8bcd8`；继续实现候选点生成、稳定重试种子和急救包。
- 随机候选点生成、稳定重试种子和急救包已提交为 `c86bdff`；继续实现轻度瞄准吸附与完整盲区表现。
- 瞄准吸附与盲区反馈已提交为 `df75057`；用户指定 Android 构建由 GitHub Actions 负责，不要求本地 Android 环境。
- 用户要求 Android Build 只允许手动触发，不在 `main` 推送或 Pull Request 时自动构建。
- 用户要求构建后的 Android APK 直接放入 GitHub Release，不再只保留 workflow artifact。

## 研究发现
- 仓库已在 `main` 分支初始化 Git。
- 开始实现时仓库只有未跟踪的 `docs/`，没有 Godot 工程、代码、`AGENTS.md` 或实际 `.gitignore`。
- 冻结设计包含 76 份 ADR；胜利条件是激活远端任务点后返回出生点撤离，而非全灭敌人。
- 玩家/敌人视野和武器射程的共同尺度为 8 个 2 米模块，即 16 米。
- 当前环境安装 Godot `4.7.stable.official.5b4e0cb0f`。
- Godot 工程可以完全使用 PrimitiveMesh 和 typed GDScript 构建首条切片，不依赖外部美术资源。
- 仓库当前没有 `export_presets.cfg` 或 `.github/workflows/`；`project.godot` 已设置 1280×720、横屏与 Mobile 渲染器。
- Android 调试 APK 可使用 Godot 默认调试签名在 CI 产出，无需将发布密钥放入仓库；正式上架签名后续单独配置。
- GitHub Actions 真实导出日志显示 `A valid Java SDK path is required in Editor Settings`，这是 APK 导出终止的直接原因。
- 同一日志显示 `libfontconfig.so.1` 缺失；它禁用系统字体支持并产生噪声，但 Godot 继续进入 Android 导出配置检查，因此不是本次终止点。
- `Could not find version of build tools ... using 33.0.2` 是回退提示；`cannot connect to daemon at tcp:5037` 是 ADB 噪声，两者都发生在 Java SDK 配置失败前后，不是主要终止原因。
- GitHub Actions 的容器 step 使用 Actions 指定的 `HOME`；仅从 `/root/.config/godot` 条件复制旧 EditorSettings 不能保证 Java/Android SDK 字段存在或匹配当前镜像。
- `godot-ci` 官方 Dockerfile 使用 `editor_settings-${GODOT_VERSION:0:3}.tres`；对 4.7 镜像实际文件名是 `editor_settings-4.7.tres`，而旧 workflow 错误查找 `editor_settings-4.tres` 并因条件判断静默跳过。
- 官方镜像固定 Java 为 `/usr/lib/jvm/java-17-openjdk-amd64`、Android SDK 为 `/usr/lib/android-sdk`、Build Tools/API 为 33.0.2/33，且 Dockerfile 未安装 `fontconfig`。

## 技术决策
| 决策 | 理由 |
|------|------|
| 用 typed GDScript 建立组件化节点 | Godot 原生、便于后续移动端迭代和 headless 检查 |
| 武器数值使用 Resource 数据 | 对应 ADR 中“武器定义属于装备而非警卫”的领域边界 |
| 输入通过玩家公开命令接口汇合 | 触控与键鼠调试不复制移动/射击逻辑 |
| 场景基础模型使用 PrimitiveMesh | 无外部资产也能构成稳定自动测试场景 |
| 射击用直接物理射线，瞄准线复用同一轨迹查询 | 确保视觉辅助与真实弹道一致 |
| 木墙使用独立 HealthComponent | 为后续滚筒、敌人与玩家复用耐久边界 |
| VisionSensor3D 同时服务玩家与警卫 | 实现 ADR-043 的对称视野，避免两套角度/距离算法漂移 |
| 视野扇形用运行时采样射线构建网格 | 能在平面玩法中直接被砖墙和木墙裁切，且易于 headless 验证 |
| 警卫可见性由玩家视野或攻击暴露共同决定 | 保留盲区隐藏，同时实现背后开火后的 2 秒反击窗口 |
| 视野网格仅是传感器的表现层 | headless 可禁用渲染而不削弱角度、距离和遮挡测试 |
| 声音通过场景级 SoundEventHub 发布 | 武器、脚步、破墙与 AI 解耦，未来可独立加入音频表现和墙体衰减 |
| 声音半径保存在发声对象的数据边界 | 武器声音属于 WeaponDefinition，符合装备拥有射击属性的领域规则 |
| 警卫调查只记录声源位置与优先级 | 不泄露玩家身份；高优先级刺激可替换低优先级调查，目视战斗始终优先 |
| 动态导航使用版本号而非逐警卫事件队列 | 墙体变化时只更新受影响格；警卫下一物理帧按版本惰性重算，满足 0.2 秒上限且便于合并连续破坏 |
| 障碍格由 BoxShape3D 的世界平面包围框生成 | 砖墙跨格边界时会阻塞两侧格，2 米木墙模块只阻塞自身格；后续旋转墙也能由四角投影覆盖 |
| 第一批只让 INVESTIGATE 与 SEARCH 使用格子路径 | 先验证明确目标点移动和动态开墙，COMBAT 掩体行为随后复用同一导航服务 |
| 现有墙体均可由物理层 2 射线判定遮挡 | 砖墙位于层 2，木墙层值 10 包含层 2；掩体验证可以复用 VisionSensor 的遮挡规则 |
| 掩体候选应取阻塞格背向玩家一侧的相邻开放格 | 从玩家胸口到候选警卫胸口的射线命中墙体即可证明该站位有效遮挡 |
| 掩体行为需要独立移动与驻留状态 | MOVE_TO_COVER 负责路径推进，IN_COVER 负责隐藏/探身周期，避免污染原 COMBAT 射击时序 |
| 掩体有效性不能只依赖当前物理射线 | 动态墙注销导航后会到帧末才真正释放物理体；射线需跳过已注销碰撞体，才能满足同逻辑帧失效 |
| 无掩体移动可直接按距离带生成速度 | 小于 8 米后退、大于 12 米接近、中间横移；仍由 CharacterBody3D 碰撞解析阻挡 |
| 石油/汽油滚筒触发完全由耐久和火焰决定 | 石油 4 耐久归零进入 4 秒燃烧；汽油 3 耐久归零或接触传播火焰立即爆炸，不使用随机概率 |
| 汽油爆炸使用 3 米半径线性衰减 | 中心 3 点、边缘 1 点；同一公式作用于玩家、警卫和可损坏模块且无击退 |
| 爆炸遮挡必须在应用伤害前确定 | 完整墙后的目标不受本次伤害，即使遮挡墙在同次爆炸中被摧毁也不重新穿透 |
| 火焰传播使用严格正交邻接 | 2 米中心距内立即传播至木墙、石油或汽油模块；斜角和间隙不传播，砖墙不参与 |
| 火区伤害不区分阵营 | 燃烧源每秒对区域内玩家和警卫造成 1 点伤害，离开后不保留灼烧状态 |
| 环境模块失效必须同步关闭四个表现层 | 注销导航格、清空碰撞层、禁用 CollisionShape3D、隐藏视觉根节点在同一调用中完成，避免不可见旧碰撞 |
| 爆炸和火焰复用统一环境目标分组 | 玩家与警卫进入无阵营受击组；木墙、石油和汽油模块进入爆炸目标与可燃模块组，后续火箭可直接复用 Hub |
| 木墙与两类滚筒共享环境模块基类 | 统一管理导航注册、活动状态、同步碰撞关闭和视觉移除，子类只负责耐久归零后的特有反应 |
| 玩家武器模型是永久手枪加一个特殊槽 | 特殊槽可在重型手枪、机枪和火箭枪间替换；替换物连同当前弹匣和备用弹药掉落 |
| 常规武器与火箭只在发射实现上分叉 | 手枪/重型手枪/机枪使用射线，火箭生成可见实体；全部共享武器定义、射程、弹药和声音边界 |
| 首轮特殊武器数值已冻结 | 重型手枪 2×6/18、机枪 1×24/48 与 0.1 秒间隔、火箭 1 发/3 备用与 2.2 秒换弹；射程均 16 米 |
| 火箭爆炸可直接复用环境反应 Hub | 4 米半径、中心 5 点、边缘 1 点、无阵营、墙体遮挡和确定性环境连锁已经由 Hub 实现 |
| 触控射击语义由当前武器定义决定 | 半自动每次按下只开一枪；机枪按住持续请求，武器本身强制射速与弹药限制 |
| 拾取交互分安全与破坏性两类 | 空槽/同类未满自动执行；不同类型只显示交换按钮，确认后才替换并掉落旧武器 |
| 火箭碰撞掩码必须覆盖角色与障碍三类物理层 | 玩家层 1、墙体层 2、警卫层 8；使用掩码 11 才能同时实现角色命中和环境碰撞 |
| 任务激活与撤离应由独立领域节点发出事件 | Area3D 只负责范围和状态，场景级任务控制器负责任务阶段、警卫警报、统计与结算，HUD 只订阅状态 |
| 任务警报只写入任务点位置 | 调用警卫公开警报入口进入调查；不保留玩家引用或持续更新坐标，避免全局透视 |
| 目标距离首轮使用近/中/远分级 | ADR-056 要求大致距离且数字/分级尚未冻结；分级不会泄露精确路线，移动端更易扫读 |
| 失败与胜利都由任务控制器终止计时 | 胜利结算展示用时、击杀、剩余生命和撤离完成；死亡立即失败，未冻结的重试流程留待随机种子切片 |
| 本局种子属于跨场景运行状态 | 场景重载会恢复墙体、资源、生命和任务状态；autoload 只保留种子即可让重试重建完全相同的开局 |
| 生成器必须在任务控制器之前完成实例化 | 任务控制器通过固定运行时名称绑定随机任务点，并在 `_ready` 时扫描全部预置警卫；场景树顺序保证无中途增援 |
| 候选点只存位置，内容定义由生成预算决定 | 共享武器候选点尚未冻结，首轮允许共用；生成器保证前三类各一件并用同一 RNG 均匀选择第四件 |
| 多警卫测试必须禁用整个 guards 分组 | 旧测试只停用单个演示警卫；随机生成 8–12 名后必须统一冻结后台 AI，避免无关攻击污染组件断言 |
| 急救包作为动态物品加入玩家视野可见性 | 满血不消耗、受伤自动恢复 2 格；表现层按玩家视野查询隐藏，碰撞拾取逻辑保持可用 |
| 瞄准吸附的首轮候选边界与玩家视野完全一致 | ADR-007 明确禁止穿墙和锁定盲区；距离上限继续使用统一 16 米视野/射程 |
| 多目标优先选择与原始瞄准射线夹角最小者 | 屏幕触控意图是方向；角度误差直接反映手指瞄准误差，并可用距离作同角度平局 |
| 盲区表现分为静态结构与动态情报两层 | ADR-009 要求墙体/地形保留暗化轮廓，而警卫、武器和动态威胁完全隐藏 |
| 盲区环境反馈只传递事件类型与大致方向 | ADR-075 禁止显示精确火区/爆炸位置，且间接闪光不得扩大动态单位显形边界 |
| CI 首轮产出 arm64 调试 APK | 中端 Android 主要是 arm64；调试签名能直接安装测试且不引入发布密钥管理 |
| Android 导出前在同一 CI job 运行语法检查和核心回归 | 只有通过玩法回归的提交才产出 APK，避免分发可启动但规则已损坏的构件 |
| Release 标签由 `workflow_dispatch` 输入并在 shell 中校验 | 允许明确版本发布，同时避免未经校验的输入进入版本修改命令；标签去掉可选 `v` 后写入 APK 版本名 |
| Release 首轮仍附加调试签名 APK | 延续当前真机测试用途，不引入仓库发布密钥；正式商店签名属于后续独立发布流程 |

## 遇到的问题
| 问题 | 解决方案 |
|------|---------|
| 用户说已添加 `.gitignore`，但文件不存在 | 本轮创建标准 Godot 忽略规则 |
| 新项目第一次直接运行 `--check-only` 时全局脚本类尚未缓存 | 先执行一次 headless 编辑器导入，再运行语法检查 |
| macOS 沙箱中 Godot 4.7 headless 启动主场景连续三次在日志目录/MoltenVK 路径崩溃 | 停止重复该命令；以 check-only、场景测试和后续 Android 真机验证覆盖，项目继续使用 Mobile |
| ImmediateMesh 即使在 headless 场景测试中也会触发 macOS 图形路径 | GameVisionCone3D 在 headless 下只禁用绘制；共享感知算法照常运行和测试 |
| 沙箱内 Godot 偶发在 `user://logs` / MoltenVK 路径 signal 11 | 使用已授权的非沙箱 headless 命令完成语法与回归验证；代码测试本身通过 |

## 资源
- `docs/design/GDD-MVP-v0.1.md`
- `docs/design/glossary.md`
- `docs/design/decisions/`
- `scripts/perception/vision_sensor_3d.gd`
- `scripts/perception/vision_cone_3d.gd`
- `scripts/actors/pistol_guard.gd`
- `scripts/ai/cover_service_3d.gd`
- `scripts/navigation/grid_navigation_3d.gd`
- `scripts/world/environment_reaction_hub.gd`
- `scripts/world/environment_module_3d.gd`
- `scripts/world/oil_barrel_wall.gd`
- `scripts/world/gasoline_barrel_wall.gd`
- `scripts/mission/mission_controller.gd`
- `scripts/world/objective_point_3d.gd`
- `scripts/world/extraction_point_3d.gd`
- `scripts/ui/objective_indicator.gd`
- `scripts/session/run_state.gd`
- `scripts/world/content_spawner_3d.gd`
- `scripts/world/health_pack_3d.gd`
- `scripts/input/aim_assist_3d.gd`
- `scripts/world/world_visibility_3d.gd`
- `export_presets.cfg`
- `.github/workflows/android-build.yml`

## 视觉/浏览器发现
- 本轮尚未进行视觉或浏览器检查。

---
*每执行2次查看/浏览器/搜索操作后更新此文件*
*防止视觉信息丢失*
