# Sparkote 專案簡報

本文件供新 session 快速了解專案全貌，減少每次重讀全部規格文件的成本。需要深入細節時，按下方文件索引讀對應規格。

最後更新：2026-06-03

---

## 專案概述

《Sparkote》是一款 2D 走格子探索 / 家園修復 / 治癒系敘事遊戲。玩家在現實中完成自我照顧小任務，獲得 Sparkote 能量，推進郵差蕾拉（Layla）開著飛天郵務露營車，在群島霧海與平行世界間送信的旅程。

核心信念：**不讓角色變強，而是讓世界變完整。**

- **引擎**：Godot 4.6.3 / GDScript
- **類型**：2D 走格子探索 / 家園修復 / 碎片化敘事 / 治癒系
- **核心體驗**：現實完成小任務 → 獲得能量 → 翻開未知地圖格 → 取得資源 / 事件 / 物品 → 回饋家園與劇情
- **目標平台**：iOS 先行，Android 第二次整合
- **變現策略**：免費遊玩，rewarded ad、一次性無廣告、外觀裝飾、家園資源包；不直接賣能量 / 任務完成 / 主線探索進度
- **目前狀態**：Phase 1-A / 1-B / 1-C / 1-D / 1-E 已完成並通過 headless GUT 驗證；Phase 1 全部子階段完成
- **下一步**：Phase 2-A 地基（能量參數表、跳日鈕、headless 經濟曲線模擬）

最新 commit：

```text
24368fb Update PROJECT_BRIEF.md: Phase 1-E complete, next step Phase 2-A
```

## 核心調性

玩家不是扮演英雄拯救世界，而是透過每天完成一些現實中的小任務，讓故事中的世界慢慢恢復流動。遊戲不追求角色戰力成長，回饋來自未知世界被打開、家園被修好、送出的信抵達真正該抵達的地方，以及玩家做過的事被日記留下。

故事主軸是「群島霧海的浮空郵差」：

```text
蕾拉收到信件
-> 根據收件者與線索探索浮空島 / 平行世界
-> 消耗 Sparkote 能量翻開未知格
-> 收集資源、信件、事件線索
-> 理解真正的收件者
-> 送達後讓世界恢復一點具體流動
```

第一章開局提案是「寄給雨聲的無字信」：蕾拉從靜止濃霧中的露營車醒來，找到一封寄給「一場在星期二下午落下的雨」的信，透過探索、修復與送達，讓雨重新落下並打開第一段森林與第二世界的伏筆。

## 技術棧

- **Engine**：Godot 4.6.3 stable
- **Language**：GDScript
- **Test framework**：GUT（Godot Unit Test），headless 執行
- **Primary architecture**：Autoload `GameState` 作為狀態脊椎；邏輯系統 autoload 單例、無狀態服務
- **Content pipeline**：JSON data + fixture，同 schema；Phase 1 只用 fixture，Phase 2 才灌真內容
- **Ads**：`AdService` 抽象層；Phase 1 stub，Phase 3 換真 poing-godot-admob
- **Asset direction**：ArtBible 已備，Phase 4 才整合正式美術

外部工具路徑：

