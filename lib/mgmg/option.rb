module Mgmg
	class Option
		Defaults = {
			left_associative: true, include_system_equips: true,
			smith_max: 10000, armor_max: 10000, comp_max: 10000
		}
		def initialize(
			left_associative: Defaults[:left_associative],
			smith_min: nil, armor_min:nil, comp_min: nil, smith_max: Defaults[:smith_max], armor_max: Defaults[:armor_max], comp_max: Defaults[:comp_max],
			step: 1, magdef_maximize: true,
			target_weight: 0, reinforcement: [], buff: nil,
			irep: nil, cut_exp: Float::INFINITY,
			include_system_equips: Defaults[:include_system_equips]
		)
			@left_associative = left_associative
			@smith_min = smith_min
			@armor_min = armor_min
			@comp_min = comp_min
			@smith_max = smith_max
			@armor_max = armor_max
			@comp_max = comp_max
			@step = step
			@magdef_maximize = magdef_maximize
			@target_weight = target_weight
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
			@include_system_equips = include_system_equips
		end
		attr_accessor :left_associative, :smith_min, :armor_min, :comp_min, :smith_max, :armor_max, :comp_max
		attr_accessor :step, :magdef_maximize, :target_weight, :reinforcement, :irep, :cut_exp, :include_system_equips
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
			@target_weight = other.target_weight
			@reinforcement = other.reinforcement.dup
			@irep = other.irep
			@cut_exp = other.cut_exp
			@include_system_equips = other.include_system_equips
		end
		def update_sa_min(recipe, force=true)
			case recipe
			when String
				if @smith_min.nil? && @armor_min
					@smith_min = @armor_min
				end
				if force || @smith_min.nil?
					s = recipe.min_level(@target_weight, opt: self)
					@smith_min = s if force || @smith_min.nil?
					@armor_min = s if force || @armor_min.nil?
				end
			when Enumerable
				if force || @smith_min.nil? || @armor_min.nil?
					@target_weight = [@target_weight, @target_weight] if @target_weight.kind_of? Numeric
					s, a = recipe.min_level(*@target_weight, opt: self)
					@smith_min = s if force || @smith_min.nil?
					@armor_min = a if force || @armor_min.nil?
				end
			else
				raise ArgumentError, 'recipe should be String or Enumerable'
			end
			self
		end
		def set_default(recipe, force: false)
			if @include_system_equips
				case recipe
				when String
					@include_system_equips = false unless Mgmg::SystemEquipRegexp.values.any?{|re| re.match(recipe)}
				when Enumerable
					@include_system_equips = false unless recipe.any?{|str| Mgmg::SystemEquipRegexp.values.any?{|re| re.match(str)}}
				else
					raise ArgumentError, 'recipe should be String or Enumerable'
				end
			end
			update_sa_min(recipe, force)
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
	
	module_function def option(recipe=nil, **kw)
		ret = Option.new(**kw)
		ret.set_default(recipe) unless recipe.nil?
		ret
	end
end
