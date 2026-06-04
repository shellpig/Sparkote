# 資源（_global/resources）

> 對應產出：`data/items.json`（kind=resource）+ 各圖 `resource_point` tile 產出。
> Schema 見 `開發設計方針.md §5.1`。逐日用量見 `subdocs/gate_d1_d7.md`。

## 資源清單（本版 first pass）

| id（提案） | 名稱 | 來源圖 | 量 | 主要用途 |
|---|---|---|---|---|
| `wood` | 木材 | 雨醒林（woke_forest） | 標準 | 木槌修復（D1）、家園結構 / 爐灶（D4） |
| `stone` | 石材 | 眠石丘（stone_hill） | 標準 | 車身爐灶修復（D4） |
| `thread` | 織線 | 霧鈴原（bell_meadow） | 標準 | 室內軟件 / 掛飾（D7） |
| `lightcrystal` | 光晶 | 微光晶谷（量多）/ 月影書庭（量少） | 第二世界特產 | 第二世界相關回饋（家園裝飾 / 後續鋪墊） |

## 規則

- 大千三區一區一資源：雨醒林→木材、眠石丘→石材、霧鈴原→織線。
- 第二世界兩圖資源**統一為光晶**，差在產量：微光晶谷量多（主採集）、月影書庭量少（點綴）。
- 資源點首採 / 重採成本與每日採集次數沿用 `config.json`（`resource_point_recollect_cost`=1、`resource_point_daily_limit` 暫留 1，2-C 跑 1 與 2 比較）。

## 待實作者開工時補

- 各 `resource_point` tile 的 `first_rewards` / `collect_rewards` 具體數值（對齊 gate D1–D7 用量與家園需求）。
- 光晶「量多 / 量少」的具體產出差（例如 collect_rewards 數量級）。
