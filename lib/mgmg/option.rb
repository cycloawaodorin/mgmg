module Mgmg
	class Option
		def initialize(
			recipe=nil, left_associative: true,
			smith_min: nil, armor_min:nil, comp_min: nil, smith_max: 10000, armor_max: 10000, comp_max: 10000,
			step: 1, magdef_maximize: true,
			min_smith: false, reinforcement: [], buff: nil
		)
			@left_associative = left_associative
			@smith_min = smith_min
			@armor_min = armor_min
			@comp_min = comp_min
			@smith_max = smith_max
			@armor_max = armor_max
			@comp_max = comp_max
			@min_smith = min_smith
			@step = step
			@magdef_maximize = magdef_maximize
			@reinforcement = reinforcement
			unless buff.nil?
				if @reinforcement.empty?
					@reinforcement = buff
				else
					raise ArgumentError, "reinforcement and buff are exclusive"
				end
			end
			set_default(recipe) unless recipe.nil?
		end
		attr_accessor :left_associative, :smith_min, :armor_min, :comp_min, :smith_max, :armor_max, :comp_max
		attr_accessor :step, :magdef_maximize, :min_smith, :reinforcement
		def initialize_copy(other)
			@left_associative = other.left_associative
			@smith_min = other.smith_min
			@armor_min = other.armor_min
			@comp_min = other.comp_min
			@smith_max = other.smith_max
			@armor_max = other.armor_max
			@comp_max = other.comp_max
			@step = other.step
			@magdef_maximize = other.magdef_maximize
			@min_smith = other.min_smith
			@reinforcement = other.reinforcement.dup
		end
		def set_default(recipe, force: false)
			case recipe
			when String
				s = @min_smith ? recipe.min_smith(opt: self) : recipe.build(opt: self).min_level
				@smith_min = s if force or @smith_min.nil?
				@armor_min = s if force or @armor_min.nil?
			when Enumerable
				s, a = recipe.min_smith(opt: self)
				@smith_min = s if force or @smith_min.nil?
				@armor_min = a if force or @armor_min.nil?
			else
				raise ArgumentError, 'recipe should be String or Enumerable'
			end
			@comp_min = str.min_comp(opt: self) if force or @comp_min.nil?
			self
		end
		def buff
			@reinforcement
		end
		def buff=(v)
			@reinforcement = v
		end
	end
end
