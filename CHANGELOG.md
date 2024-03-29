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

## 1.3.2 2021/05/18
- `Mgmg::TPolynomial`に比較演算子を追加．
- `String#phydef_optimize`，`String#buster_optimize`を追加．
- (`Enumerable#search`から呼び出される)`Enumerable#comp_search`における最大道具製作レベルチェックが間違っていたバグを修正．
- `String#search`および`Enumerable#search`において，総経験値量が等しい組み合わせの場合，目標パラメータが大きくなる製作Lvの組み合わせを返すように修正．

## 1.4.0 2021/06/03
- `Mgmg::Equip#atk_sd`，`Mgmg::Equip#dex_as`，`Mgmg::Equip#mag_das`，`Mgmg::Equip#magmag`を，威力値の定数倍(常に`Integer`)から威力値そのもの(`Rational`)に変更．これに伴い，`Mgmg::Equip#power`の返り値も威力値とした．互換性のため，`Mgmg::Equip#fpower`はそのまま残した．
- ver2.00β12で導入された，合成の消費エレメントが地と火または水で折半される仕様に対応した．`Mgmg::Equip#comp_cost`は従来の値の半分となり，`Mgmg::Equip#total_cost`はver2.00β12以降の総消費エレメントとなった．
- `Mgmg::TPolynomial#<=>`を追加．
- `Enumerable#show`を追加．
- `Mgmg::Equip#pmdef`で，`Mgmg::Equip#phydef`と`Mgmg::Equip#magmag`のうち，小さい方を返すようにし，`String#poly`の引数に`:pmdef`を受け付けるようにした．

## 1.4.1 2022/01/06
- [リファレンス](./reference.md)を[README](./README.md)から分離独立させた．
- `Mgmg::IR`を追加．
	- これを生成するための`String#ir`および`Enumerable#ir`を追加
	- `String#search`および`Enumerable#search`において，内部的にこれを利用することで高速化．
- `Mgmg.#find_lowerbound`, `Mgmg.#find_upperbound`を追加．
- 魔法の威力に対応する`Mgmg::Equip#magic2`を追加．
- `String#min_levels`およびその関連メソッドにおいて，重量1以外を指定できるようにした．

## 1.4.2 2022/06/09
- `Mgmg::Equip#reinforce`および`Mgmg::IR`を使うメソッド群に`reinforcement`キーワード引数を追加．
	- スキルおよび料理による強化効果をシミュレートできるようになった．
	- 料理については，プリセット料理名または`Mgmg.#cuisine`で生成される`Mgmg::Cuisine`オブジェクトを使う．

## 1.5.0 2022/06/22
- `Mgmg::Option`を実装し，search系メソッドを中心としたキーワード引数を，このクラスに集約してから受け渡すようにした．
	- オプションオブジェクトは`Mgmg.#option`によって生成し，キーワード引数`opt`に渡す．従来のキーワード引数は廃止された．
	- この変更で，一部の受け渡し忘れのバグが修正され，パフォーマンスが改善した．
- `Enumerable#search`で無駄な処理が発生していて，処理時間がかかっていたバグを修正．
- `String#min_level`，`Enumerable#min_level`の仕様を変更し，合成後の重量を目標値にするのに必要な鍛冶・道具製作Lvを計算するようにした．
	- この変更に伴い，`Mgmg::Equip#min_level`を，`Mgmg::Equip#min_levels_max`に名称変更し，`String#min_levels_max`，`Enumerable#min_levels_max`を追加した．
	- 関連して，`String#max_weight`，`String#min_weight`，`Enumerable#max_weight`，`Enumerable#min_weight`，`Enumerable#max_weights`，`Enumerable#min_weights`を追加した．
	- `Mgmg::Option#smith_min`，`Mgmg::Option#armor_min`のデフォルト値を，`String#min_level`，`Enumerable#min_level`を用いて設定する仕様とし，その目標重量を`Mgmg::Option#target_weight`で指定するようにした．
- `String#min_comp`，`String#min_smith`，`Enumerable#min_comp`，`Enumerable#min_smith`において，既製品のみである，合成を行わないなど，該当スキルが必要ないレシピである場合の返り値を`-1`に変更した．

## 1.5.1 2022/06/24
- `Mgmg::Recipe`を実装し，レシピ`String`または`Enumerable`と，注目パラメータ`Symbol`，オプション`Mgmg::Option`をセットで取り扱えるようにした．
	- `String#to_recipe(para=:power, allow_over20: false, **kw)`または`Enumerable#to_recipe(para=:power, **kw)`で生成できる．
	- `Mgmg::Recipe#build`，`Mgmg::Recipe#search`など`String`等に対する操作と同様にでき，注目パラメータとオプションは，`to_recipe`でセットしたものがデフォルトで使われるようになる．各メソッド呼び出し時にキーワード引数を与えることで，一時的に上書きすることもできる．
