# 更新履歴

## 1.0.0 2018/12/22
- 初版．

## 1.0.1 2018/12/23
- 魔水の副重量が間違っていたバグを修正．
- `Mgmg::Equip#magmag`を追加．

## 1.0.2 2018/12/23
- `Mgmg::Equip#+`を追加し，`Array#equip`を削除．
- `Enumerable#map(&:build).sum`的なことをする`Enumerable#build`を追加した．

## 1.0.3 2018/12/30
- `Integer`へのモンキーパッチを`Refinements`に置き換えた(外部から見えなくなった)．無駄に2倍にしていたエレメント値の主原料値を戻した．

## 1.0.4 2019/01/11
- `Mgmg::Equip#power`では数字が大きくなり，わかりにくくなるため，`Float`にして正規の威力値を返す`Mgmg::Equip#fpower`を追加した．

## 1.0.5 2019/01/12
- HPの材質値を5倍にしてしまっていたバグを修正．

## 1.0.6 2019/01/13
- 消費エレメント計算において，WikiではHPのみ1/4倍となっていたところ，Excel版ではMPも1/4倍されていたため，MPも1/4倍となるように修正．

## 1.0.7 2019/02/26
- github に登録．gem 化し，rubygems.org に登録．

## 1.0.8 2019/03/15
- マニュアル等の不備を修正．

## 1.0.9 2019/05/30
- 丸めを無視した多項式近似(変数は製作レベル)を表す`Mgmg::TPolynomial`およびこれを生成するメソッド`String#poly`を追加．

## 1.0.10 2019/06/29
- 消費エレメント量を返す`Mgmg::Equip#total_cost`を追加．
	- `Mgmg::Equip#inspect`の返り値にこれを含めるように変更．
	- `String#build`等において，製作Lvを負の値にすると，街の製作屋に依頼した場合のコストを計算するように変更．

## 1.0.11 2019/06/29
- ローブの表記ゆれとして，法衣の入力を許容するように．

## 1.1.0 2019/07/27
- 量産品の本と一般的な本の魔力が入れ替わっていたバグを修正．
- MPを持つ装備の消費エレメント量計算が間違っていたバグを修正．
- (今まで製作品のみに対応していた)既成品の表記ゆれに対応し，正しいアイテム名を受け入れるように修正した．
- `Enumerable#build()`の引数が2個だけ入力された場合のレベル設定を，`comp=[smith,armor].max`から`comp=armor.tap{armor=smith}`に変更．
- `Mgmg::Equip#fpower`および`Mgmg::Equip#power`の仕様を変更．
	- 魔防が最大の防具に対する`Mgmg::Equip#fpower`の返り値を実効魔防値に変更．
	- 複数装備に対する`Mgmg::Equip#fpower`の返り値を9パラ合計値(HPとMPは1/4倍)に変更．
	- `Mgmg::Equip#power`の返り値も，その2倍または4倍の整数値に変更．
- 完全ではないが，レシピ文字列の正当性チェックを導入し，どの部分文字列でパース失敗となったかを例外メッセージに入れた．
	- 不正文字種の混入，括弧の対応不備をチェック．
	- 部分文字列に対して，鍛冶・防具製作レシピとして，装備種別名として，素材としてのいずれで解釈して失敗したかを示すように．
		- 既成品の名前を間違えた場合，鍛冶・防具製作レシピとして解釈できなかった扱いになる．
- その他，README.md，CHANGELOG.md の細部を修正．

## 1.2.0 2019/08/04
- `Mgmg::TPolynomial`に，基礎的な演算を行うメソッドを追加した．
	- 加減及びスカラー倍に関するもの: `+`, `-`, `scalar`, `*`, `quo`, `/`, `+@`, `-@`
	- 偏微分: `partial_derivative`
- 近似多項式において，floor(種別値*主原料値)部分に丸め後の値を使うように変更した．
- レシピ中の空白文字とバックスラッシュを無視するようにした．

## 1.2.1 2019/08/07
- `String#poly`が受け取れる引数に`:cost`を追加．消費エレメント量に関する近似多項式を返す．
- 主装備の種別値が0であることにより，継承されないはずのパラメータについて，近似多項式計算で誤って継承していたバグを修正．
- `Mgmg::TPolynomial#to_s`において，`self`が零多項式の場合に空文字列を返していたのを，`0/1`を`fmt`で文字列に変換した値を返すように修正．

## 1.2.2 2019/08/07
- `Mgmg::`指定忘れのバグを修正．

## 1.2.3 2019/11/10
- typoに基づくバグの修正．

## 1.2.4 2020/03/01
- 開発用のgemのバージョンを更新(ライブラリ本体は更新なし)．

## 1.2.5 2020/08/22
- `Mgmg::TPolynomial#leading(fmt=nil)`, `Mgmg::TPolynomial#[](i, j)`を追加．
- `Mgmg::Equip#history`, `Mgmg::Equip#min_levels`, `Mgmg::Equip#min_level`を追加．
- ソースコードのファイル配置を整理．

## 1.3.0 2020/08/26
- 既製品に対する`Mgmg::Equip#min_level`の返り値を`nil`から`0`に変更．
- `String#build`において，第1引数にもデフォルト値`-1`を設定し，引数なしで委託製作相当とするように変更．
- `String#poly`のデフォルト引数を`:cost`に設定．
- `Mgmg.#exp`，`String#eff`，`String#peff`，`String#min_levels`を追加．
- `String#smith_search`, `String#comp_search`, `String#min_smith`, `String#min_comp`を追加．

## 1.3.1 2020/08/31
- `String#poly`のキーワード引数`left_associative`が無視される場合があったバグを修正．
- `Mgmg.#exp`に3引数を与えられるように修正．
- `String#search`，`Enumerable#search`を追加．
- `Enumerable#min_levels`，`Enumerable#min_level`，`Enumerable#min_smith`，`Enumerable#min_comp`を追加．

## 1.3.2
- `Mgmg::TPolynomial`に比較演算子を追加．
- `String#phydef_optimize`，`String#buster_optimize`を追加．
- (`Enumerable#search`から呼び出される)`Enumerable#comp_search`における最大道具製作レベルチェックが間違っていたバグを修正．
- `String#search`および`Enumerable#search`において，総経験値量が等しい組み合わせの場合，目標パラメータが大きくなる製作Lvの組み合わせを返すように修正．
