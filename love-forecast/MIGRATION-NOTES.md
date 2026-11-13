# 接入记录：锚点替换

日期：2026-11-13 ｜ 范围：`ai-workflow/{skills,rules,templates,reference,hooks,scripts}`

## 一、替换了什么

| 类别 | 原值 | 新值 | 处数 |
|------|------|------|------|
| 包名 | `com.hema.*` | `com.loveforecast.*` | 45 |
| 公共库 | `hema-common` | `love-common` | 37 |
| BFF 错误码类 | `BookingErrorCode` | `LoveErrorCode` | 18 |
| URL 前缀 | `/api/v1/booking/` | `/api/v1/love/` | 23 |
| 启动/BFF 模块 | `booking-app`、`booking-bff-app`、`booking-bff-admin` | `love-app` | 122 |
| 建议域 | `booking-order`、`booking-order-service`、`order-api/impl` | `love-advice`、`advice-api/impl` | 46 |
| 档案域 | `booking-inventory`、`booking-inventory-service`、`inventory-api/impl` | `love-profile`、`profile-api/impl` | 35 |
| 域错误码 | `OrderErrorCode` / `InventoryErrorCode` | `AdviceErrorCode` / `ProfileErrorCode` | — |
| 通配路径 | `booking-*-service/*-api/` | `love-{domain}/{domain}-api/` | 9 |

替换后 `booking-*` 与 `com.hema` 均为 0 残留（`booking-order-create` 是 Golden 文件名，保留）。

## 二、保留了什幺，为什么

| 保留内容 | 原因 |
|---------|------|
| `docs/**/_golden/` 下的停车业务样例（`DD-STORY-GOLDEN-001-booking-order-create.md` 等） | 教学样例，按 MIGRATION §一.3 应「用本项目业务重写」而非替换文件名 |
| Skill 正文里的业务示例：车位、车场、订单、支付、万象城 | 它们是理解流程的素材，且多处已标注「示例」。替换成恋爱业务会失真，成本也远高于收益 |
| `ParkingLotQueryService` 等代码示例 | 同上，属于「示例语境」 |
| 「模板版说明」中的 `booking-*` 元描述 | 它本身在描述模板机制，不是项目事实 |

**判断标准**：一条锚点是否会被当作**本项目事实**引用。会 → 替换；只是举例说明 → 保留。

## 三、踩过的坑

第一次用 `grep -rl | xargs perl -pi` 做全文替换，产生了 200+ 处语义矛盾：

- `love-app / love-app`（双 BFF 合并后重复）
- `love-advice/order-api`（模块名换了，子模块没换）
- `/api/v1/love/app/pay/callback`（前缀换了，业务路径没换）

**已回滚重做**。教训：

1. **先替换长的、具体的，再替换短的**（`booking-bff-app` 必须在 `booking-app` 之前）。
2. **模块名与子模块名要成对替换**（`booking-order` → `love-advice` 时，`order-api` 必须同时映射到 `advice-api`）。
3. **双 BFF / 双端语义无法机械合并**，必须手工重写那几句（约 10 处）。
4. Windows Git Bash 下 `grep -rl` 输出反斜杠路径，`perl -pi` 打不开文件——必须用 `find -exec` 直接传。

## 四、遗留项

| 项 | 状态 |
|----|------|
| Skill 正文的业务示例仍是停车业务 | 有意保留；不影响执行，但读起来是「另一个项目」 |
| `java-project.md` 里 `profile-impl` 的示例类名（`DeviceMonitorProperties`） | 示例，保留 |
| Golden 未用本项目业务重写 | 按 MIGRATION §一.3 属待办，不影响流程正确性 |

## 五、自查命令

```bash
cd ai-workflow
# 应无输出
grep -rn "com\.hema\|hema-common\|BookingErrorCode\|/api/v1/booking" skills/ rules/ reference/
# 应无输出（排除 Golden 文件名与模板说明）
grep -rn "booking-" skills/ rules/ reference/ | grep -v "模板版说明" | grep -v "booking-order-create"
# 应无重复
grep -rn "love-app.*love-app" skills/ rules/ | grep -v "启动" | grep -v "AbstractIntegrationTest"
```
