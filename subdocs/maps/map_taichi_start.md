# 靜止霧區（map_taichi_start）

> 對應產出：`data/maps/map_taichi_start.json`。Schema 沿用 `開發設計方針.md §5.1` / fixture `tests/fixtures/maps/map_1.json`。
> 逐日定位見 `subdocs/gate_d1_d7.md`（D1 開局）。

## 定案

| 欄位 | 值 |
|---|---|
| id | `map_taichi_start` |
| name | 靜止霧區 |
| world | overworld（大千） |
| region | start |
| resource_bias | 無（教學區，不主打採集） |

## 結構（已定案）

- **單線 3 格**：起點 → 中段 → 出口，共 3 格（含起點與出口）。
- 起點＝蕾拉醒來的靜止濃霧灰格（露營車停駐、引擎無法啟動）。
- 出口 tile：`type=exit`，`target_maps=["map_taichi_forest"]`，通往雨醒林。
- 中段格作為最小教學步（移動 / 翻格示範）。

## 敘事定位

D1 開局教學：玩家用第一筆 Sparkote 能量在此前進，引出車外郵筒中的第一封信（寄給「一場在星期二下午落下的雨」）。劇情詳見 `主角與故事提案.md`。

## 待實作者開工時補

- 三格 tile 的 `position` 座標、`cost`（建議起點 0、其餘低成本）。
- 第一封信作為任務道具（requirements）的取得點掛在哪一格 / 哪個事件。
