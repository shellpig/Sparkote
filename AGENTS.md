# Agent Instructions

# Sparkote

《Sparkote》是一款 2D 走格子探索 / 治癒系敘事遊戲：玩家在現實中完成自我照顧小任務，化為「Sparkote 能量」，推進郵差蕾拉（Layla）開著飛天郵務露營車、在群島霧海與平行世界間送信的旅程。核心信念：**不讓角色變強，而是讓世界變完整。**

- **類型**：2D 走格子探索 / 家園修復 / 碎片化敘事 / 治癒系
- **核心循環**：現實完成小任務 → 獲得能量 → 消耗能量翻開地圖未知格 → 開格獲得資源・物品・事件 → 回饋家園 / 推進劇情 →（每日回來推進）
- **變現**：免費遊玩，rewarded ad（看廣告解鎖額外任務）為核心變現；iOS rewarded ad spike 已通過，Godot + admob 選型拍板，`AdService` 介面已驗證。
- **目標平台**：iOS 先行（手上有測試機）+ Android（獨立第二次整合）；引擎 Godot 4.6.3 / GDScript。
- **工作流**：沿用前作 AfterTheModel 的生產級工作流與工具鏈（`GameState` 模式、Godot 4.6、agent-sprite-forge）。
- **目前進度**：設計討論已收斂（三份實作文件分工、系統分層、`GameState` / Content 模型、Phase 規劃定案）；**尚未開始實作**。Phase 1 = 純系統地基，全程用 fixture、零真內容。
  - Phase 進度（單一事實來源）見 `遊戲規格書.md > Phase 規劃`。

## New Conversation Opening Check

At conversation start, read in this layered order. Ignore `舊文件/`.

**Layer 1 — 必讀（建立全貌）：**
1. `AGENTS.md`（本檔）
2. `遊戲規格書.md`（全遊戲通用系統規格、核心循環、系統分層、`GameState` / Content 模型、Phase 規劃與驗收條件；場景專屬規格之後 link 到 `subdocs/`）
3. `ArtBible/`（美術方向參考圖：等角地圖、露營車內外、事件插圖；延到 Phase 4 整合，Phase 1~2 全用佔位）
4. `git log --oneline -10`（近期變更）

**Layer 2 — 實作 / 測試文件（自 Phase 1 起寫，Sparkote 無歷史包袱）：**
- `開發設計方針.md` — 實作細節、檔案結構、Autoload 職責 / 簽名、signal、資料契約（implementer-owned）
- `測試指南.md` — Godot 測試流程（GUT headless）、手動驗收清單（verifier-owned）
- `驗證後已知問題.md` — 待修清單與已接受的邊界決定（Phase 2-E 收尾時才建立，尚未存在）

**Layer 3 — 任務相關細節與實作參考：**

- `Sparkote_故事提案.md`（世界觀「群島霧海浮空郵差」、主角蕾拉、核心劇情驅動、第一/二封信開局）
- `廣告spike清單.md` — iOS rewarded ad spike 驗證清單（已通過，`AdService` 介面沿用即可）
- `subdocs/` — 場景 / 內容專屬規格（各地圖、事件劇情、角色、家園佈置細節），按主題分子資料夾；**只在該場景 / 內容 phase 開工時新增**，目前尚未建立
- `舊文件/Sparkote_設計文件.md` — 早期發想筆記，**僅供參考、非實作依據**
- agent-sprite-forge 工具（位置見「專案外部工具路徑」）
- Godot 專案 source code（建立後）

Report to user: current progress, and any issues with their scope of impact.

## Project Skills

