# (株)Spread 勤怠システム

飲食事業部を主に勤怠管理を行うシステムです。

## 共同開発の流れ(git flow)

1.トピックブランチへ移動
git checkout nakashi or hayashi

2.develop ブランチをトピックブランチへ merge する
(nakashi or hayashi) git merge develop

    ※コンフリクト発生時は解消後↓
      ※(nakashi or hayashi) git add 【【. or -p】→ git commit -m"--" #修正をコミットする

3.各トピックブランチでコード実装

4.コミットする

```
    git add -a -m"コメント"
```

5.develop ブランチへ移動
git checkout develop

6.リモートリポジトリの最新を取得
(develop) git pull

7.develop にトピックブランチの実装を反映
(develop) git merge nakashi or hayashi

8.リモートリポジトリにプッシュする。
(develop) git push

### 開発環境

- Ruby 2.6.3
- Ruby on Rails 5.1.7
- heroku