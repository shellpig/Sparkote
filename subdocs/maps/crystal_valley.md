# 微光晶谷（crystal_valley）

> 對應產出：`data/maps/crystal_valley.json`。Schema 見 `開發設計方針.md §5.1`。
> 逐日定位見 `subdocs/gate_d1_d7.md`（D2–D3 第二封信真收件人）。

## 定案

| 欄位 | 值 |
|---|---|
| id | `crystal_valley`（提案） |
| name | 微光晶谷 |
| world | second_world（第二世界①） |
| region | crystal_valley |
| resource_bias | lightcrystal（光晶・**量多**，主採集區） |

## 敘事定位（D2–D3，第二封信）

- 第二世界第一張地圖，由大千的霧中發亮裂縫進入。
- 蕾拉在大千先找到暗掉的裂晶石（以為是收件者），追著微弱的光找到霧中裂縫，通往微光晶谷。
- **真正收件者**＝晶谷裡一整片「曾把光借給孩子們的晶石群」（信封地址只是線索）。
- 送達：信放進晶谷中央裂縫，一開始什麼都沒發生 → 最小一顆晶石亮起 → 光慢慢傳遍整片晶谷。不是原諒也不是修復，只是那句遲來的道歉終於被聽見。

## 含資源 / 事件

- 光晶資源點（`type=resource_point`，產出 lightcrystal，**量多**）。
- 晶石群送達事件（`type=event`）：放信 → 延遲 → 最小晶石先亮 → 全谷亮起。

## 待實作者開工時補

- tile graph、cost；第二世界穿梭入口（從大千裂縫）的接線。
- 第二封信道具與「暗裂晶石→真晶石群」的線索/requirements 串接。
