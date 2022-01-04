# リファレンス
本ライブラリで定義される主要なメソッドを以下に解説します．

## `String#build(smith=-1, comp=smith, left_associative: true)`
レシピ文字列である`self`を解釈し，鍛冶・防具製作Lvを`smith`，道具製作Lvを`comp`として鍛冶・防具製作及び武器・防具合成を行った結果を後述の`Mgmg::Equip`クラスのインスタンスとして生成し，返します．例えば，
```ruby
'[杖(水玉10火玉5)+本(骨10鉄1)]+[本(水玉5綿2)+杖(骨10鉄1)]'.build(112, 176)
```
のようにします．基本的に`[]`による合成順序の指定が必要ですが，不確定の場合，`left_associative`が真なら左結合，偽なら右結合として解釈します．
```ruby
'法衣(綿10皮10)+歴戦の服'
```
のように，既成品を含む合成レシピも解釈します．キャラクリ初期装備の劣悪な服，劣悪な小手以外のあらゆる装備を網羅しています．劣悪な服，劣悪な小手はキャラクリ以外での初期装備品として解釈します．`comp`を省略した場合，`smith`と同じ値として処理します．

`self`が解釈不能な場合，例外が発生します．また，製作Lvや完成品の☆制限のチェックを行っていないほか，本ライブラリでは`武器+防具`や`防具+武器`の合成も可能になっています．街の鍛冶・防具製作・道具製作屋に任せた場合をシミュレートする場合は製作Lvを負の値(`-1`など，負であれば何でもよい)にします(製作Lv0相当の性能を計算し，消費エレメント量は委託仕様となります)．

## `Enumerable#build(smith=-1, armor=smith, comp=armor.tap{armor=smith}, left_associative: true)`
複数のレシピ文字列からなる`self`の各要素を製作し，そのすべてを装備したときの`Mgmg::Equip`を返します．製作では`鍛冶Lv=smith`, `防具製作Lv=armor`, `道具製作Lv=comp`とします．1つしか指定しなければすべてそのLv，2つなら1つ目を`smith=armor`，2つ目を`comp`に，3つならそれぞれの値とします．`left_associative`はそのまま`String#build`に渡されます．製作Lvが負の場合，製作Lv0として計算した上で，消費エレメント量は街の製作屋に頼んだ場合の値を計算します．武器複数など，同時装備が不可能な場合でも，特にチェックはされません．

## `String#min_level(weight=1)`
`self`を`weight`以下で作るための最低製作Lvを返します．`build`と異なり，合成や既成品は解釈できません．また，素材の☆による最低製作Lvとのmaxを返すため，街の鍛冶・防具製作屋に頼んだ場合の重量は`self.build.weight`で確認する必要があります．`weight`を省略した場合，重量1となる製作Lvを返します．

## `String#min_levels(left_associative: true)`
合成レシピの各鍛冶・防具製作品に対して，レシピ文字列をキー，重量1で作製するために必要な製作Lvを値とした`Hash`を返します．重量1以外は指定できません．
最大値は，`self.build.min_level`によって得られます．

## `Enumerable#min_levels(left_associative: true)`
すべての要素`str`に対する`str.min_levels`をマージした`Hash`を返します．

## `Enumerable#min_level(left_associative: true)`
`self.min_levels`から武器，防具それぞれに対する最大値を求め，`[必要最小鍛冶Lv, 必要最小防具製作Lv]`を返します．武器，防具の一方のみが含まれる場合，もう一方は`0`になります．
`String#min_level`と異なり，重量1以外は指定できません．

## `String#min_comp(left_associative: true)`，`Enumerable#min_comp(left_associative: true)`
レシピ通りに合成するのに必要な道具製作Lvを返します．ただし，全体が「[]」で囲われているか，非合成レシピの場合，代わりに`0`を返します．

`Enumerable`の場合，すべての要素に対する最大値を返します．

## `String#min_smith(left_associative: true)`，`Enumerable#min_smith(left_associative: true)`
レシピ通りに製作するのに必要な鍛冶・防具製作Lvを返します．製作物の重量については考慮せず，鍛冶・防具製作に必要な☆条件を満たすために必要な製作Lvを返します．

