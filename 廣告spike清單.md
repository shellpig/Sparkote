# Sparkote｜iOS Rewarded Ad Spike 驗證清單 v0.1

> 目標單一:在一個**沒有遊戲本體**的空 Godot 專案裡,於 iPhone 真機跑通
> 「載入 → 播放 → 發獎勵」的 rewarded **test ad**,並驗證失敗時不卡死。
> 過了這關,Godot 選型才算拍板,才開始蓋 Sparkote 本體。

**背景決策**
- 引擎:Godot 4(沿用 AfterTheModel 的生產級工作流,4.6)
- 變現:rewarded ad 是唯一變現,且綁在「看廣告解鎖額外任務」核心機制 → 視為第一個要攻克的技術風險
- 平台:iOS 先測(手上有 iPhone),Android 之後上(廣告為兩套獨立原生整合,iOS 過 ≠ Android 過)

---

## Spike 目標(驗收總綱)
在 iPhone 真機:按一顆按鈕 → 看到帶 **「Test Ad」** 字樣的 rewarded 影片 → 看完觸發發獎勵 callback → 畫面點數 +1;且「廣告沒載入成功」時按鈕給明確回饋而非無反應。

---

## 階段 0:前置帳號與環境
- [ ] 註冊 **AdMob 帳號**(免費) → verify:能登入 AdMob 後台
- [ ] 後台手動新增一個 iOS App(選「尚未上架 / Not listed」) → verify:拿到真實 App ID(本 spike 先不用,只確認流程通)
- [ ] 確認 Mac + Xcode 可用、Apple 開發者帳號能簽名到自己的 iPhone → verify:Xcode 能把任意空白 app 跑上 iPhone
- [ ] 確認 Godot 版本(沿用 4.6?) → verify:`godot --version` 一致

## 階段 1:建立隔離的 spike 專案
- [ ] 開全新空 Godot 專案 `Sparkote_AdSpike`(不污染 Sparkote 本體) → verify:能跑起空場景
- [ ] 一個場景:一顆「看廣告」Button + 一個「點數:N」Label → verify:按鈕點了會印 log

## 階段 2:安裝 godot-admob-plugin
- [ ] 下載對應 **Godot 4.x**(對齊 4.6)的 godot-admob-plugin → verify:`addons/` 出現 plugin、可在專案設定啟用
- [ ] 安裝 plugin 要求的 iOS export 相關檔案 → verify:Export 視窗 iOS preset 不報缺檔
- [ ] 讀該 plugin 版本 README,記下**測試模式旗標名稱**(`is_real` / test device 等,版本而定) → verify:能說出這版怎麼切測試模式

## 階段 3:iOS 設定(最容易出錯)
- [ ] iOS export preset 的 `GADApplicationIdentifier` 填 **iOS App ID 測試值** `ca-app-pub-3940256099942544~1458002511` → verify:Info.plist 產出有此 key
- [ ] 處理 **ATT(App Tracking Transparency)**:加入 `NSUserTrackingUsageDescription` 字串,並在請求廣告前觸發 ATT 授權彈窗 → verify:首次啟動跳出系統追蹤詢問
- [ ] 確認 plugin 需要的 iOS 框架 / CocoaPods 依賴都進了 export → verify:Xcode 能 build 不缺 symbol

## 階段 4:AdService 抽象層(架構決策,現在就立)
- [ ] 建一個 `AdService` autoload(仿 AfterTheModel 的 `GameState` 模式),對外只暴露:
  - `request_rewarded()`
  - signal `rewarded_succeeded`(發獎勵)
  - signal `rewarded_failed(reason)`(載入/播放失敗)
  - → verify:按鈕只呼叫 `AdService.request_rewarded()`,完全不直接碰 plugin 類別
- [ ] rewarded 廣告單元 ID 填 **iOS rewarded 測試 ID** `ca-app-pub-3940256099942544/1712485313` → verify:此常數只出現在 AdService 一處

## 階段 5:真機跑通(核心驗收)
- [ ] Godot 匯出 Xcode 專案 → Xcode 簽名 → 安裝到 iPhone → verify:app 在真機開起來
- [ ] 點「看廣告」→ 載入 → 播放 → verify:**畫面看得到「Test Ad」字樣**(沒有就立刻停,代表在拉真廣告)
- [ ] 看完廣告 → verify:`rewarded_succeeded` 觸發、點數 +1
- [ ] 連續點 3~5 次 → verify:每次都能重新載入並發獎勵,無卡死、非只成功一次

## 階段 6:失敗路徑(優雅降級驗收,別跳過)
- [ ] 開飛航模式 / 斷網後點「看廣告」 → verify:`rewarded_failed` 觸發,按鈕給明確回饋(例「廣告暫時無法載入」),**非無反應、非當機**
- [ ] 廣告播到一半中離 → verify:不發獎勵、狀態正常復原、可再次嘗試

## 階段 7:Spike 結案判定
- [ ] **通過** = 階段 5 全綠 + 階段 6 全綠 → Godot + godot-admob-plugin 在 iOS 可承載核心變現 → **選型拍板,開始蓋 Sparkote 本體**
- [ ] **不通過** = 記錄卡在哪步(plugin 維護 / iOS 整合 / ATT / Godot 版本相容) → 帶證據重新評估(換 plugin / 換 Godot 版本 / 才考慮 Unity)

---

## 紅線提醒(全程)
- 只用本檔的 **sample 測試 ID**,絕不填自己的正式 ID。
- 操作前先確認畫面有 **「Test Ad」**,才繼續。
- 測試廣告隨便點;一旦換成正式 ID,自己一下都不能點(AdMob 視為無效流量,會封廣告帳號)。

---

## 測試 ID 對照表

| 用途 | iOS 測試 ID | Android 測試 ID(之後上 Android 用) |
|---|---|---|
| App ID(`~` 結尾) | `ca-app-pub-3940256099942544~1458002511` | `ca-app-pub-3940256099942544~3347511713` |
| Rewarded(`/` 結尾) | `ca-app-pub-3940256099942544/1712485313` | `ca-app-pub-3940256099942544/5224354917` |
| Interstitial | `ca-app-pub-3940256099942544/4411468910` | — |
| Banner | `ca-app-pub-3940256099942544/2934735716` | — |

> ⚠️ 這些 ID 多年穩定但仍應以 Google 官方文件為準(Google Mobile Ads SDK → iOS → Test ads)。動手前建議核對一次,避免版本過期。
