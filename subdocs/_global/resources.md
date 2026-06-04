# 資源（_global/resources）

> 對應產出：`data/items.json`（kind=resource）+ 各圖 `resource_point` tile 產出。
> Schema 見 `開發設計方針.md §5.1`。逐日用量見 `subdocs/gate_d1_d7.md`。

## 標準資源（可重複採集，resource_point collect_rewards）

| id（提案） | 名稱 | 來源圖 | 量 | 主要用途 |
|---|---|---|---|---|
| `wood` | 木材 | 雨醒林（map_taichi_forest） | 標準 | 木槌修復（D1）、家園結構 / 爐灶（D4） |
| `stone` | 石材 | 眠石丘（map_taichi_stonehills） | 標準 | 車身爐灶修復（D4） |
| `thread` | 織線 | 霧鈴原（map_taichi_far） | 標準 | 室內軟件 / 掛飾（D7） |
| `crystal` | 晶石 | 微光晶谷（量多）/ 月影書庭（量少） | 第二世界特產 | 第二世界相關回饋（家園裝飾 / 後續鋪墊） |

## 特殊資源（一次性取得，**不可重複採集**）

> 使用者決策：這三項是「只有一個 / 數量有限的特殊道具」，**只能從 discovery 格或事件一次性取得**（或 resource_point 的 `first_rewards` 首採一次），**不得掛在 `collect_rewards`** 重複產出。
> 仍為 `kind=resource`（可被家園修復消耗），差別只在取得方式。

| id | 名稱 | 取得方式（一次性） | 主要用途 |
|---|---|---|---|
| `metal_fragment` | 金屬碎片 | 眠石丘 discovery 格（數個一次性） | 引擎 L2 修復、信箱修復 |
| `taichi_crystal` | 大千結晶 | 大千一次性 discovery / 事件（特產收藏） | 特產 / 後續收藏，目前不參與修復 |
| `second_spore` | 微光孢子 | 微光晶谷 discovery 格 + 首採（一次性） | 窗戶 L2 修復（發光窗） |

## 規則

- 大千三區一區一資源：雨醒林→木材、眠石丘→石材、霧鈴原→織線。
- 第二世界兩圖資源**統一為晶石（crystal）**，差在產量：微光晶谷量多（主採集）、月影書庭量少（點綴）。
- 標準資源的首採 / 重採成本與每日採集次數沿用 `config.json`（`resource_point_recollect_cost`=1、`resource_point_daily_limit` 暫留 1，2-C 跑 1 與 2 比較）。
- 特殊資源一次性取得；總供給量須 ≥ 家園修復需求（metal_fragment 需求 3、second_spore 需求 1，現有一次性來源已足）。

## 待實作者開工時補

- 各 `resource_point` tile 的 `first_rewards` / `collect_rewards` 具體數值（對齊 gate D1–D7 用量與家園需求）。
- 晶石「量多 / 量少」的具體產出差（例如 collect_rewards 數量級）。