`Enumerable`の場合，すべての要素に対し，武器，防具それぞれの最大値を求め，`[必要最小鍛冶Lv, 必要最小防具製作Lv]`を返します．

## `String#poly(para=:cost, left_associative: true)`
レシピ文字列である`self`を解釈し，`para`で指定した9パラ値について，丸めを無視した鍛冶・防具製作Lvと道具製作Lvの2変数からなる多項式関数を示す`Mgmg::TPolynomial`クラスのインスタンスを生成し，返します．`para`は次のシンボルのいずれかを指定します．
```ruby
:attack, :phydef, :magdef, :hp, :mp, :str, :dex, :speed, :magic
```
これらは，`Mgmg::Equip`から当該属性値を取得するためのメソッド名と同一です．`left_associative`は`String#build`の場合と同様です．

`para`として，複数の9パラ値を組み合わせた以下のシンボルを指定することもできます．
```ruby
:atkstr, :atk_sd, :dex_as, :mag_das, :magmag, :pmdef
```
ただし，自動選択の`:power`は指定できません．

また，`:cost`を渡すことで，消費エレメント量に関する近似多項式を得られます．`self`に`"+"`が含まれていれば合成品とみなし，最後の合成に必要な地エレメント量を，それ以外では，武器なら消費火エレメント量を，防具なら消費水エレメント量を返します．ただし，`self`が既成品そのものの場合，零多項式を返します．

## `String#ir(left_associative: true)`
レシピ文字列である`self`を解釈し，9パラ値について，丸めを考慮した鍛冶・防具製作Lvと道具製作Lvの2変数からなる関数オブジェクトを保持する`Mgmg::IR`クラスのインスタンスを生成し，返します．詳しくは，後述の`Mgmg::IR`クラスの説明を参照ください．

## `Enumerable#ir(left_associative: true)`
複数のレシピ文字列からなる`self`の各要素を製作し，そのすべてを装備したときの`Mgmg::IR`を返します．この場合，鍛冶Lv，防具製作Lv，道具製作Lvの3変数からなる関数オブジェクトを保持するものとして扱われます．各装備の種別に応じ，鍛冶Lvまたは防具製作Lvを適用し，9パラ値を計算します．

## `String#smith_seach(para, target, comp, smith_min=nil, smith_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false)`
`para`の値が`target`以上となるのに必要な最小の鍛冶・防具製作Lvを二分探索で探索して返します．
道具製作Lvは`comp`で固定，鍛冶・防具製作Lvを`smith_min`と`smith_max`で挟み込んで探索します．
`smith_min`が`nil`のとき，`min_smith`が真なら重量を問わず☆的に必要な最小の鍛冶・防具製作Lv (`self.min_smith`)，偽なら最小重量で製作するのに必要な鍛冶・防具製作Lv (`self.build.min_level`)を使用します．
`smith_min<smith_max`でないとき，`smith_max`で`para`が`target`以上でないときは`ArgumentError`となります．
`para`は，`Mgmg::Equip`のメソッド名をシンボルで指定(`:power, :fpower`も可)します．
反転などの影響で，探索範囲において`para`の値が(広義)単調増加になっていない場合，正しい結果を返しません．
`cut_exp`以下の経験値で`target`以上を達成できない場合，`Mgmg::SearchCutException`を発生します．

## `String#comp_search(para, target, smith, comp_min=nil, comp_max=10000, left_associative: true)`
`String#smith_seach`とは逆に，鍛冶・防具製作Lvを固定して最小の道具製作Lvを探索します．
`comp_min`が`nil`のときは，製作に必要な最小の道具製作Lv (`self.min_comp`)を使用します．
その他は`String#smith_seach`と同様です．

## `String#search(para, target, smith_min=nil, comp_min=nil, smith_max=10000, comp_max=10000, left_associative: true, step: 1, cut_exp: Float::INFINITY, min_smith: false)`
`c_min=comp_search(para, target, smith_max, comp_min, comp_max)` から `c_max=comp_search(para, target, smith_max, comp_min, comp_max)` まで，`step`ずつ動かして，
`smith_search`を行い，その過程で得られた最小経験値の鍛冶・防具製作Lvと道具製作Lvからなる配列を返します．
レシピ中の，対象パラメータの種別値がすべて奇数，または全て偶数であるなら，`step`を`2`にしても探索すべき範囲を網羅できます．
`cut_exp`以下の経験値で`target`以上を達成できない場合，`Mgmg::SearchCutException`を発生します．

