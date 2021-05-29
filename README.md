# (株)spread 勤怠システム

## 飲食事業部を主に勤怠管理を行うシステムです。
<br>

### 【仕様】
### -管理者-
```
- 全スタッフの勤怠情報、設定を閲覧、修正できる
- 社内で扱う形式のCSVファイルを出力できる
（全員の勤怠情報をまとめて集計したもの）
- スタッフの追加・削除ができる
```

<br>

-他スタッフ-
```
- ログイン後シンプルなフォームから勤怠登録ができる
```

<br>

### 【追加・修正予定】
```
- 一部機能を制限した管理権限の追加
(店長はパートナーの勤怠に限って修正できる。など)
- 打刻漏れや不正勤怠の通知機能追加
- リファクタリング
- 勤務時間の細分化計算ロジックを組む
```

### 開発環境
```
- Ruby 2.6.3
- Ruby on Rails 5.1.7
```
### 初期データ
```
管理者
    社員コード 999
    パスワード password
一般
    社員コード 1001,1002,1003,1004,9001
    パスワード password（一律）
```

### URL
```

```
