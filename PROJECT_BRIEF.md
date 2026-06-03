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
- **目前狀態**：Phase 1-A / 1-B / 1-C / 1-D 已完成並通過 headless GUT 驗證；1-D 已建立事件播放器、日記頁與心情筆記
- **下一步**：Phase 1-E 家園 + 資源點

最新 commit：

```text
46459eb Fix dead map fixture issue for unlocked maps and stage Godot UIDs
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

Godot 專案本體已建立。Phase 1-A 已建立以下架構骨架：

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
│   │   └── ui_navigation.gd
│   ├── systems/
│   │   ├── day_cycle.gd
│   │   ├── task_system.gd
│   │   ├── exploration.gd
│   │   ├── event_system.gd
│   │   ├── resource_point.gd
│   │   ├── home_system.gd
│   │   ├── store.gd
│   │   └── notification.gd
│   └── ui/
├── addons/gut/
├── scenes/main.tscn
├── data/
│   ├── config.json
│   ├── tasks.json
│   ├── items.json
│   ├── home.json
│   ├── maps/
│   └── events/
├── tests/
│   ├── fixtures/
│   └── unit/
├── ArtBible/
└── 舊文件/
```

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
|---|---|---|
| 1-A 架構地基 | 已完成（headless GUT 通過） | `GameState`、`Config`、`Content` fixture loader、`SaveService`、`AdService` stub、`EventSystem` seam、`UINavigation`、啟動 / debug 場景 |
| 1-B 任務 + 能量 | 已完成（headless GUT 通過；主場景啟動正常） | `TaskSystem`、`DayCycle`、任務頁、能量產出與提示 |
| 1-C 探索翻格 | 已完成（headless GUT 通過；地圖頁切換正常） | 相鄰 graph、霧、逐格成本、岔路、五種地點類型、資源點首採、多地圖切換 |
| 1-D 事件 + 日記 | 已完成（headless GUT 通過；支持重播與心情筆記） | 事件播放器、選項、獎勵 / 效果、日記頁、事件回看、心情筆記 |
| 1-E 家園 + 資源點 | 待開工 | 家園修復、插槽式佈置、資源點重採、集中採集頁 |
| 2 內容生產 + 測試 | 待規劃 | D1-D7 手感閘門；真任務池、真事件、真地圖、真家園定義；過閘門後量產第一版內容 |
| 3 變現整合 | 待規劃 | 真 `AdService`、遊戲商店、IAP、無廣告、每日免費領取、恢復購買 |
| 4 美術整合 + 正式 UI | 待規劃 | ArtBible 換掉佔位：等角地圖、露營車內外、事件插圖、UI skin、動態回饋 |
| 5 平台 / 存檔 / 通知 / iOS | 待規劃 | 本機存檔落地、通知、iOS export + ATT、觸控化 |
| 6 Endgame 雛形 + 平衡收尾 | 待規劃 | 隨機地圖模板、照顧型回饋、整體平衡、D1/D7 留存埋點 |

## Phase 1-A 速查

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

1-A 剩餘待定：

- 存檔檔名
- 存檔版本欄位格式

## 測試速查

Godot headless 在目前 Windows / sandbox 環境中，直接 sandbox 執行可能因無法開 `user://logs/godot*.log` 而 crash。驗證時直接用 elevated 權限跑：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gexit
```

單一測試檔：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless -s addons/gut/gut_cmdln.gd -gtest=res://tests/unit/test_game_state.gd -gexit
```

預定測試檔：

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

| 文件 | 何時讀 |
|---|---|
| `AGENTS.md` | 新 session 開場；專案規則、修改授權、驗證 / commit 規則、外部工具 |
| `PROJECT_BRIEF.md` | 快速建立全貌；先讀本檔，再按需求深入 |
| `遊戲規格書.md` | 全遊戲通用系統、核心循環、`GameState` 欄位、Phase 規劃與驗收意圖 |
| `開發設計方針.md` | Godot 檔案結構、autoload 職責、API / signal、Content schema、Phase 1 接線契約 |
| `測試指南.md` | GUT headless 命令、自動化測試項目、手動驗收清單 |
| `主角與故事提案.md` | 世界觀、主角蕾拉、信件敘事、第一 / 第二封信提案 |
| `廣告spike清單.md` | iOS rewarded ad spike 驗證結果與接入背景 |
| `ArtBible/` | 等角地圖、露營車內外、事件插圖等美術方向參考 |
| `舊文件/` | 歷史 archive，除非使用者明確要求，開工時忽略 |

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

- Godot 專案本體已建立；Phase 1-A / 1-B 已提交。
- `subdocs/` 尚未建立；等內容 / 場景 phase 開工再新增。
- `驗證後已知問題.md` 尚未建立。
- `ArtBible/` 已有參考圖，但 Phase 4 前不整合正式美術。
- iOS rewarded ad spike 已通過，但真 plugin 接入在 Phase 3。
- Android 是獨立第二次整合，不是 iOS 同步目標。
- 資源點每日採集 1 次或 2 次尚待 Phase 2 手感閘門決定。
- 超級任務次數保留上限、家園資源包、外觀 / 家具比例、第二世界正式名稱等仍待決策。

## 下一步建議

短線最合理下一步：**Phase 1-E 家園 + 資源點**。

開工前先讀：

- `遊戲規格書.md > §11~§13`
- `遊戲規格書.md > §20 Phase 1`
- `開發設計方針.md > §7.4`
- `測試指南.md > §4.5`

Phase 1-D 已驗證：

```text
EventSystem.play 載入並引導播放內容頁
-> resolve 結算選擇，發放獎勵，套用 effects
-> 支援對話分支，不同選項有各自獨立的獎勵與日記日誌
-> replay 重播模式加載歷史選擇並防止重複發獎
-> 日記頁面支持逐日審閱、統計與已解鎖事件重播
-> 心情筆記當今日任務全部做完時彈窗提示，可補寫與儲存
-> GUT headless 測試全綠
```