This project uses local skills from `C:\_work\AI_Work\Skills\`.

Trigger rules:
- Diagnosing bugs / analyzing errors / finding root cause → read `Skills\engineering\diagnose\SKILL.md` first
- Requirements unclear / spec discussion / planning / need to ask clarifying questions → read `Skills\productivity\grill-me\SKILL.md` first
- Frontend / local web app verification, UI behavior debugging, browser screenshots, or console logs → read `Skills\engineering\webapp-testing\SKILL.md` first
- Normal state / no urgent or special situation → read `Skills\productivity\caveman\SKILL.md` first

Only modify files when user explicitly requests fix, implement, or commit. Verify/diagnose = report only.

## Generate 2D Asset Shorthand

When the user says `g2d 生 XXX 圖`, `g2d generate XXX image`, or any close shorthand:

- If `XXX` is a place, location, level, room, street, station, apartment, map, area, environment, or scene, use `$generate2dmap`.
- If `XXX` is not a place/location, use `$generate2dsprite`.
- Do not ask the user to choose between the two when the noun clearly implies one category.

Default output paths:

- Map/location outputs: `C:\_work\AI_Work\Projects\Sparkote\assets\generated\maps\<asset_name>\`
- Sprite/non-location outputs: `C:\_work\AI_Work\Projects\Sparkote\assets\generated\sprites\<asset_name>\<action_or_variant>\`

Keep generated raw images, processed transparent sheets, frame PNGs, GIF previews, prompts, and metadata inside the chosen asset folder unless the user explicitly requests a different path.

Image generation handling:

- Built-in `image_gen` may save new images under Codex's generated image cache first. After every generation, copy the actual PNG/image file back into the selected project output folder. Do not leave only the prompt text in the project folder.
- Use unique timestamp-style suffixes down to seconds for generated prompt and image filenames to avoid collisions, for example `main-character-concept-20260525-164029.png` and `main-character-concept-20260525-164029.prompt.txt`. Do not reuse generic names such as `prompt-used.txt` or `concept.png` when creating new generated assets.


## 文件

**已建立（專案根目錄）：**
- `Sparkote_故事提案.md` — 世界觀（群島霧海浮空郵差）、主角蕾拉、核心劇情驅動、第一/二封信開局提案
- `遊戲規格書.md` — 全遊戲通用系統規格與驗收條件、核心循環、系統分層、`GameState` / Content 資料模型、Phase 規劃（Phase 進度單一事實來源）
- `開發設計方針.md` — 實作層：檔案結構、Autoload 職責 / 簽名、signal、資料契約（implementer-owned，自 Phase 1 起寫）
- `測試指南.md` — 測試流程（GUT headless）與手動驗收清單（verifier-owned，自 Phase 1 起寫）
- `廣告spike清單.md` — iOS rewarded ad spike 驗收清單（已通過）
- `ArtBible/` — 美術方向參考圖（等角地圖、露營車內外、事件插圖）+ 各圖 prompt 說明
- `舊文件/Sparkote_設計文件.md`（含 `.html`）— 早期設計筆記（archive，僅供參考、非實作依據）

**規劃中：**
- `subdocs/` — 場景 / 內容專屬規格（地圖、事件劇情、角色、家園）；只在該 phase 開工時才寫，完成後 freeze 為歷史快照，不預建空殼。
- `驗證後已知問題.md` — 驗收問題追蹤與已接受的邊界決定。Phase 2-E 收尾時建立。
- `PROJECT_BRIEF.md` — 專案總覽與 Phase 進度表。規格書 + 設計方針合計 > 100 KB 時才建立；在那之前 `遊戲規格書.md > Phase 規劃` 為 Phase 進度單一事實來源。

## 專案外部工具路徑

外部工具不放進本專案 repo，避免汙染遊戲程式碼。

| 工具 | 路徑 | 用途 |
|---|---|---|
| agent-sprite-forge | `C:\_work\AI_Work\Tools\agent-sprite-forge` | AI 生成 2D sprite / map / prop |
| Godot 4.6.3 editor | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64.exe` | 引擎（GUI 版） |
| Godot 4.6.3 console | `C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe` | 引擎（CLI 版，用於 `--version` / headless export） |
| Godot export templates | `C:\Users\User\AppData\Roaming\Godot\export_templates\4.6.3.stable\` | ✅ 已安裝（Windows / Linux / macOS / iOS / Android / Web 全平台 templates 齊全） |
| Codex DeepSeek home | `C:\_work\AI_Work\Tools\codex-deepseek-home` | DS reviewer 環境 |

## Art Bible 規則

- 美術參考錨點放在 `ArtBible/`：等角地圖（Isometric）、露營車內外（Camper-van / home_base）、地圖事件插圖（Map Event Illustration），各圖附 `.txt` prompt 說明。
- 美術延到 Phase 4 才整合；Phase 1~2 全用佔位畫面，先把系統與內容做完測完，避免風格未定就量產素材導致漂移。
- 用 agent-sprite-forge 生成正式素材前，須先據 `ArtBible/` 收斂出穩定風格基準（色盤、線條、構圖紀律、治癒系氛圍），否則生成後風格漂移回不去。


## 驗證模式規則

當使用者要求「驗證」時，只能進行檢查、讀檔、執行測試、啟動本機服務與回報結果。

除非使用者明確要求「修」、「修改」、「commit」或「提交」，否則不得：

- 修改任何程式碼或文件
- 自行套 patch
- stage 檔案
- 建立 commit

若驗證中發現問題，只列出問題、影響範圍與建議修法，等待使用者下一步指示。

### Godot Headless 驗證

在目前 Windows / sandbox 環境中，Godot headless 直接在 sandbox 內執行會因無法開啟 `user://logs/godot*.log` 而 crash（signal 11）。

執行 Godot headless 驗證時，不要先跑 sandbox 版再讓它 crash；直接用 escalated 權限執行同一命令並回報這是已知 sandbox log 權限限制。

常用命令：

```powershell
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . res://tests/manual/test_runner.tscn
C:\_work\Godot_v4.6.3\Godot_v4.6.3-stable_win64_console.exe --headless --path . -s res://tests/manual/verify_game_state.gd
```

## 修改程式碼授權規則

除非使用者明確要求「修」、「修改」、「實作」、「處理某個 phase」、「commit」或「提交」，否則不得修改任何程式碼、文件或設定檔。

當使用者只是描述錯誤、貼截圖、詢問原因、要求解釋、要求列出問題、要求驗證，或詢問某功能怎麼使用時，只能分析與回報，不得自行套 patch。

## Python 執行環境規則

後續執行測試、匯入驗證、腳本執行時，預設固定使用專案虛擬環境：

- `.\.venv\Scripts\python.exe`

目標是讓 Agent 與使用者看到一致結果，避免誤用其他全域或內建 runtime Python。

## DeepSeek Codex CLI Reviewer

When the user says "要 ds4 pro 做 XXX", "要 ds4 flash 做 XXX", or similar wording, run the task through Codex CLI via the local Moon Bridge DeepSeek setup.

Model mapping:
- `ds4 pro` → `deepseek-v4-pro`
- `ds4 flash` → `deepseek-v4-flash`
- If the user says `ds4` without specifying `pro` or `flash`, use `deepseek-v4-pro`.

Default mode: read-only reviewer.
- Use `CODEX_HOME=C:\_work\AI_Work\Tools\codex-deepseek-home`.
- No file writes, deletes, staging, commits, or pushes.
- Do not read `.env`, `data/`, `舊文件/`, or `C:\_work\AI_Work\Tools\`.
- Treat output as second opinion; review it before reporting.
