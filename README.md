# lumi-resources

AIが管理するlumiシリーズのリソースレジストリです。

「ルキルキ」のような略称を、正式名称と各サービス固有の識別子へ解決するために使います。
実行時の予定取得は各サービスのCLIまたはHTTP APIが担当し、このリポジトリは取得対象の定義だけを提供します。

## 現在の定義

resources.yamlには、現時点で次のリソースを登録しています。

- 正式名称: ROOKEY♡ROOKEYS
- 略称: ルキルキ
- TimeTree: plus_newidol
- TicketDive: kGnh5rGrPQGi4OEoaoIm
- Lit.link: amamiyasaku（雨宮サク個人ページによる補助取得）

Lit.linkの定義はグループ公式ページではないため、member-proxyとして扱います。
この区別を保持することで、個人予定とグループ予定を自動的に同一視しません。

## 利用例

    lumitlink events amamiyasaku
    lumitree candidate plus_newidol
    lumidive candidate https://ticketdive.com/artist/kGnh5rGrPQGi4OEoaoIm

各CLIはlumi.event.feed.v1を標準出力へ返します。集約側はresources.yamlのcli定義を読み、結果を共通形式として処理できます。

## 検証

    ./scripts/validate.sh

CIではPull Requestとmainへのpushで同じ検証を実行します。

## 設計方針

- YAMLを正本とし、データベースや管理APIを持たない
- AIは公式リンクの探索、別名解決、識別子の更新、根拠の記録を担当する
- 予定取得の実行時はYAMLを読むだけにし、AIの推論結果を毎回の取得経路へ持ち込まない
- 取得方法の違いはサービス側CLIに閉じ込める

