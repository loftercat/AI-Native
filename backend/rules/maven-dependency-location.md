# Maven 依赖定位 SOP

编码时 `import com.hema.common.*` 等依赖**找不到类 / 编译不过 / 不确定 jar 位置**时，按以下流程定位；**禁止**直接全盘文件系统检索 jar。

## 必守

1. **先跑第 1 级，失败再第 2 级**，按顺序降级
2. **命令输出重定向**：PowerShell 下 `mvn` 输出会被 CLIXML 包装吞掉，命令一律追加 `> <file>.log 2>&1`，再读取日志文件判断结果
3. **`-pl <module>` 指定模块**（如 `-pl booking-bff-admin`），避免全仓库构建
4. **不把「找不到 jar」当成阻断点**：两轮定位后仍不确定时，基于已有信息自行判断继续；不向用户发起固定阻断提问（环境可能不同、可能是其他系统，不标准化）

## 第 1 级：直接拿 jar 绝对路径（首选）

```powershell
mvn dependency:build-classpath -pl <module> -Dmdep.outputFile=cp.txt > mvn-cp.log 2>&1
```

- 生成 `cp.txt`，内含当前模块**全部依赖 jar 的绝对路径**（含私有 nexus 仓库下载的包）
- 直接可确认某个 `groupId:artifactId:version` 对应的 jar 是否在 classpath、落在哪个本地仓库目录

## 第 2 级：看仓库/镜像与最终 POM（仅第 1 级失败时）

```powershell
mvn help:effective-settings > mvn-settings.log 2>&1   # 仓库 / 镜像 / 私有 nexus 配置
mvn help:effective-pom > mvn-pom.log 2>&1             # 最终生效 POM（父 POM 合并后的依赖版本）
```

- `effective-settings`：确认本地仓库路径、是否配置私有 nexus 镜像、snapshot 策略
- `effective-pom`：确认依赖最终解析到的版本（`${hema-common.version}` 等属性实际值）

## 反模式

```powershell
# ❌ 全盘搜 jar
Get-ChildItem -Path C:\ -Recurse -Filter hema-common*.jar

# ❌ 直接 mvn 且不重定向（CLIXML 吞输出，看不到结果）
mvn dependency:build-classpath -pl booking-bff-admin

# ❌ 找不到就停下来问用户
```
