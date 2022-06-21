module Mgmg
	module_function def option(recipe=nil, **kw)
		ret = Option.new(**kw)
		ret.set_default(recipe) unless recipe.nil?
		ret
	end
	class Option
		def initialize(
			left_associative: true,
			smith_min: nil, armor_min:nil, comp_min: nil, smith_max: 10000, armor_max: 10000, comp_max: 10000,
			step: 1, magdef_maximize: true,
			min_smith: false, reinforcement: [], buff: nil,
			irep: nil, cut_exp: Float::INFINITY
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
			@irep = irep
			@cut_exp = cut_exp
		end
		attr_accessor :left_associative, :smith_min, :armor_min, :comp_min, :smith_max, :armor_max, :comp_max
		attr_accessor :step, :magdef_maximize, :min_smith, :reinforcement, :irep, :cut_exp
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
			@irep = other.irep
			@cut_exp = other.cut_exp
		end
		def set_default(recipe, force: false)
			case recipe
			when String
				if force || @smith_min.nil? || @armor_min.nil?
					s = @min_smith ? recipe.min_smith(opt: self) : recipe.build(opt: self).min_level
					@smith_min = s if force || @smith_min.nil?
					@armor_min = s if force || @armor_min.nil?
				end
			when Enumerable
				if force || @smith_min.nil? || @armor_min.nil?
					if @min_smith
						s, a = recipe.min_smith(opt: self)
					else
						s, a = recipe.build(opt: self).min_level
					end
					@smith_min = s if force || @smith_min.nil?
					@armor_min = a if force || @armor_min.nil?
				end
			else
				raise ArgumentError, 'recipe should be String or Enumerable'
			end
			@comp_min = recipe.min_comp(opt: self) if force || @comp_min.nil?
			@irep = recipe.ir(opt: self) if force || @irep.nil?
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
