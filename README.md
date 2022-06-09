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

あるいは，[Ajax版](http://cycloawaodorin.sakura.ne.jp/sonota/mgmg/mgmg.html) を利用することもできます．Ajax版は一部の機能しか実装されていませんが，Ruby環境がない場合にも利用できます．

## 使い方
並列型多段合成杖を製作し，標準出力に出力する．

```ruby
puts '[杖(水玉10火玉5)+本(骨10鉄1)]+[本(水玉5綿2)+杖(骨10鉄1)]'.build(112, 176)
#=> 杖4☆20(骨綿)[攻撃:119, MP:104, 魔力:1,859, EL:水2]
```

中間製作品の性能を確認する．

```ruby
puts '[杖(水玉10火玉5)+本(骨10鉄1)]+[本(水玉5綿2)+杖(骨10鉄1)]'.build(112, 176).history
#=> 杖1☆7(貴貴)[MP:15, 魔力:50, EL:水2]
#=> 本1☆5(骨鉄)[攻撃:44, 魔防:19, MP:20, 魔力:256]
#=> 杖2☆12(貴骨)[攻撃:56, MP:41, 魔力:650, EL:水2]
#=> 本1☆3(貴綿)[MP:8, 魔力:36]
#=> 杖1☆5(骨鉄)[攻撃:24, MP:32, 魔力:321]
#=> 本2☆8(綿骨)[攻撃:46, MP:35, 魔力:487]
#=> 杖4☆20(骨綿)[攻撃:119, MP:104, 魔力:1,859, EL:水2]
```

複数装備を製作し，そのすべてを装備した場合の合計値を標準出力に出力する．

```ruby
r = %w|本(金3骨1)+[弓(骨1綿1)+[杖(金3金3)+[弓(綿1綿1)+[杖(宝10金6)+本(骨9鉄2)]]]] フード(石10骨9) 首飾り(宝10水10) 指輪(木10金10)|
puts r.build(122, 139, 232)
#=> 複数装備9(武:1, 頭:1, 飾:2)[攻撃:15, 物防:34, 魔防:28, HP:241, MP:71, 器用:223, 素早:222, 魔力:6,604]
```

重量1または2で作るのに必要な防具製作Lvを確認する．

```ruby
p ['重鎧(皮10金10)'.min_level, '重鎧(皮10金10)'.min_level(2)]
#=> [162, 42]
```

合成レシピから必要製作Lvを確認する．
```ruby
p '[杖(水玉10火玉5)+本(骨10鉄1)]+[本(水玉5綿2)+杖(骨10鉄1)]'.min_levels
#=> {"杖(水玉10火玉5)"=>92, "本(骨10鉄1)"=>48, "本(水玉5綿2)"=>12, "杖(骨10鉄1)"=>28}
p '[杖(水玉10火玉5)+本(骨10鉄1)]+[本(水玉5綿2)+杖(骨10鉄1)]'.build.min_level
#=> 92
```

近似多項式を得る．

```ruby
puts '[斧(牙10金10)+剣(鉄10皮1)]+剣(鉄10皮1)'.poly(:attack).to_s('%.4g')
#=> (0.02588S+3.364)C+(4.677S+699.9)
```

既成品の性能を確認する．

```ruby
puts '小竜咆哮'.build
#=> 弓1☆10(木骨)[攻撃:50, 器用:120, 素早:50]
```

目標威力を最小のスキル経験値で達成する鍛冶Lvと道具製作Lvの組み合わせを探索し，必要な総経験値を確認する．

```ruby
r = '双短剣(金3皮1)+[杖(鉄2綿1)+[斧(玉5鉄1)+[杖(綿1綿1)+[斧(玉5金3)+[剣(金3牙1)+[斧(木2牙1)+[剣(木2牙1)+双短剣(鉄10木1)]]]]]]]'
sc = r.search(:atk_sd, 1_000_000)
p [sc, Mgmg.exp(*sc)]
#=> [[155, 376], 304969]
```

探索の際，スキル及び料理を考慮する．

```ruby
r = '重鎧(皮2綿1)+[帽子(宝1宝1)+[重鎧(玉5金3)+[帽子(宝1宝1)+[重鎧(玉5金6)+[軽鎧(金3骨1)+[重鎧(皮2骨1)+軽鎧(鉄10綿1)]]]]]]'
sc = r.search(:phydef, 100_000, reinforcement: ['物防御UP', 'アースドランと氷河酒の蒸し焼き', 'ガードアップ'])
p [sc, Mgmg.exp(*sc)]
#=> [[120, 264], 152502]
```


各メソッドの詳しい説明等は [リファレンス](./reference.md) を参照されたい．

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

## 謝辞
面白いゲームを作ってくださった耕様および，高精度なシミュレータを作製し，本ライブラリの作製を可能とした，Excel版装備計算機の作者様に感謝いたします．

## Contributing
バグ報告等は https://github.com/cycloawaodorin/mgmg/issues にて．
