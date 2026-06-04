# 霧鈴原（map_taichi_far）

> 對應產出：`data/maps/map_taichi_far.json`。Schema 見 `開發設計方針.md §5.1`。
> 逐日定位見 `subdocs/gate_d1_d7.md`（D5 第三封信線索）。

## 定案

| 欄位 | 值 |
|---|---|
| id | `map_taichi_far` |
| name | 霧鈴原 |
| world | overworld（大千 正式區③） |
| region | meadows |
| resource_bias | thread（織線：霧氣凝成的絨毛植物） |

## 敘事定位（D5，第三封信線索）

- 第三封信「寄給橋那頭，那盞還亮著的燈」現身後，蕾拉循線來到霧鈴原。
- 含**被霧吞掉的斷橋**：橋板只剩半截，對岸房子空了、燈滅了 → 蕾拉以為又失敗（呼應她的傷口）。
- **風鈴草機關**：在有人「被記得」時會輕響，作為指向月影書庭（D6）的線索觸發。
- 採**織線**，供家園軟件修復（D7）。

## 含資源 / 事件

- 織線資源點（`type=resource_point`，產出 thread）。
- 斷橋事件（`type=event`）：發現空窗 → 風鈴草輕響 → 揭示燈主為老郵差、信留在月影書庭，串到 D6。
- 送達後（D7）斷橋重新接上一小段（世界恢復流動的可見回饋）。

## 待實作者開工時補

- tile graph、cost、斷橋格的阻擋 / 解除（是否用 requirements）。
- 風鈴草線索機關以何種事件 / flag 表示，串接月影書庭入口開啟。