## `Enumerable#search(para, target, smith_min=nil, armor_min=nil, comp_min=nil, smith_max=10000, armor_max=10000, comp_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false)`
複数装備の組について，`para`の値が`target`以上となる最小経験値の`[鍛冶Lv，防具製作Lv，道具製作Lv]`を返します．
武器のみなら防具製作Lvは`0`，防具のみなら鍛冶Lvは`0`，合成なしなら道具製作Lvは`0`となります．
`cut_exp`以下の経験値で`target`以上を達成できない場合，`Mgmg::SearchCutException`を発生します．

## `Mgmg.#find_lowerbound(a, b, para, start, term, smith_min_a: nil, smith_min_b: nil, min_smith: false)`
レシピ`a`とレシピ`b`について，`para`の値を目標値以上にする最小経験値の組において，目標値`start`における優劣が逆転する目標値の下限を探索し，返します．
返り値は`[逆転しない最大目標値, 逆転時の最小para値]`です．前者は逆転目標値の下限，後者は，目標値が前者よりも少しだけ大きいときの`para`値です．
ここで，最小経験値が小さい方，または最小経験値が同じなら，そのときの`para`値が大きい方をよりよいものと解釈します．
`term`は`start`より大きい値とします．目標値`term`における優劣が，目標値`start`における優劣と同じ場合，`Mgmg::SearchCutException`を発生します．
`a`と`b`は`String`でもその`Enumerable`でも構いません．

`smith_min_a`と`smith_min_b`は，それぞれ`a`と`b`の探索最小鍛冶・防具製作Lvを指定します．これらが`nil`で，`min_smith`が真ならば，重量を無視した製作可能最小Lvが指定されます．`min_smith`が偽(デフォルト)ならば，最小重量で製作可能な製作Lvが指定されます．重量を無視した製作可能Lvでの重量が3で，重量が2以下となる製作Lvで探索したい場合などは，`smith_min_a`や`smith_min_b`を具体的に指定してください．

## `Mgmg.#find_upperbound(a, b, para, start, term, smith_min_a: nil, smith_min_b: nil, min_smith: false)`
`Mgmg.#find_lowerbound`とは逆に，目標値を下げながら，優劣が逆転する最大の目標値を探索し，返します．返り値は`[逆転する最大目標値, 逆転前の最小para値]`です．目標値が，前者よりも少しでも大きいと逆転が起こらず(逆転する目標値の上限)，少しだけ大きい時の`para`値が後者になります．

## `String#eff(para, smith, comp=smith, left_associative: true)`
[`smith`を1上げたときの`para`値/(`smith`を1上げるのに必要な経験値), `comp`を1上げたときの`para`値/(`comp`を2上げるのに必要な経験値)]を返します．
`para`は，`Mgmg::Equip`のメソッド名をシンボルで指定(`:power, :fpower`も可)します．

## `String#peff(para, smith, comp=smith, left_associative: true)`
近似多項式における偏微分値を使用した場合の，`String#eff`と同様の値を返します．`self.poly(para, left_associative: left_associative).eff(smith, comp)`と等価です．

## `String#phydef_optimize(smith=nil, comp=smith, left_associative: true, magdef_maximize: true)`
反転物防装備の反転材の種別，素材の最適化を行い，修正したレシピを返します．
`smith`，`comp`は探索を行う製作レベルを表し，`smith`が`nil`の場合，近似多項式で最適化を行います．近似多項式では，道具製作レベルの次数が高い項の係数を最適化します．
物防を最大化するレシピのうち，`magdef_maximize`が真なら魔防を最大化する組み合わせ，偽ならコストを最小化(≒魔防を最小化)する組み合わせを探索します．
ある範囲での全数探索を行うため，段数の多いレシピでは計算量が膨大になるほか，厳密な最適化を保証するものではなく，今後のアップデートで解が変わるような変更が入る可能性があります．