- `String#to_recipe`にのみ，☆20制限のチェック機構を導入した．
- 計算を繰り返した際，複数装備の装備数が増加していってしまうバグを修正した．

## 1.5.2 2022/06/28
- `String#poly`が`:magic2`に対応していなかったバグを修正．

## 1.5.3 2022/06/28
- `Recipe#option`がキーワード引数を受け取れなかったバグを修正．

## 1.5.4 2022/06/30
- 既製品の探索を制御する`:include_system_equips`オプションを追加．
	- 既製品を含まないレシピを計算するとき，これを偽に設定することで，高速化される．
	- デフォルト値は`true`．ただし，既製品を含まないレシピ文字列を`to_recipe`すると，自動的に`false`に書き換える．
- 一部のメソッドで計算結果をキャッシュすることで，同じ材料装備を含む大量のレシピを計算する場合に高速化された．
	- `Mgmg.#clear_cache`ですべてのキャッシュをクリアできる．
- 一部のオプションのデフォルト値をグローバルに変更するための定数ハッシュ`Mgmg::Option::Defaults`を追加．

## 1.5.5 2022/07/02
- `Enumerable#to_recipe`が動かなくなったバグを修正．
- `String#min_level`において，正しい答えを返さなくなったバグを修正．

## 1.5.6 2022/07/17
- `Mgmg.#find_lowerbound`，`Mgmg.#find_upperbound`における探索刻み幅を1から1/8に変更し，コーナーケースでの精度を上昇させた．
- `Enumerable#min_level`が，原料☆によるレベル制限を無視した値を返すことがあったバグを修正．
- `Mgmg.#find_lowerbound`や`Mgmg::IR#atk_sd` などにおいて，返り値が，分母が1の`Rational`である場合，代わりに`Integer`を返すように修正．

## 1.5.7 2022/10/15
- 経験値上限を指定して，目標パラメータを最大化する製作Lvを返す`Mgmg::Recipe#find_max`を追加．
- `Mgmg::Recipe#search`において，解の経験値が`cut_exp`ちょうどの場合に例外となっていたバグを修正．

## 1.6.0 2022/10/18
- `Mgmg.#find_upperbound`のアルゴリズムを改善し，探索下限目標値の引数を削除．
- `Enumerable#search`，`Enumerable#find_max`が正しい解を返さない場合があったバグを修正．

## 1.6.1 2022/10/21
- `Mgmg.#find_lowerbound`，`Mgmg.#find_upperbound`において，同値レシピを指定した場合などを例外とするように修正．
- `Enumerable#to_recipe`にも`allow_over20`キーワード引数を導入し，デフォルトで☆20を超えるレシピを含む場合に例外とするように修正．
- 実効HP(最大HP+腕力)を表す`Mgmg::Equip#hs`を追加．

## 1.6.2 2022/10/31
- 既製品を含むかどうかのチェックを行った場合，同じレシピについては繰り返しチェックしないようにして高速化した．

## 1.7.0 2022/11/12
- オプション`step`を廃止し，レシピに応じて自動的に無駄な探索を省略するように変更．
- `String/Enumerable#search/find_max`において，フィボナッチ探索を用いたアルゴリズムに変更．単峰でないため，オプション`comp_ext`を使って追加の探索を行い，取りこぼしを避ける．
- `Mgmg.#find_upperbound`のアルゴリズムに誤りがあり，大きく間違えた解を返していた問題を修正．
- `Mgmg::IR#attack`等において，引数が`nil`(製作Lvを指定せず，多項式を返す)の場合に，例外となっていたバグを修正．
- オブション`smith/armor/comp_max`のデフォルト値を10^9に変更．

## 1.8.0 2022/11/14
- オプション`comp_ext`を`fib_ext`に変更し，追加探索の範囲を修正．
- オプション`smith/armor/comp_max`の扱い方を修正し，デフォルト値を10^5に変更．
- `Enumerable#find_max`，`Mgmg.#find_lowerbound`のバグを修正．

## 1.8.1 2022/11/19
- `Mgmg::Recipe`に`name`属性を追加．`String/Enumerable#to_recipe`の際，キーワード引数`name`を追加することで設定できる．
- `Mgmg.#efficient_list` を追加．
- `Enumerable#build`，`Enumerable#search`で意図せぬ例外が発生していた問題を修正．

## 1.8.2 2022/11/21
- オプション`cut_exp`で探索が打ち切られる場合に，`Mgmg::SearchCutException`でない例外が発生する場合があったバグを修正．
