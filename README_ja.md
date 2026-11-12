# Ruby Text Lite for Godot 4

[Ruby Text for Godot 4](https://ibuking289.itch.io/ruby-text-godot4)（$4）の無料
Lite 版です。完全版はブラウザで試せます: [無料の Web デモ](https://ibuking289.itch.io/japanese-text-godot-demo)。
仕組みの解説（Zenn）: [Godot 4 の RichTextLabel にルビ（ふりがな）を自力で付ける仕組み](https://zenn.dev/ibuking289/articles/godot4-ruby-richtextlabel)。

`RichTextLabel` にふりがな / ルビ / ピンインを表示します。
`[ruby=よみ]漢字[/ruby]` BBCode を使うと、本文の上に小さな読みテキストを
中央揃えで描画します -- Godot 既存の BBCode エフェクト（color、wave、shake
など）や、タイプライター風の `visible_characters` / `visible_ratio` と
組み合わせ可能です。

> **このアドオンのコードは AI（Claude）の助けを借りて書かれました。**

## できること (Lite)

- 差し替えが簡単: `RubyLabelLite` ノードを追加し、`text` の代わりに
  `ruby_text` を設定するだけ。
- `[ruby=よみ]漢字[/ruby]` BBCode 記法 -- Lite が理解する入力記法はこれだけ
  です（full 版が追加する記法は下の表を参照）。
- 他の BBCode タグ（`[color]`、`[wave]`、`[shake]` など）と併用可能 -- ルビ
  自体は本文の BBCode 色とは独立した `ruby_color` で描画されます。
- タイプライター対応: 本文の文字が実際に表示されてからルビが出るので、
  `visible_characters` / `visible_ratio` とそのまま組み合わせられます。
- 2行に折り返された本文のルビは行セグメントごとに描画されるため、
  テキストに重なりません。
- 隣接するルビは重ならないよう調整: 同じ行の隣り合うルビが衝突するほど
  幅がある場合、後のルビを右へ（行末を超えそうなときは前のルビを左へ）
  最小限ずらして間隔を保ちます。
- 自動縦スペース確保 (`auto_spacing`) により、ルビが前の行やラベル上端で
  切れないようにします。

## 導入方法

1. `addons/ruby_text_lite/` をプロジェクトの `addons/` フォルダにコピー
   （または [Releases](https://github.com/imaiibuki/ruby-text-lite-godot4/releases/latest) の `ruby_text_lite_v1.0.0.zip` をプロジェクトのフォルダに展開）。
2. プロジェクト設定 > プラグイン で「Ruby Text Lite」を有効化（任意 --
   `RubyLabelLite` は `class_name` により、プラグインを有効にしなくても
   そのまま使えます。有効化すると「ノードを作成」ダイアログに
   `RubyLabelLite` 用のアイコン/ショートカットが追加されるだけです）。
3. `RubyLabelLite` ノードを追加（または既存の `RichTextLabel` ノードの型を
   シーンドックで `RubyLabelLite` に変更）し、通常の `normal_font` テーマ
   オーバーライドでフォントを割り当て、`ruby_text` を設定します。

Lite のクラス名（`RubyLabelLite`、`RubyParserLite`、`RubyLayoutLite`、
`RBEffectLite`）はすべて full 版とは別名にしているため、Lite と full 版
「Ruby Text」を同じプロジェクトに両方導入しても `class_name` の衝突は
起きません。

## プロパティ (RubyLabelLite)

| プロパティ | 型 | デフォルト | 説明 |
|---|---|---|---|
| `ruby_text` | String（複数行） | `""` | `[ruby=よみ]漢字[/ruby]` BBCode を使った入力テキスト。設定すると BBCode に変換され `RichTextLabel.text` に代入されます。 |
| `ruby_scale` | float | `0.5` | ラベルの `normal_font_size` に対するルビのフォントサイズの比率。 |
| `ruby_color` | Color | 白 | ルビ文字の塗り色。 |
| `ruby_offset` | float | `2.0` | ルビと本文グリフ上端との追加の隙間（px）。 |
| `auto_spacing` | bool | `true` | ルビが切れないよう縦方向のスペースを自動で確保します。 |
| `ruby_reveal` | enum | `FIRST_CHAR` | `FIRST_CHAR`: 本文の最初の文字が表示された時点でルビを表示。`ALL_CHARS`: 本文の全文字が表示されるまで待つ。 |

## Lite と full 版 Ruby Text（$4）の比較

| 機能 | Lite（無料） | full 版（$4） |
|---|---|---|
| `[ruby=よみ]漢字[/ruby]` BBCode | あり | あり |
| 青空文庫/なろう記法 `｜漢字《よみ》`、`漢字《よみ》` | なし（そのまま文字として表示） | あり |
| モノルビ `｜東京《とう・きょう》` | なし | あり |
| 傍点（圏点）`《《強調》》` | なし | あり |
| ルビの縁取り (`ruby_outline_size`/`ruby_outline_color`) | なし | あり |
| `ruby_scale`、`ruby_color`、`ruby_offset`、`auto_spacing` | あり | あり |
| タイプライター表示 (`visible_characters`/`visible_ratio`、`ruby_reveal`) | あり | あり |
| 隣接ルビの重なり回避 | あり | あり |
| 折り返し本文の処理 | あり | あり |

full 版: <https://ibuking289.itch.io/ruby-text-godot4>

## 制限事項 (Lite、正直な一覧)

- 認識するのは `[ruby=よみ]漢字[/ruby]` BBCode のみです。`｜`/`《`/`》` や
  `・` 区切りの読みは、入力したとおりそのまま文字として出力されます
  （ルビにならず、エラーにもなりません）。
- ルビの縁取りオプションはありません。
- その他のレンダリング上の制限は full 版と同様です（縦書き非対応、本文より
  広い読みは中央揃えで overhang しエッジでクランプ、折り返し本文の読みは
  言語的に「賢く」ではなく比例分割されるなど）。詳細は full 版の README を
  参照してください。

## 日本語の行頭禁則

テキストの言語が日本語のとき（`label.language = "ja"`、または Godot 4.6
以降は日本語の OS などアプリの言語を受け継いだとき）、Godot の既定の設定
では行頭に小さい仮名（っ・ゃ など）や ー が来ることがあります。Godot 4.5
以降は **プロジェクト設定 > Internationalization > Locale > Line Breaking
Strictness** を **Strict** にしてください。`RubyLabelLite` で 4.7.2 で測ると
（`language = "ja"`、Noto Sans JP 20 px、46 の幅）48 件が 0 件になりました。Godot
4.3・4.4 にはこの設定がありません。

## 動作確認済みバージョン

- **Godot 4.7.2-stable** および **Godot 4.3-stable**、Windows x64、
  headless: ユニットテスト（`tests/`、配布 zip には含まれません）は全て
  パス、加えてパッケージ化した zip の導入チェック（新規プロジェクトで
  アドオン内の全スクリプトがパースエラーなく読み込まれること）も確認済み。
- **Godot 4.4.1・4.5.2・4.6.3-stable**、Windows x64、headless:
  ユニットテストは全てパス（zip の導入チェックは 4.3・4.7.2 のみ）。
- レンダリングされたスクリーンショットでの目視確認、および上記以外の
  Godot 4.x バージョン・レンダラー・OS・エクスポートテンプレート
  （モバイル/web）での確認は行っていません。

## ライセンス

MIT（`LICENSE` 参照）。アドオン自体にフォントは要りません。日本語のフォント
（例: Noto Sans JP）を `normal_font` に割り当ててください。デモにはそのまま表示できるよう Noto Sans JP（SIL OFL 1.1）を同梱しています（`NOTICE.md` 参照）。full 版（Ruby Text for Godot 4）は別のライセンスで
個別に販売されています。
