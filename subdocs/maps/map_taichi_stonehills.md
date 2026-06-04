# 眠石丘（map_taichi_stonehills）

> 對應產出：`data/maps/map_taichi_stonehills.json`。Schema 見 `開發設計方針.md §5.1`。
> 逐日定位見 `subdocs/gate_d1_d7.md`（D4 開拓 + 家園第一次修復）。

## 定案

| 欄位 | 值 |
|---|---|
| id | `map_taichi_stonehills` |
| name | 眠石丘 |
| world | overworld（大千 正式區②） |
| region | stonehills |
| resource_bias | stone（石材） |

## 敘事定位（D4）

- 露營車引擎仍弱、需石材修車身，蕾拉開拓眠石丘。
- 首採石材，回家園做**第一次修復**：修好車身爐灶 → 爐火亮起（家園可見成長，見 `subdocs/_global/home.md`）。
- 沉睡的石、寂靜療癒的氛圍，與霧鈴原同一柔調。

## 含資源 / 事件

- 石材資源點（`type=resource_point`，產出 stone）。
- 事件可選配（本版以採集 + 家園回饋為主，不強制安排主線信件）。

## 待實作者開工時補

- tile graph 佈局、cost、是否安排支線小事件。
- 與家園爐灶修復項的資源需求對齊（木材 + 石材，見 home subdoc）。