## `String#buster_optimize(smith=nil, comp=smith, left_associative: true)`
`String#phydef_optimize`の魔力弓版で，反転材の素材の最適化を行い，修正したレシピを返します．

## `Mgmg.#exp(smith, armor, comp=armor.tap{armor=0})`
鍛冶Lvを0から`smith`に，防具製作Lvを0から`armor`に，道具製作Lvを0から`comp`に上げるのに必要な総経験値を返します．鍛冶Lvと防具製作Lvは逆でも同じです．

## `Mgmg::Equip`
前述の`String#build`によって生成される装備品のクラスです．複数装備の合計値を表す「複数装備」という種別の装備品の場合もあります．以下のようなインスタンスメソッドが定義されています．

## `Mgmg::Equip#to_s`
```ruby
"杖4☆20(骨綿)[攻撃:119, MP:104, 魔力:1,859, EL:水2]"
```
のような，わかりやすい形式の文字列に変換します．上の例で「4」は重量，「骨」は主材質，「綿」は副材質を表します．各種数値が必要な場合は次以降に説明するメソッドをご利用ください．複数装備の場合は以下のような文字列になります．
```ruby
"複数装備9(武:1, 頭:1, 飾:2)[攻撃:15, 物防:34, 魔防:28, HP:241, MP:71, 器用:223, 素早:222, 魔力:6,604]"
```
「9」は合計重量，(武:1, 頭:1, 飾:2)は武器を1つ，頭防具を1つ，装飾品を2つ装備していることを示します．装備している場合は「胴」「腕」「足」も記述されます．

## `Mgmg::Equip#inspect`
`Mgmg::Equip#to_s`の出力に加え，0となる9パラ値を省略せず，総消費エレメント量を連結した文字列を出力します．すなわち，
```ruby
"杖4☆20(骨綿)[攻撃:119, 物防:0, 魔防:0, HP:0, MP:104, 腕力:0, 器用:0, 素早:0, 魔力:1859, EL:火0地0水2]<コスト:火2066地1575水0>"
```
のような文字列を返します．

## `Mgmg::Equip#weight, star`
それぞれ重量，☆数を整数値で返します．「複数装備」の場合，`weight`は総重量，`star`は装備数に関する値が返ります．

## `Mgmg::Equip#total_cost`
製作に必要な総エレメント量を，火，地，水の順のベクトルとして返します．ケージの十分性の確認には，下記の`comp_cost`を用います．

## `Mgmg::Equip#comp_cost(outsourcing=false)`
`self`が合成によって作られたものだとした場合の消費地エレメント量を返します．地ケージ確保のための確認用途が多いと思うので短い`cost`をエイリアスとしています．`outsourcing`が真の場合，街の道具製作屋に頼んだ場合のコストを返します．
武器なら火エレメント，防具なら水エレメントを，地エレメントと同値分だけ消費するため，火または水ケージも同量必要となります．

## `Mgmg::Equip#smith_cost(outsourcing=false)`
`self`が鍛冶・防具製作によって作られたものだったものだとした場合の消費火・水エレメント量を返します．`outscourcing`が真の場合，街の鍛冶屋・防具製作屋に頼んだ場合のコストを返します．

## `Mgmg::Equip#attack, phydef, magdef, hp, mp, str, dex, speed, magic, fire, earth, water`
それぞれ
```
攻撃，物防，魔防，HP，MP，腕力，器用，素早さ，魔力，火EL，地EL，水EL
```
の値を`Integer`で返します．

## `Mgmg::Equip#power`
武器種別ごとに適した威力計算値を返します．具体的には以下の値です．

|武器種別|威力計算値|
|:-|:-|
|短剣，双短剣|攻撃+腕力/2+器用/2|
|剣，斧|攻撃+腕力|
|弓|max(器用+攻撃/2+腕力/2, 魔力+器用/2+攻撃/4+腕力/4)|
|弩|器用+攻撃/2+腕力/2|
|杖，本|max(魔力x2，攻撃+腕力)|

弓，杖，本では`self`の性能から用途を判別し，高威力となるものの値を返します．防具に対してこのメソッドを呼び出すと，9パラメータのうち最も高い値を返します．

防具の場合，9パラメータのうち，最大のものを返します．ただし，最大の値に魔防が含まれている場合，代わりに「魔防+魔力/2」を返します．

