module Mgmg
	class Reinforcement
		def initialize(vec)
			@vec = vec
		end
		attr_accessor :vec
		def initialize_copy(other)
			@vec = other.vec
		end
	end
	
	#                                               攻  物  防  HP  MP  腕  器  速  魔
	Skill = {
		'物防御UP'       => Reinforcement.new( Vec[  0, 10,  0,  0,  0,  0,  0,  0,  0] ),
		'魔防御UP'       => Reinforcement.new( Vec[  0,  0, 10,  0,  0,  0,  0,  0,  0] ),
		'腕力UP'         => Reinforcement.new( Vec[  0,  0,  0,  0,  0, 10,  0,  0,  0] ),
		'メンテナンス'   => Reinforcement.new( Vec[ 50,  0,  0,  0,  0,  0,  0,  0,  0] ),
		'ガードアップ'   => Reinforcement.new( Vec[  0, 50,  0,  0,  0,  0,  0,  0,  0] ),
		'パワーアップ'   => Reinforcement.new( Vec[  0,  0,  0,  0,  0, 50,  0,  0,  0] ),
		'デックスアップ' => Reinforcement.new( Vec[  0,  0,  0,  0,  0,  0, 50,  0,  0] ),
		'スピードアップ' => Reinforcement.new( Vec[  0,  0,  0,  0,  0,  0,  0, 50,  0] ),
		'マジックアップ' => Reinforcement.new( Vec[  0,  0,  0,  0,  0,  0,  0,  0, 50] ),
		'オールアップ'   => Reinforcement.new( Vec[  0, 50,  0,  0,  0, 50, 50, 50, 50] ),
	}
	
	class << Reinforcement
		def cuisine(c)
			Reinforcement.new( Vec[*(c.vec), *Array.new(6, 0)] )
		end
	end
	
	class Equip
		def reinforce(*arg)
			arg.each do |r|
				r = case r
				when Reinforcement
					r
				when Cuisine
					Reinforcement.cuisine(r)
				when String
					Skill[r] or raise ArgumentError, "Unknown skill `#{r}' is given."
				else
					raise ArgumentError, "The argument should be Mgmg::Cuisine or skill name String. (`#{r.class}' is given)"
				end
				@para.map!.with_index do |pr, i|
					if r.vec[i] == 0
						pr
					else
						pr * (100+r.vec[i]).quo(100)
					end
				end
			end
			self
		end
	end
end
