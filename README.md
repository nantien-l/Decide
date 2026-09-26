# Decide

Decide 是一個以 SwiftUI 製作的 iOS 選擇輔助 App。輸入煩惱或選項，讓 App 協助整理候選項目，再以動畫隨機選出結果。

## 功能

- 手動建立問題與選項，支援新增、排序與刪除選項。
- 使用 Apple Intelligence 將自然語言整理成可編輯的決策問題與候選選項。
- 語音輸入可直接轉寫為決策提示。
- 決策動畫、觸覺回饋與重新選擇功能。
- 使用 SwiftData 在裝置上儲存決策歷程與結果，支援分類、收藏及篩選。
- 支援 App Intents，可從 Shortcuts 開啟已預先填入的決策。
- 可設定語言、外觀、文字大小、觸覺回饋與決策動畫。

## 需求

- Xcode 27 或更新版本
- iOS 27.0 或更新版本
- 使用 AI 建議時，需要支援並啟用 Apple Intelligence 的裝置
- 使用語音輸入時，需要授權麥克風與語音辨識權限

## 執行方式

1. 使用 Xcode 開啟 `Decide.xcodeproj`。
2. 在 Scheme 選擇 `Decide`，再選擇 iPhone 模擬器或實體裝置。
3. 按下 Run。

也可以在專案根目錄執行：

```sh
xcodebuild -project Decide.xcodeproj -scheme Decide -sdk iphonesimulator -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

## 隱私

決策紀錄保存在裝置本機。語音功能會使用 iOS 的語音辨識服務；AI 建議依賴 Apple Intelligence 是否可用與其系統設定。

## 技術

SwiftUI、SwiftData、App Intents、Speech、AVFAudio 與 Foundation Models。