複数装備の場合，9パラメータの合計値を返します．ただし，HPとMPは1/4倍します．HPとMPの特例は，消費エレメント量の計算と同様とするものです．

いずれの場合も，EL値，重量，☆は無視されます．

## `Mgmg::Equip#atkstr, atk_sd, dex_as, mag_das`
それぞれ
```
攻撃+腕力，攻撃+腕力/2+器用/2，器用+攻撃/2+腕力/2，魔力+器用/2+攻撃/4+腕力/4
```
の値を返します．これらはそれぞれ
```
(剣，斧，杖，本)，(短剣，双短剣)，(弓，弩)，(バスターアロー)
```
の威力です．トリックプレーやディバイドには対応していません．

## `Mgmg::Equip#magmag`
「魔防+魔力/2」の値を返します．魔力の半分が魔防に加算されることから，実際の魔防性能となります．

## `Mgmg::Equip#pmdef`
物防と実効魔防のうち，小さい方を返します．

## `Mgmg::Equip#+(other)`
`self`と`other`を装備した「複数装備」の`Mgmg::Equip`を返します．`self`と`other`はいずれも単品でも「複数装備」でも構いません．武器複数などの装備可否チェックはされません．

## `Mgmg::Equip#history`
多段階の合成におけるすべての中間生成物からなる配列を返します．
「複数装備」の場合，各装備の`history`を連結した配列を返します．

## `Mgmg::Equip#min_levels`
レシピ中の，鍛冶・防具製作物の文字列をキー，重量1で生成するのに必要な最小レベルを値とした`Hash`を返します．
「複数装備」の場合，各装備の`min_levels`をマージした`Hash`を返します．

## `Mgmg::Equip#min_level`
`min_levels`の値の最大値を返します．「複数装備」の場合，`[鍛冶の必要レベル，防具製作の必要レベル]`を返します．

## `Mgmg::TPolynomial`
前述の`String#poly`によって生成される二変数多項式のクラスです．最初のTはtwo-variableのTです．以下のようなメソッドが定義されています．

## `Mgmg::TPolynomial#to_s(fmt=nil)`
鍛冶・防具製作LvをS，道具製作LvをCとして，`self`を表す数式文字列を返します．係数`coeff`を文字列に変換する際，`fmt`の値に応じて次の方法を用います．

|`fmt`のクラス|変換法|
|:-|:-|
|`NilClass`|`coeff.to_s`|
|`String`|`fmt % [coeff]`|
|`Symbol`|`coeff.__send__(fmt)`|
|`Proc`|`fmt.call(coeff)`|

通常，係数は`Rational`であるため，`'%.2e'`などを指定するのがオススメです．

## `Mgmg::TPolynomial#inspect(fmt=->(r){"Rational(#{r.numerator}, #{r.denominator})"})`
`Mgmg::TPolynomial#to_s`と同様ですが，鍛冶・防具製作Lvを`s`，道具製作Lvを`c`としたRubyの式として解釈可能な文字列を返します．つまり，係数をリテラル，掛け算を`*`で表現しています．`fmt`は`Mgmg::TPolynomial#to_s`と同様で，適当な値を指定することでRuby以外の言語でも解釈可能になります．例えば，精度が問題でないならば，`'%e'`とすると，大抵の言語で解釈可能な文字列を生成できます．

## `Mgmg::TPolynomial#leading(fmt=nil)`
最高次係数を返します．`fmt`が`nil`なら数値(`Rational`)をそのまま，それ以外なら`Mgmg::TPolynomial#to_s`と同様の方式で文字列に変換して返します．ただし，レシピの段数に応じた最高次数を返すため，レシピ次第では本メソッドの返り値が`0`となり，それより低い次数の項が最高次となることもあり得ます．そのようなケースでの真の最高次の探索はしません．

## `Mgmg::TPolynomial#[](i, j)`
鍛冶・防具製作Lvをs，道具製作Lvをcとして，s<sup>i</sup>c<sup>j</sup> の係数を返します．負の値を指定すると，最高次から降順に数えた次数の項の係数を返します．例えば`i, j = -1, -1`なら，最高次の係数となります．引数が正で範囲外なら`0`を返し，負で範囲外なら`IndexError`を上げます．