| 工具 | 路徑 |
|---|---|
| Godot editor | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64.exe` |
| Godot console | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe` |
| Godot export templates | `C:\Users\User\AppData\Roaming\Godot\export_templates\4.6.3.stable\` |
| agent-sprite-forge | `C:\_work\AI_Work\Tools\agent-sprite-forge` |
| Codex DeepSeek home | `C:\_work\AI_Work\Tools\codex-deepseek-home` |

## 目錄結構

Godot 專案本體已建立。Phase 1（1-A~1-E）完成後的實際結構：

```text
.
├── project.godot
├── scripts/
│   ├── autoload/
│   │   ├── game_state.gd
│   │   ├── config.gd
│   │   ├── content.gd
│   │   ├── save_service.gd
│   │   ├── ad_service.gd
│   │   ├── ui_navigation.gd
│   │   ├── day_cycle.gd        # 1-B
│   │   └── task_system.gd      # 1-B
│   ├── systems/
│   │   ├── exploration.gd      # 1-C
│   │   ├── event_system.gd     # 1-D
│   │   ├── home_system.gd      # 1-E
│   │   └── resource_point.gd   # 1-E
│   └── ui/
│       ├── main.gd
│       ├── task_page.gd        # 1-B
│       ├── map_page.gd         # 1-C
│       ├── diary_page.gd       # 1-D
│       ├── event_player.gd     # 1-D
│       ├── home_page.gd        # 1-E
│       └── collect_panel.gd    # 1-E
├── addons/gut/
├── scenes/
│   ├── main.tscn
│   └── ui/                     # task/map/diary/event_player/home_page.tscn
├── data/
│   └── config.json             # 真內容 Phase 2 才灌；Phase 1 用 fixture
├── tests/
│   ├── fixtures/               # config/tasks/items/home.json + maps/ + events/ + bad/
│   └── unit/                   # 12 個 test_*.gd（含 phase1 smoke）
├── ArtBible/
└── 舊文件/
```

> Store / Notification 系統與 `data/` 真內容（tasks/items/home/maps/events）目前**尚未存在**：前者排 Phase 3/5，後者 Phase 2 才產；Phase 1 的對應內容全在 `tests/fixtures/`。

`舊文件/` 是歷史 archive，開工時忽略。

## 核心系統

### GameState

全域玩家狀態單一事實來源，負責原子變更、查詢與 requirements 判定。存檔內容就是 `GameState.to_dict()`。

管理範圍：

- 遊戲日 / 週進度 / 超級任務次數
- 能量與上限
- 資源、任務道具、家具、外觀、收藏
- 已解鎖地圖、已翻開格、資源點採集記錄
- 旗標、已完成事件與事件選項
- 家園修復狀態與插槽擺放
- 當日任務候選 / 選擇 / 完成狀態
- 常用任務
- 日記與心情筆記
- 購買權益與每日領取旗標

邊界：

- `GameState` 不負責 UI、事件播放、廣告 SDK、流程編排。
- 需要讀 Content / Config 的判定放在邏輯系統，例如 `Exploration`、`HomeSystem`、`ResourcePoint`。
- 所有狀態變更都經 `GameState` API；邏輯系統不可直接改欄位。

### Config

全域設定 autoload，預設讀 `data/config.json`；測試可指定 `tests/fixtures/config.json`。

集中管理：

- 任務能量：普通 1 / 高級 2 / 超級 3
- 能量上限與提示門檻
- 每日任務槽位 / 候選數
- 資源點重採成本與每日採集次數
- 週超級任務門檻

### Content

內容載入與查詢 autoload。Phase 1 fixture 與 Phase 2 真內容沿用同一份 JSON schema。

載入範圍：

- 任務池
- 地圖與格子 graph
- 事件
- 物品 / 資源 metadata
- 家園插槽與修復項

loader 必須對壞資料明確報錯、不靜默、不崩。最小 schema 見 `開發設計方針.md > 5.1 Phase 1 最小 Content JSON schema`。

### 主要邏輯系統

| 系統 | 職責 |
|---|---|
| `DayCycle` | 推進遊戲日、重置每日旗標、週檢查、重骰任務 |
| `TaskSystem` | 任務候選、選擇、完成、自我申報、額外高級任務、超級任務 |
| `Exploration` | 翻格、相鄰 graph、requirements / 能量判定、五種地點結算、多地圖切換 |
| `EventSystem` | 事件 overlay、pages / choices、rewards / effects、事件日記、回看 |
| `HomeSystem` | 家園修復、家具插槽放置 / 收納 |
| `ResourcePoint` | 已開資源點重採、集中採集頁資料 |
| `SaveService` | 本機存檔 round-trip |
| `AdService` | rewarded ad 抽象層；Phase 1 stub 含 debug fail mode |
| `UINavigation` | 根頁互斥、overlay stack、caller 還原 |

## Phase 進度

| Phase | 狀態 | 概要 |
|:---|:---|:---|
| 1-A 架構地基 | ✅ 完成 | `GameState`、`Config`、`Content` fixture loader、`SaveService`、`AdService` stub、`EventSystem` seam、`UINavigation`、啟動 / debug 場景；headless GUT 通過 |
| 1-B 任務 + 能量 | ✅ 完成 | `TaskSystem`、`DayCycle`、任務頁、能量產出與提示；主場景啟動正常 |
| 1-C 探索翻格 | ✅ 完成 | 相鄰 graph、霧、逐格成本、岔路、五種地點類型、資源點首採、多地圖切換；地圖頁切換正常 |
| 1-D 事件 + 日記 | ✅ 完成 | 事件播放器、選項、獎勵 / 效果、日記頁、事件回看、心情筆記；支持重播 |
| 1-E 家園 + 資源點 | ✅ 完成 | HomeSystem 修復/插槽、ResourcePoint 重採/集中採集、佔位家園頁；**Phase 1 headless GUT 79/79 全綠** |
| 2-A 地基 | 📋 規格定案・待開工 | 能量參數表（對齊 config.json）、跳日鈕、headless 純經濟曲線模擬（不走 UI）、D1–D7 閘門腳本骨架 |
| 2-B 內容 | 📋 規格定案・待開工 | 3–4 大千圖 + 1–2 第二世界圖、真任務池、真事件鏈（含新手贈點 D1–D7 緩降）、真家園 / 資源點定義 |
| 2-C 手感閘門 (de-risk) | 📋 規格定案・待開工 | 硬指標（sim：Day6 可翻 ≥ 4、無 cap 失控）+ 軟手感四條清單，**雙過才准量產** |
| 2-D 量產 | 📋 規格定案・待開工 | ~20 圖、大千 3 區 + 第二世界 2 區、主線 + 部分支線、出口鏈 / 阻擋 / 穿梭、家園完整修復 / 佈置、圖紙、背包分類 |
| 3 變現整合 | ⬜ 待規劃 | 真 `AdService`、遊戲商店、IAP、無廣告、每日免費領取、恢復購買 |
| 4 美術整合 + 正式 UI | ⬜ 待規劃 | ArtBible 換掉佔位：等角地圖、露營車內外、事件插圖、UI skin、動態回饋 |
| 5 平台 / 存檔 / 通知 / iOS | ⬜ 待規劃 | 本機存檔落地、通知、iOS export + ATT、觸控化 |
| 6 Endgame 雛形 + 平衡收尾 | ⬜ 待規劃 | 隨機地圖模板、照顧型回饋、整體平衡、D1/D7 留存埋點 |

> **Phase 2 核心 = 能量 → 資源 → 家園成長迴圈**；規格散落三處：範圍 / 判準見 `遊戲規格書.md §20`、實作契約見 `開發設計方針.md §8`、驗收清單見 `測試指南.md §6`。

## Phase 1-A 速查（歷史，已完成）

Phase 1-A 目標：所有架構件以「可被呼叫的契約 + 最小真實行為」立起來，headless 全綠，後續 1-B~1-E 有 seam 可接。此階段不含真內容、不含正式面板。

建議實作順序：

```text
1. 建 Godot project + GUT + 目錄骨架
2. Config + fixture config
3. GameState 初始狀態 / 原子 API / signals
4. Content fixture loader + schema validation
5. requirements 查詢
6. SaveService round-trip
7. AdService stub + debug fail mode
8. UINavigation 狀態機
9. EventSystem seam
10. main.tscn / debug entry
11. test_*.gd 覆蓋 1-A 清單
```

1-A 待定項（已解決）：

- 存檔檔名：`user://savegame.json`
- 存檔版本欄位：`version: 1`（`load_from_file` 對 version ≠ 1 或格式異常報錯）

