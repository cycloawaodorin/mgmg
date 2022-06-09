module Mgmg
	using Refiner
	class Cuisine
		def initialize(vec)
			@vec = vec
		end
		attr_accessor :vec
		def initialize_copy(other)
			@vec = other.vec.dup
		end
		
		def attack
			@vec[0]
		end
		def phydef
			@vec[1]
		end
		def magdef
			@vec[2]
		end
		def to_s
			"料理[攻撃:#{self.attack}, 物防:#{self.phydef}, 魔防:#{self.magdef}]"
		end
		alias :inspect :to_s
	end
	
	SystemCuisine = {
		'焼き肉'                         => Cuisine.new( Vec[ 5,  0,  0] ), # ☆1
		'焼き金肉'                       => Cuisine.new( Vec[10,  0,  0] ), # ☆3
		'焼き黄金肉'                     => Cuisine.new( Vec[15,  0,  0] ), # ☆5
		'焼きリンゴ'                     => Cuisine.new( Vec[ 0,  5,  0] ), # ☆1
		'焼きイチゴ'                     => Cuisine.new( Vec[ 0, 10,  0] ), # ☆3
		'焼きネギタマ'                   => Cuisine.new( Vec[ 0, 15,  0] ), # ☆5
		'サボテン焼き1'                  => Cuisine.new( Vec[ 5,  5,  0] ), # ☆1
		'サボテンバーガー'               => Cuisine.new( Vec[10, 10,  0] ), # ☆3
		'サボテン焼き7'                  => Cuisine.new( Vec[15, 15,  0] ), # ☆7
		'獣肉とカエン酒の丸焼き'         => Cuisine.new( Vec[ 8,  0,  0] ), # 料理Lv0
		'ドランギョと煉獄酒の丸焼き'     => Cuisine.new( Vec[15, 11,  6] ), # 料理Lv15
		'ドラバーンと煉獄酒の丸焼き'     => Cuisine.new( Vec[23, 17,  9] ), # 料理Lv24
		'フレドランと煉獄酒の丸焼き'     => Cuisine.new( Vec[59,  0,  0] ), # 料理Lv27
		'ダークドンと煉獄酒の丸焼き'     => Cuisine.new( Vec[35, 26, 21] ), # 料理Lv27
		'ダークドンと氷河酒の丸焼き'     => Cuisine.new( Vec[26, 35, 15] ), # 料理Lv27
		'ウッチと氷酒の蒸し焼き'         => Cuisine.new( Vec[ 0, 11, 10] ), # 料理Lv0
		'ゴッチと氷酒の蒸し焼き'         => Cuisine.new( Vec[ 0, 15, 13] ), # 料理Lv3
		'ガガッチと氷水酒の蒸し焼き'     => Cuisine.new( Vec[ 0, 19, 15] ), # 料理Lv6
		'ガガッチと氷河酒の蒸し焼き'     => Cuisine.new( Vec[ 0, 22, 16] ), # 料理Lv12
		'ドランギョと氷河酒の蒸し焼き'   => Cuisine.new( Vec[ 6, 24, 11] ), # 料理Lv15
		'ドラバーンと氷河酒の蒸し焼き'   => Cuisine.new( Vec[10, 35, 19] ), # 料理Lv24
		'アースドランと氷河酒の蒸し焼き' => Cuisine.new( Vec[ 0, 87,  0] ), # 料理Lv27
		'ダークドンと氷河酒の蒸し焼き'   => Cuisine.new( Vec[15, 52, 38] ), # 料理Lv27
		'ダークドンと煉獄酒の蒸し焼き'   => Cuisine.new( Vec[15, 52, 38] ), # 料理Lv27
		'ウッチとカエン酒の蒸し焼き'     => Cuisine.new( Vec[ 0, 10, 11] ), # 料理Lv0
		'ゴッチとカエン酒の蒸し焼き'     => Cuisine.new( Vec[ 0, 13, 15] ), # 料理Lv3
		'ガガッチと爆炎酒の蒸し焼き'     => Cuisine.new( Vec[ 0, 15, 19] ), # 料理Lv6
		'ガガッチと煉獄酒の蒸し焼き'     => Cuisine.new( Vec[ 0, 16, 22] ), # 料理Lv12
		'ドランギョと煉獄酒の蒸し焼き'   => Cuisine.new( Vec[ 9, 18, 15] ), # 料理Lv15
		'ドラバーンと煉獄酒の蒸し焼き'   => Cuisine.new( Vec[14, 26, 25] ), # 料理Lv24
		'アクアドランと煉獄酒の蒸し焼き' => Cuisine.new( Vec[ 0,  0, 87] ), # 料理Lv27
	}
	SystemCuisine.keys.each do |k|
		ary = k.scan(%r|(.+)と(.+)の(.+)|)[0]
		if ary
			c = case ary[2]
			when '丸焼き'
				'焼き'
			when '蒸し焼き'
				'蒸し'
			else
				raise UnexpectedError
			end
			SystemCuisine.store("#{ary[0]}の#{ary[1]}#{c}", SystemCuisine[k])
		end
	end
	
	MainFood = {
		'獣肉'         => Vec[10,  0,  0],
		'ウッチ'       => Vec[ 0, 10, 10],
		'ゴッチ'       => Vec[ 0, 12, 12],
		'ガガッチ'     => Vec[ 0, 14, 14],
		'ドランギョ'   => Vec[15, 15, 10],
		'ドラバーン'   => Vec[20, 20, 15],
		'フレドラン'   => Vec[50,  0,  0],
		'アースドラン' => Vec[ 0, 50,  0],
		'アクアドラン' => Vec[ 0,  0, 50],
		'ダークドン'   => Vec[30, 30, 30],
	}
	SubFood = {
		'氷酒'     => Vec[ 50,  70,  50],
		'氷水酒'   => Vec[ 50,  90,  50],
		'氷河酒'   => Vec[ 50, 110,  50],
		'カエン酒' => Vec[ 70,  50,  70],
		'爆炎酒'   => Vec[ 90,  50,  90],
		'煉獄酒'   => Vec[110,  50, 110],
	}
	Cookery = {
		'焼き' => Vec[50, 50, 30],
		'蒸す' => Vec[30, 75, 75],
	}
	Cookery.store('丸焼き', Cookery['焼き'])
	Cookery.store('すき焼き', Cookery['焼き'])
	Cookery.store('焼く', Cookery['焼き'])
	Cookery.store('焼', Cookery['焼き'])
	Cookery.store('蒸し焼き', Cookery['蒸す'])
	Cookery.store('ボイル', Cookery['蒸す'])
	Cookery.store('蒸し', Cookery['蒸す'])
	Cookery.store('蒸', Cookery['蒸す'])
	
	class << Cuisine
		def cook(cookery_s, main_s, sub_s, level)
			begin
				c = Cookery[cookery_s]
				m = MainFood[main_s]
				s = SubFood[sub_s]
				v = Vec[1, 1, 1]
				v.e_mul!(m).e_mul!(c).e_mul!(s.dup.add!(100+level)).e_div!(10000)
				new(v)
			rescue
				arg = [cookery_s, main_s, sub_s, level].inspect
				raise ArgumentError, "Some of arguments for cooking seems to be wrong. #{arg} is given, but they should be [cookery (String), main food (String), sub food (String), cooking level (Integer)]. Not all of cookeries and foods are supported."
			end
		end
	end
	
	module_function def cuisine(*arg)
		case arg.size
		when 3
			if arg.all?{ |e| e.kind_of?(Integer) } then
				Cuisine.new( Vec[*arg] )
			else
				raise ArgumentError, "All the cuisine parameters must be Integer."
			end
		when 1
			SystemCuisine[arg[0]] or raise ArgumentError, "The cuisine name `#{arg[0]}' is not supported."
		when 4
			Cuisine.cook(*arg)
		else
			raise ArgumentError, 'The number of argument must be 1, 3 or 4.'
		end
	end
end
