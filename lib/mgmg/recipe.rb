module Mgmg
	class Recipe
		def initialize(recipe, para=:power, **kw)
			@recipe = recipe
			@recipe.each(&:freeze) if @recipe.kind_of?(Enumerable)
			@recipe.freeze
			@para = para
			@option = Option.new(**kw).set_default(@recipe)
		end
		attr_reader :recipe
		attr_accessor :para
		def initialize_copy(other)
			@recipe = other.recipe.dup
			@option = other.option.dup
		end
		private def temp_opt(**kw)
			if kw.empty?
				@option
			else
				ret = @option.dup
				kw.each do |key, value|
					ret.method((key.to_s+'=').to_sym).call(value)
					ret.update_sa_min(@recipe) if key == :target_weight
					ret.irep.add_reinforcement(value) if key == :reinforcement || key == :buff
					if key == :left_associative
						ret.irep = @recipe.ir(opt: ret).add_reinforcement(ret.reinforcement)
					end
				end
				ret
			end
		end
		def option(**kw)
			@option = temp_opt(*kw)
			@option
		end
		def option=(new_option)
			@option = new_option.set_default(@recipe)
		end
		def replace(new_recipe, para: @para, **kw)
			@recipe = new_recipe
			@recipe.each(&:freeze) if @recipe.kind_of?(Enumerable)
			@recipe.freeze
			@para = para
			@option = Option.new(**kw).set_default(@recipe)
			self
		end
		def min_weight
			@recipe.min_weight(opt: @option)
		end
		def max_weight(include_outsourcing=false)
			@recipe.max_weight(opt: @option)
		end
		def min_level(w=@option.target_weight, include_outsourcing=false)
			@recipe.min_level(w, include_outsourcing, opt: @option)
		end
		def min_levels(w=1)
			@recipe.min_levels(w, opt: @option)
		end
		def min_levels_max(w=1)
			@recipe.min_levels_max(w, opt: @option)
		end
		def min_smith
			@recipe.min_smith
		end
		def min_comp
			@recipe.min_comp
		end
		def build(smith=-1, armor=smith, comp=armor.tap{armor=smith}, **kw)
			opt = temp_opt(**kw)
			smith, armor, comp = opt.smith_min, opt.armor_min, opt.comp_min if smith.nil?
			case @recipe
			when String
				recipe.build(smith, comp, opt: opt)
			when Enumerable
				recipe.build(smith, armor, comp, opt: opt)
			else
				raise BrokenRecipeError
			end
		end
		def show(smith=-1, armor=smith, comp=armor.tap{armor=smith}, para: @para, **kw)
			opt = temp_opt(**kw)
			smith, armor, comp = opt.smith_min, opt.armor_min, opt.comp_min if smith.nil?
			case @recipe
			when String
				recipe.show(smith, comp, para: para, opt: opt)
			when Enumerable
				recipe.show(smith, armor, comp, para: para, opt: opt)
			else
				raise BrokenRecipeError
			end
		end
		def search(target, para: @para, **kw)
			opt = temp_opt(**kw)
			@recipe.search(para, target, opt: opt)
		end
		private def correct_level(s, ac, x, opt)
			if s.nil?
				if x.equal?(false)
					s, ac, x = opt.smith_min, opt.comp_min, nil
				else
					s, ac, x = opt.smith_min, opt.armor_min, opt.comp_min
				end
			else
				s = 0 if s < 0
				ac = 0 if ac < 0
				if x.equal?(false)
					x = nil
				else
					x = 0 if x < 0
				end
			end
			[s, ac, x]
		end
		def para_call(smith=-1, armor=smith, comp=armor.tap{armor=smith}, para: @para, **kw)
			opt = temp_opt(**kw)
			smith, armor, comp = correct_level(smith, armor, comp, opt)
			case @recipe
			when String
				opt.irep.para_call(para, smith, comp)
			when Enumerable
				opt.irep.para_call(para, smith, armor, comp)
			else
				raise InvalidRecipeError
			end
		end
		def ir(**kw)
			temp_opt(**kw).irep
		end
		%i|attack phydef magdef hp mp str dex speed magic atkstr atk_sd dex_as mag_das magic2 magmag pmdef|.each do |sym|
			define_method(sym) do |s, ac=s, x=false, **kw|
				s, ac, x = correct_level(s, ac, x, temp_opt(**kw))
				ir(**kw).method(sym).call(s, ac, x)
			end
		end
		%i|power fpower|.each do |sym|
			define_method(sym) do |s, a=s, c=a.tap{a=s}, **kw|
				s, a, c = correct_level(s, a, c, temp_opt(**kw))
				ir(**kw).method(sym).call(s, a, c)
			end
		end
		%i|smith_cost comp_cost cost|.each do |sym|
			define_method(sym) do |s, c=s, outsourcing=false, **kw|
				s, c, x = correct_level(s, c, false, temp_opt(**kw))
				ir(**kw).method(sym).call(s, c, out_sourcing)
			end
		end
		def poly(para=@para, **kw)
			opt = temp_opt(**kw)
			if @recipe.kind_of?(String)
				@recipe.poly(para, opt: opt)
			else
				raise InvalidRecipeError, "Mgmg::Recipe#poly is available only for String recipes."
			end
		end
		def phydef_optimize(smith=nil, comp=smith, **kw)
			opt = temp_opt(**kw)
			if @recipe.kind_of?(String)
				@recipe.phydef_optimize(smith, comp, opt: opt)
			else
				raise InvalidRecipeError, "Mgmg::Recipe#phydef_optimize is available only for String recipes."
			end
		end
		def buster_optimize(smith=nil, comp=smith, **kw)
			opt = temp_opt(**kw)
			if @recipe.kind_of?(String)
				@recipe.buster_optimize(smith, comp, opt: opt)
			else
				raise InvalidRecipeError, "Mgmg::Recipe#buster_optimize is available only for String recipes."
			end
		end
	end
end
class String
	def to_recipe(para=:power, **kw)
		Mgmg::Recipe.new(self, para, **kw)
	end
end
module Enumerable
	def to_recipe(para=:power, **kw)
		Mgmg::Recipe.new(self, para, **kw)
	end
end