## 測試速查

Godot headless 在目前 Windows / sandbox 環境中，直接 sandbox 執行可能因無法開 `user://logs/godot*.log` 而 crash。驗證時直接用 elevated 權限跑：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

單一測試檔：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_game_state.gd -gexit
```

測試檔（皆已存在，headless 79/79 全綠）：

| 測試檔 | 涵蓋 |
|---|---|
| `test_game_state.gd` | GameState 原子操作 + 序列化 round-trip |
| `test_config.gd` | Config 讀取 |
| `test_content.gd` | Content 載入 fixture + 查詢 + 壞資料報錯 |
| `test_requirements.gd` | requirements 判定 |
| `test_save.gd` | SaveService 存讀 |
| `test_ad_stub.gd` | AdService stub 成功 / 失敗 |
| `test_ui_navigation.gd` | UINavigation 根頁互斥 + overlay 還原 |
| `test_task_system.gd` | 1-B TaskSystem + DayCycle + 能量 |
| `test_exploration.gd` | 1-C 翻格 + requirements 阻擋 |
| `test_event_diary.gd` | 1-D 事件播放 + 日記資料 |
| `test_home_resource.gd` | 1-E 修復 + 資源點 |
| `test_phase1_smoke.gd` | Phase 1 端到端煙霧 |

`git diff --check` 若只出現 LF -> CRLF warning，屬 Windows autocrlf 提示，不是 whitespace error。

## 規格文件索引

> 深入細節時按行範圍只讀對應段，不必整份重讀。行號會隨改動漂移，對不上時以標題為準。

**頂層（先讀）**

| 文件 | 何時讀 |
|:---|:---|
| `AGENTS.md` | 新 session 開場；專案規則、修改授權、驗證 / commit 規則、外部工具 |
| `PROJECT_BRIEF.md` | 本檔；先讀建立全貌，再按下方行號索引深入 |

### 遊戲規格書.md（~467 行）

全遊戲通用系統規格與驗收意圖；單一事實來源。

| 區段 | 行範圍 | 何時讀 |
|:---|:---|:---|
| 指導原則 / 目前狀態 | 12-30 | 了解薄原型定調與當前進度 |
| 核心循環 / 系統分層 | 31-60 | 建立整體心智模型 |
| GameState（狀態脊椎） | 61-103 | 改狀態欄位 / 存檔內容時 |
| 全域設定（能量參數） | 104-124 | 調能量 / 槽位 / 資源點數值時 |
| 任務系統 / 能量 | 125-164 | 改 TaskSystem / 能量規則時 |
| 探索翻格 / 地點 + Requirements | 165-212 | 改 Exploration / 五種地點 / 阻擋時 |
| 事件系統 | 213-231 | 改 EventSystem / 事件資料時 |
| 資源 + 資源點 / 家園 / 背包 / 日記 | 232-306 | 改資源 / HomeSystem / 背包 view / 日記時 |
| Content 資料模型 | 307-331 | 設計地圖 / 事件 / 物品 JSON 時 |
| UINavigation / AdService / SaveService | 332-381 | 改導航 / 廣告介面 / 存檔時 |
| 變現系統（架構） | 382-400 | Phase 3 變現前 |
| **§20 Phase 規劃（Phase 2 子階段 + 能量數學 + 閘門判準）** | **401-451** | **規劃任一 phase；Phase 2 開工前必讀** |
| §21 待決策 | 452-467 | 查未定數值（2-C 實機 / 開工時補） |

### 開發設計方針.md（~384 行）

implementer-owned：檔案結構、autoload 職責、API / signal、資料契約、各階段接線。

| 區段 | 行範圍 | 何時讀 |
|:---|:---|:---|
| 範圍與邊界 / 起始範圍 | 13-32 | 第一次實作前 |
| 專案檔案結構 | 33-80 | 找檔案放哪 / 新增檔時 |
| Autoload 一覽 | 81-95 | 查 autoload 職責 |
| 資料契約共識（含 §5.1 最小 Content JSON schema） | 96-129 | 寫 / 改任何 data 或 fixture JSON 時必讀 |
| §6 1-A 架構地基契約 | 130-218 | 改 GameState / Config / Content / Save / Ad / UINav 時 |
| §7 1-B~1-E 實作契約 | 219-318 | 改 TaskSystem / Exploration / Event / Home / ResourcePoint 時 |
| **§8 Phase 2 實作契約（subdocs→data、dev 工具、headless 經濟模擬、能量參數、新手贈點）** | **319-373** | **Phase 2 任一子階段開工前必讀** |
| §9 Headless 驗證命令 | 374-384 | 跑 headless 時 |

### 測試指南.md（~246 行）

verifier-owned：headless 命令、自動化項目、手動驗收清單。

| 區段 | 行範圍 | 何時讀 |
|:---|:---|:---|
| 範圍 / 測試環境（headless 命令 + fixture 約定） | 10-65 | 跑測試前 |
| 測試分層（自動 vs 手動） | 66-76 | 規劃測試擺哪時 |
| §4 Phase 1 測試（4.1 1-A ~ 4.5 1-E） | 77-194 | 驗 Phase 1 各子階段 |
| §5 Phase 1 整合煙霧 | 195-208 | 端到端回歸 |
| **§6 Phase 2 測試（6.1 2-A 工具 / 6.2 2-C 硬+軟閘門 / 6.3 2-B·2-D 內容）** | **209-243** | **驗 Phase 2 時必讀** |
| §7 更後續 Phase | 244-246 | Phase 3+ 規劃時 |

### 其他文件（敘事 / 背景，無需行號索引）

| 文件 | 何時讀 |
|:---|:---|
| `主角與故事提案.md`（~80 行） | 世界觀、蕾拉、第一 / 二封信開局；寫事件劇情 / `gate_d1_d7` 前 |
| `廣告spike清單.md`（~79 行） | iOS rewarded ad spike 驗證背景；Phase 3 接真 plugin 前 |
| `ArtBible/` | 等角地圖、露營車內外、事件插圖美術方向；Phase 4 前不整合 |
| `subdocs/`（尚未建立） | 場景 / 內容專屬規格；對應內容 phase 開工才建 |
| `舊文件/` | 歷史 archive，除非明確要求，忽略 |

## 實作注意事項

- 使用者明確說「修 / 修改 / 實作 / 處理 phase / commit / push」才可改檔。
- 使用者說「驗證」時只能檢查、讀檔、跑測試、回報；不可 patch / stage / commit。
- `開發設計方針.md` 偏 implementer-owned；`測試指南.md` 偏 verifier-owned。角色不符時只列建議。
- `.idea/` 是 IDE 本機設定，通常不 commit。
- `舊文件/` 是歷史 archive，忽略。
- Phase 1~2 全用佔位表現層；不要提前導入正式美術。
- `data/` 放真內容；`tests/fixtures/` 放 fixture，兩者不要混。
- 不要直接賣能量、任務完成或主線探索進度。

## 目前已知邊界

- Godot 專案本體已建立；Phase 1（1-A~1-E）全部已提交，headless GUT 79/79 全綠。
- `subdocs/` 尚未建立；等內容 / 場景 phase 開工再新增。
- `驗證後已知問題.md` 尚未建立。
- `ArtBible/` 已有參考圖，但 Phase 4 前不整合正式美術。
- iOS rewarded ad spike 已通過，但真 plugin 接入在 Phase 3。
- Android 是獨立第二次整合，不是 iOS 同步目標。
- 資源點每日採集 1 次或 2 次尚待 Phase 2 手感閘門決定。
- 超級任務次數保留上限、家園資源包、外觀 / 家具比例、第二世界正式名稱等仍待決策。

## 下一步建議

短線最合理下一步：**Phase 2-A 地基**。

開工前先讀：

- `遊戲規格書.md > §20 Phase 2`（範圍 / 子階段 / 閘門判準 / 能量數學）
- `開發設計方針.md > §8 Phase 2`（subdocs→data 對應、dev 工具接線、headless 經濟模擬）
- `測試指南.md > §6 Phase 2`（2-A 工具、2-C 硬+軟閘門清單、內容驗收）

Phase 1-E 已驗證：

```text
HomeSystem.repair 消耗資源推進修復等級並記日記
-> place_furniture/remove_furniture 插槽類型驗證、完全不改能量/探索
-> ResourcePoint.collect 扣能量、發產出、標記計數；次數用完拒採
-> get_collectable_points 跨地圖掃描已開資源點今日狀態
-> 佔位家園頁 + 集中採集子面板
-> GUT headless 79/79 全綠（含 Phase 1 端到端煙霧測試）
```
