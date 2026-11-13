# 受影响测试范围分级规则（impact-scope-guide）

> bugfix Skill Step 6 使用。按"改动符号的可见性"判定，不按"文件位置"。
> 设计依据：DD-STORY-2026-S01-093（源项目 bugfix Skill 设计卡） §5、ADR-7

## 判定决策树

```text
改动的符号是什么？改的是签名还是方法体内部逻辑？
│
├─ 改方法体内部逻辑（非签名，契约没变）
│  ├─ private / package-private（仅本类内部）
│  │  → 跑该模块：mvn -pl <module>/<impl> -am test
│  └─ public 方法体内部（无论是否被跨模块调用，跨模块方通过 api mock 不受影响）
│     → 跑该 impl 模块：mvn -pl <module>/<impl> -am test
│
├─ 改方法签名 / 类签名（契约变）
│  ├─ public 方法/类，仅在本 *-impl 内被调用（Grep 确认）
│  │  → 跑该模块：mvn -pl <module>/<impl> -am test
│  └─ public 方法/类，被跨模块 @Autowired 调用（Grep 确认）
│     → 跑所有依赖该模块的模块：
│       mvn -pl <依赖模块1>,<依赖模块2> -am test
│
├─ *-api 接口 / DTO（签名/字段变）
│  → 跑所有依赖该 api 的模块：
│    mvn -pl <依赖模块1>,<依赖模块2> -am test
│
├─ love-common
│  → 跑全量：mvn test
│
├─ love-common
│  → 停下来，不归本仓库，交还人工
│
├─ MyBatis XML
│  → 跑该 Mapper 对应模块 + 额外跑该 Mapper 所有测试方法：
│    mvn -pl <module>/<impl> -am test -Dtest=<MapperTestClass>
│
└─ OpenAPI 文档（docs/api/）
   → 跑 tests/blackbox 下相关黑盒脚本：
     pytest tests/blackbox/ -k <相关用例>
```

## 边界判定示例

| 改动 | 表面位置 | 改的是签名还是方法体 | 跑哪些测试 |
|------|----------|-------------------|-----------|
| `ParkingLotQueryService` private 方法 | `profile-impl` | 方法体 | 仅 profile-impl |
| `ParkingLotQueryService.getLotDetail` 加回 null 守卫 | `profile-impl` | 方法体内部逻辑（签名没变） | 仅 profile-impl（BFF mock api 不受影响） |
| `ParkingLotQueryService.searchLots` 改方法签名（加参数） | `profile-impl` | 签名变 | profile-impl + 所有调用方（BFF） |
| `InventoryApi` 接口方法签名变 | `profile-api` | 签名变 | 所有依赖 profile-api 的模块 |
| `LoveErrorCode` 枚举项 | `love-common` | 平台横切 | 全量 mvn test |
| `ParkingLotMapper.xml` SQL | `profile-impl` | XML 反射调用 | profile-impl + 该 Mapper 所有测试 |

## 跑测试的硬约束

- 失败时修**代码**，不修**测试断言**（BR-11）
- 禁止 `@Disabled` 跳过失败测试（BR-11）
- 循环计数器 > 3 → 交还人工（AC-08）

## 如何确认跨模块调用

1. Grep 改动符号的类名/方法名，看是否在其它模块 `import` 或 `@Autowired`
2. 或用 `mvn dependency:tree` 看模块依赖关系
3. 不确定时按"跨模块"处理（跑更多测试，宁可多跑不可漏跑）