## `Mgmg::TPolynomial#evaluate(smith, comp=smith)`
鍛冶・防具製作Lvを`smith`，道具製作Lvを`comp`として値を計算します．丸めを無視しているため，実際の合成結果以上の値が返ります．

## `Mgmg::TPolynomial#smith_fix(smith, fmt=nil)`
鍛冶・防具製作Lvを`smith`で固定し，道具製作Lvのみを変数とする多項式として，`to_s(fmt)`したような文字列を返します．

## `Mgmg::TPolynomial#scalar(value)`
多項式として`value`倍した式を返します．
alias として`*`があるほか`scalar(1.quo(value))`として`quo`，`/`，`scalar(1)`として`+@`，`scalar(-1)`として`-@`が定義されています．

## `Mgmg::TPolynomial#+(other)`, `Mgmg::TPolynomial#-(other)`
多項式として`self+other`または`self-other`を計算し，結果を返します．
`other`は`Mgmg::TPolynomial`であることが想定されており，スカラー値は使えません．

## `Mgmg::TPolynomial#partial_derivative(variable)`
多項式として偏微分し，その微分係数を返します．
`variable`はどの変数で偏微分するかを指定するもので，`"s"`なら鍛冶・防具製作Lv，`"c"`なら道具製作Lvで偏微分します．

## `Mgmg::TPolynomial#eff(smith, comp=smith)`
製作Lv(`smith`, `comp`)における鍛冶・防具製作Lv効率と道具製作Lv効率からなる配列を返します．
一方のみが欲しい場合，`Mgmg::TPolynomial#smith_eff(smith, comp=smith)`，`Mgmg::TPolynomial#smith_eff(smith, comp=smith)`が使えます．

## `Mgmg::IR`
前述の`String#ir`または`Enumerable#ir`によって生成される，9パラ値を計算するための，2変数または3変数の関数オブジェクトを保持するクラスです．`Mgmg::IR`では，`Mgmg::Equip`と異なり，重量，EL値，総消費エレメントを取り扱いません．

## `Mgmg::IR#to_s`
例えば，「斧(牙9皮9)+短剣(鉄9皮2)」のレシピに対して，
```ruby
"斧☆14(皮鉄)<攻撃:[110(s+170)/100]+[[[86(s+135)/100][(c+130)/2]/100]/100], 腕力:[14(s+170)/100]>"
```
のような文字列を返します．ここで，sは鍛冶Lv，sは道具製作Lvを表します．防具の場合，sの代わりに防具製作Lvを表すaが用いられます．「[]」は，0への丸めを意味し，掛け算記号は省略されています．

## `Mgmg::IR#attack, phydef, magdef, hp, mp, str, dex, speed, magic(s=nil, ac=s, x=nil)`
それぞれ
```
攻撃，物防，魔防，HP，MP，腕力，器用，素早さ，魔力
```
の値を計算する関数オブジェクトまたは計算した値を返します．与えた引数の数に応じて，

|引数の数|返り値|
|:-|:-|
|0|関数オブジェクト|
|1 または 2|`s`を鍛冶Lvまたは防具製作Lv，`ac`を道具製作Lvとして計算した値|
|3|`s`を鍛冶Lv，`ac`を防具製作Lv，`x`を道具製作Lvとして計算した値|

を返します．

## `Mgmg::IR#atkstr, atk_sd, dex_as, mag_das, magmag, pmdef(s, ac, x=nil)`
`Mgmg::Equip`における同名メソッドと同様に，9パラ値を組み合わせた値を計算して返します．9パラの単独値と異なり，引数の数は2または3でなくてはなりません．

## `Mgmg::IR#power, fpower(s, a=s, c=a.tap{a=s})`
`Mgmg::Equip`における同名メソッドと同様に，適当な値を自動選択して返します．引数は`Enumerable#build`と同様になっています．

## `Mgmg::IR#smith_cost, comp_cost(s, c=s, outsourcing=false)`
`Mgmg::Equip`における同名メソッドと同様に，鍛冶・防具製作コストまたは武具合成コストを計算して返します．複数装備では意味のある値を計算できないため，製作Lvの3種入力はできません．
