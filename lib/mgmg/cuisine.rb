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
		'焼き肉'           => Cuisine.new( Vec[ 5,  0, 0] ),
		'焼き金肉'         => Cuisine.new( Vec[10,  0, 0] ),
		'焼き黄金肉'       => Cuisine.new( Vec[15,  0, 0] ),
		'焼きリンゴ'       => Cuisine.new( Vec[ 0,  5, 0] ),
		'焼きイチゴ'       => Cuisine.new( Vec[ 0, 10, 0] ),
		'焼きネギタマ'     => Cuisine.new( Vec[ 0, 15, 0] ),
		'サボテン焼き1'    => Cuisine.new( Vec[ 5,  5, 0] ),
		'サボテンバーガー' => Cuisine.new( Vec[10, 10, 0] ),
		'サボテン焼き7'    => Cuisine.new( Vec[15, 15, 0] ),
	}
	
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
