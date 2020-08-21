# Mgmg
This gem is a tool for a game in Japanese language, therefore the following are described in Japanese. English is not supported.

## これは何？
mgmgは耕氏の [巡り廻る](http://rebellionrpg.blog80.fc2.com/) の武器・防具の製作及び合成のシミュレーションを行うRubyのGemです．原作(ゲーム)を解析したわけではなく，攻略Wiki上で公開されている [巡り廻る装備計算機(ver0.99.06).xls](https://wikiwiki.jp/guruguru/%E8%A3%85%E5%82%99%E5%93%81%E5%90%88%E6%88%90#n07db4f5) の計算をRuby上で行います．基本的に同じ計算をしていますが，数学的な同値変換(量子化誤差の配慮なし)を行っている他，Excel版が浮動小数点数演算を行っているのに対して，本ライブラリでは整数演算で完結しています．これらの違いの他，バグによって結果が変わる可能性があります．

## 特徴
後述の`String#build`によってレシピ文字列から直接計算できる点が一番の押しです．Excel版に比べ，レシピの試行錯誤を(計算能力ではなく，入力の容易さの意味で)高速に処理できると思います．製作Lvを変化させたときのグラフを生成するなども容易にできます．また，ごく一部(キャラクリ初期装備)を除く全ての既成品に対応しています．

## 制限
Excel版に比べ，入力のチェックがなされておらず，☆制限の違反等を明示的には示しません．
メイン機能である`String#build`では，材料ごとに異なる製作Lvで製作した場合をシミュレートできません．本ライブラリのメソッドを組み合わせて用いると対応できますが，面倒くさいのでその方法は解説しません．

また，実機とは異なる結果が得られる場合があることがわかっています．防具製作Lv139，道具製作Lv234において
```
指輪(木10金3)+[手袋(金3石1)+指輪(木10皮1)]
```
を実機(ver1.19)で製作すると器用603になりますが，Excel版，本ライブラリともに器用604と計算されます．

## インストール
下記でインストールします．

    $ gem install mgmg

あるいは，http://cycloawaodorin.sakura.ne.jp/sonota/mgmg/mgmg.html にてAjax版を利用することもできます．Ajax版は一部の機能しか実装されていませんが，Ruby環境がない場合にも利用できます．

## 使い方
並列型多段合成杖を製作し，標準出力に出力．

```ruby
puts '[杖(水玉10火玉5)+本(骨10鉄1)]+[本(水玉5綿2)+杖(骨10鉄1)]'.build(112, 176)
#=> 杖4☆20(骨綿)[攻撃:119, MP:104, 魔力:1,859, EL:水2]
```

複数装備を製作し，そのすべてを装備した場合の合計値を標準出力に出力．

```ruby
puts %w|本(金3骨1)+[弓(骨1綿1)+[杖(金3金3)+[弓(綿1綿1)+[杖(宝10金6)+本(骨9鉄2)]]]] フード(石10骨9) 首飾り(宝10水10) 指輪(木10金10)|.build(122, 139, 232)
#=> 複数装備9(武:1, 頭:1, 飾:2)[攻撃:15, 物防:34, 魔防:28, HP:241, MP:71, 器用:223, 素早:222, 魔力:6,604]
```

重量1または2で作るのに必要な防具製作Lvを確認する．

```ruby
p ['重鎧(皮10金10)'.min_level, '重鎧(皮10金10)'.min_level(2)]
#=> [162, 42]
```

近似多項式を得る．

```ruby
puts '[斧(牙10金10)+剣(鉄10皮1)]+剣(鉄10皮1)'.poly(:attack).to_s('%.4g')
#=> (0.02588S+3.364)C+(4.677S+699.9)
```

既成品の性能を確認．

```ruby
puts '小竜咆哮'.build(-1)
#=> 弓1☆10(木骨)[攻撃:50, 器用:120, 素早:50]
```

### 表記ゆれについて
本ゲームでは，装備種別の名称に，下記の表のような表記ゆれが存在します．

|劣悪|店売り・歴戦|製作選択肢ver1.21|製作品ver1.21|製作選択肢ver1.22β37|製作品ver1.22β37|
|:-|:-|:-|:-|:-|:-|
|弩|弩|弩|ボウガン|弩|弩|
|ローブ|法衣|ローブ|ローブ|法衣|法衣|
|-|手袋|グローブ|グローブ|手袋|手袋|
|-|脛当て|すね当て|脛当て|すね当て|脛当て|

本ライブラリでは，既成品，製作品ともにこれらの表記を同一視し，いずれを用いたレシピも処理できるようにしています．
「ボウガン」の一般的な表記ゆれである「ボーガン」も受け付けています．

「正式な装備種別名」は「製作品ver1.22β37」が妥当であろうと考え，`Mgmg::Equip#to_s`などではこれを用いるようにしています．

## リファレンス
本ライブラリで定義される主要なメソッドを以下に解説します．

### `String#build(smith, comp=smith, left_associative: true)`
レシピ文字列である`self`を解釈し，鍛冶・防具製作Lvを`smith`，道具製作Lvを`comp`として鍛冶・防具製作及び武器・防具合成を行った結果を後述の`Mgmg::Equip`クラスのインスタンスとして生成し，返します．例えば，
```ruby
'[杖(水玉10火玉5)+本(骨10鉄1)]+[本(水玉5綿2)+杖(骨10鉄1)]'.build(112, 176)
```
のようにします．基本的に`[]`による合成順序の指定が必要ですが，不確定の場合，`left_associative`が真なら左結合，偽なら右結合として解釈します．
```ruby
'ローブ(綿10皮10)+歴戦の服'
```
のように，既成品を含む合成レシピも解釈します．キャラクリ初期装備の劣悪な服，劣悪な小手以外のあらゆる装備を網羅しています．劣悪な服，劣悪な小手はキャラクリ以外での初期装備品として解釈します．`comp`を省略した場合，`smith`と同じ値として処理します．

`self`が解釈不能な場合，例外が発生します．また，製作Lvや完成品の☆制限のチェックを行っていないほか，本ライブラリでは`武器+防具`や`防具+武器`の合成も可能になっています．街の鍛冶・防具製作・道具製作屋に任せた場合をシミュレートする場合は製作Lvを負の値(`-1`など，負であれば何でもよい)にします(製作Lv0相当の性能を計算し，消費エレメント量は委託仕様となります)．

### `String#min_level(weight=1)`
`self`を`weight`以下で作るための最低製作Lvを返します．`build`と異なり，合成や既成品は解釈できません．また，素材の☆による最低製作Lvとのmaxを返すため，街の鍛冶・防具製作屋に頼んだ場合の重量は`self.build(-1).weight`で確認する必要があります．`weight`を省略した場合，重量1となる製作Lvを返します．

### `Enumerable#build(smith, armor=smith, comp=armor.tap{armor=smith}, left_associative: true)`
複数のレシピ文字列からなる`self`の各要素を製作し，そのすべてを装備したときの`Mgmg::Equip`を返します．製作では`鍛冶Lv=smith`, `防具製作Lv=armor`, `道具製作Lv=comp`とします．1つしか指定しなければすべてそのLv，2つなら1つ目を`smith=armor`，2つ目を`comp`に，3つならそれぞれの値とします．`left_associative`はそのまま`String#build`に渡されます．製作Lvが負の場合，製作Lv0として計算した上で，消費エレメント量は街の製作屋に頼んだ場合の値を計算します．武器複数など，同時装備が不可能な場合でも，特にチェックはされません．

### `String#poly(para, left_associative: true)`
レシピ文字列である`self`を解釈し，`para`で指定した9パラ値について，丸めを無視した鍛冶・防具製作Lvと道具製作Lvの2変数からなる多項式関数を示す`Mgmg::TPolynomial`クラスのインスタンスを生成し，返します．`para`は次のシンボルのいずれかを指定します．
```ruby
:attack, :phydef, :magdef, :hp, :mp, :str, :dex, :speed, :magic
```
これらは，`Mgmg::Equip`から当該属性値を取得するためのメソッド名と同一です．`left_associative`は`String#build`の場合と同様です．

`para`として，複数の9パラ値を組み合わせた以下のシンボルを指定することもできます．
```ruby
:atkstr, :atk_sd, :dex_as, :mag_das, :magmag
```
これらは同名のメソッドと異なり，本来の威力値等に関する近似多項式を返し，4倍化や2倍化はされていません．また，自動選択の`:power`は指定できません．

また，`:cost`を渡すことで，消費エレメント量に関する近似多項式を得られます．`self`に`"+"`が含まれていれば合成品とみなし，最後の合成に必要な地エレメント量を，それ以外では，武器なら消費火エレメント量を，防具なら消費水エレメント量を返します．ただし，`self`が既成品そのものの場合，零多項式を返します．

### `Mgmg::Equip`
前述の`String#build`によって生成される装備品のクラスです．複数装備の合計値を表す「複数装備」という種別の装備品の場合もあります．以下のようなインスタンスメソッドが定義されています．

### `Mgmg::Equip#to_s`
```ruby
"杖4☆20(骨綿)[攻撃:119, MP:104, 魔力:1,859, EL:水2]"
```
のような，わかりやすい形式の文字列に変換します．上の例で「4」は重量，「骨」は主材質，「綿」は副材質を表します．各種数値が必要な場合は次以降に説明するメソッドをご利用ください．複数装備の場合は以下のような文字列になります．
```ruby
"複数装備9(武:1, 頭:1, 飾:2)[攻撃:15, 物防:34, 魔防:28, HP:241, MP:71, 器用:223, 素早:222, 魔力:6,604]"
```
「9」は合計重量，(武:1, 頭:1, 飾:2)は武器を1つ，頭防具を1つ，装飾品を2つ装備していることを示します．装備している場合は「胴」「腕」「足」も記述されます．

### `Mgmg::Equip#inspect`
`Mgmg::Equip#to_s`の出力に加え，0となる9パラ値を省略せず，総消費エレメント量を連結した文字列を出力します．すなわち，
```ruby
"杖4☆20(骨綿)[攻撃:119, 物防:0, 魔防:0, HP:0, MP:104, 腕力:0, 器用:0, 素早:0, 魔力:1859, EL:火0地0水2]<コスト:火491地3150水0>"
```
のような文字列を返します．

### `Mgmg::Equip#weight, star`
それぞれ重量，☆数を整数値で返します．「複数装備」の場合，`weight`は総重量，`star`は装備数に関する値が返ります．

### `Mgmg::Equip#total_cost`
製作に必要な総エレメント量を，火，地，水の順のベクトルとして返します．ケージの十分性の確認には，下記の`comp_cost`を用います．

### `Mgmg::Equip#attack, phydef, magdef, hp, mp, str, dex, speed, magic, fire, earth, water`
それぞれ
```
攻撃，物防，魔防，HP，MP，腕力，器用，素早さ，魔力，火EL，地EL，水EL
```
の値を`Integer`で返します．

### `Mgmg::Equip#power`
武器種別ごとに適した威力計算値の4倍の値を返します．具体的には以下の値です．

|武器種別|威力計算値の4倍|
|:-|:-|
|短剣，双短剣|攻撃x4+腕力x2+器用x2|
|剣，斧|攻撃x4+腕力x4|
|弓|max(器用x4+攻撃x2+腕力x2, 魔力x4+器用x2+攻撃+腕力)|
|弩|器用x4+攻撃x2+腕力x2|
|杖，本|max(魔力x8，攻撃x4+腕力x4)|

弓，杖，本では`self`の性能から用途を判別し，高威力となるものの値を返します．防具に対してこのメソッドを呼び出すと，9パラメータのうち最も高い値を返します．

防具の場合，9パラメータのうち，最大のものの2倍の値を返します．ただし，最大の値に魔防が含まれている場合，代わりに「魔防x2+魔力」を返します．

複数装備の場合，9パラメータの合計値の4倍を返します．ただし，HPとMPは4倍にしません．HPとMPの特例は，消費エレメント量の計算と同様とするものです．

いずれの場合も，EL値，重量，☆は無視されます．

### `Mgmg::Equip#fpower`
武器または複数装備の場合，`Mgmg::Equip#power.fdiv(4)`を返します．防具の場合，`Mgmg::Equip#power.fdiv(2)`を返します．

### `Mgmg::Equip#atkstr, atk_sd, dex_as, mag_das`
それぞれ
```
攻撃+腕力，攻撃x2+腕力+器用，器用x2+攻撃+腕力，魔力x4+器用x2+攻撃+腕力
```
の値を返します．これらはそれぞれ
```
(剣，斧，杖，本)，(短剣，双短剣)，(弓，弩)，(バスターアロー)
```
の威力の定数倍の値です．トリックプレーやディバイドには対応していません．

### `Mgmg::Equip#magmag`
「魔防x2+魔力」の値を返します．魔力の半分が魔防に加算されることから，実際の魔防性能に比例した値となります．

### `Mgmg::Equip#comp_cost(outsourcing=false)`
`self`が合成によって作られたものだとした場合の消費地エレメント量を返します．地ケージ確保のための確認用途が多いと思うので短い`cost`をエイリアスとしています．`outsourcing`が真の場合，街の道具製作屋に頼んだ場合のコストを返します．

### `Mgmg::Equip#smith_cost(outsourcing=false)`
`self`が鍛冶・防具製作によって作られたものだったものだとした場合の消費火・水エレメント量を返します．`outscourcing`が真の場合，街の鍛冶屋・防具製作屋に頼んだ場合のコストを返します．

### `Mgmg::Equip#+(other)`
`self`と`other`を装備した「複数装備」の`Mgmg::Equip`を返します．`self`と`other`はいずれも単品でも「複数装備」でも構いません．武器複数などの装備可否チェックはされません．

### `Mgmg::Equip#history`
多段階の合成におけるすべての中間生成物からなる配列を返します．
「複数装備」の場合，各装備の`history`を連結した配列を返します．

### `Mgmg::Equip#min_levels`
レシピ中の，鍛冶・防具製作物の文字列をキー，重量1で生成するのに必要な最小レベルを値とした`Hash`を返します．
「複数装備」の場合，各装備の`min_levels`をマージした`Hash`を返します．

### `Mgmg::Equip#min_level`
`min_levels`の値の最大値を返します．「複数装備」の場合，`[鍛冶の必要レベル，防具製作の必要レベル]`を返します．

### `Mgmg::TPolynomial`
前述の`String#poly`によって生成される二変数多項式のクラスです．最初のTはtwo-variableのTです．以下のようなメソッドが定義されています．

### `Mgmg::TPolynomial#to_s(fmt=nil)`
鍛冶・防具製作LvをS，道具製作LvをCとして，`self`を表す数式文字列を返します．係数`coeff`を文字列に変換する際，`fmt`の値に応じて次の方法を用います．

|`fmt`のクラス|変換法|
|:-|:-|
|`NilClass`|`coeff.to_s`|
|`String`|`fmt % [coeff]`|
|`Symbol`|`coeff.__send__(fmt)`|
|`Proc`|`fmt.call(coeff)`|

通常，係数は`Rational`であるため，`'%.2e'`などを指定するのがオススメです．

### `Mgmg::TPolynomial#inspect(fmt=->(r){"Rational(#{r.numerator}, #{r.denominator})"})`
`Mgmg::TPolynomial#to_s`と同様ですが，鍛冶・防具製作Lvを`s`，道具製作Lvを`c`としたRubyの式として解釈可能な文字列を返します．つまり，係数をリテラル，掛け算を`*`で表現しています．`fmt`は`Mgmg::TPolynomial#to_s`と同様で，適当な値を指定することでRuby以外の言語でも解釈可能になります．例えば，精度が問題でないならば，`'%e'`とすると，大抵の言語で解釈可能な文字列を生成できます．

### `Mgmg::TPolynomial#[](i, j)`
鍛冶・防具製作LvをS，道具製作LvをCとして，S<sup>i</sup>C<sup>j</sup> の係数を返します．負の値を指定すると，最高次から降順に数えた次数の項の係数を返します．例えば`i, j = -1, -1`なら，最高次の係数となります．引数が正で範囲外なら`0`を返し，負で範囲外なら`IndexError`を上げます．

### `Mgmg::TPolynomial#evaluate(smith, comp=smith)`
鍛冶・防具製作Lvを`smith`，道具製作Lvを`comp`として値を計算します．丸めを無視しているため，実際の合成結果以上の値が返ります．

### `Mgmg::TPolynomial#smith_fix(smith, fmt=nil)`
鍛冶・防具製作Lvを`smith`で固定し，道具製作Lvのみを変数とする多項式として，`to_s(fmt)`したような文字列を返します．

### `Mgmg::TPolynomial#scalar(value)`
多項式として`value`倍した式を返します．
alias として`*`があるほか`scalar(1.quo(value))`として`quo`，`/`，`scalar(1)`として`+@`，`scalar(-1)`として`-@`が定義されています．

### `Mgmg::TPolynomial#+(other)`, `Mgmg::TPolynomial#-(other)`
多項式として`self+other`または`self-other`を計算し，結果を返します．
`other`は`Mgmg::TPolynomial`であることが想定されており，スカラー値は使えません．

### `Mgmg::TPolynomial#partial_derivative(variable)`
多項式として偏微分し，その微分係数を返します．
`variable`はどの変数で偏微分するかを指定するもので，`"s"`なら鍛冶・防具製作Lv，`"c"`なら道具製作Lvで偏微分します．

## 謝辞
面白いゲームを作ってくださった耕様および，高精度なシミュレータを作製し，本ライブラリの作製を可能とした，Excel版装備計算機の作者様に感謝いたします．

## Contributing
バグ報告等は https://github.com/cycloawaodorin/mgmg/issues にて．
