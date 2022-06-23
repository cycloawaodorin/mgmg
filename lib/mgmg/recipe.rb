module Mgmg
	class Recipe
		def initialize(recipe, para: :power, **kw)
			@recipe = recipe
			@recipe.each(&:freeze) if @recipe.kind_of?(Enumerable)
			@recipe.freeze
			@para = para
			@option = Option.new(**kw).set_default(@recipe)
		end
		attr_reader :recipe
		attr_writer :para
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
					ret.irep.add_reinforcement if key == :reinforcement || key == :buff
				end
				ret
			end
		end
		def option(**kw)
			@option = temp_opt(*kw)
			@option
		end
		def replace(new_recipe, **kw)
			@recipe = new_recipe
			@recipe.each(&:freeze) if @recipe.kind_of?(Enumerable)
			@recipe.freeze
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
		def build(smith=-1, armor=smith, comp=armor.tap{armor=smith}, min: false, **kw)
			opt = temp_opt(**kw)
			smith, armor, comp = opt.smith_min, opt.armor_min, opt.comp_min if min
			case @recipe
			when String
				recipe.build(smith, comp, opt: opt)
			when Enumerable
				recipe.build(smith, armor, comp, opt: opt)
			else
				raise BrokenRecipeError
			end
		end
		def show(smith=-1, armor=smith, comp=armor.tap{armor=smith}, para: @para, min: false, **kw)
			opt = temp_opt(**kw)
			smith, armor, comp = opt.smith_min, opt.armor_min, opt.comp_min if min
			case @recipe
			when String
				recipe.show(smith, comp, para: para, opt: opt)
			when Enumerable
				recipe.show(smith, armor, comp, para: para, opt: opt)
			else
				raise BrokenRecipeError
			end
		end
		def para(smith=-1, armor=smith, comp=armor.tap{armor=smith}, para: @para, min: false, **kw)
			opt = temp_opt(**kw)
			smith, armor, comp = opt.smith_min, opt.armor_min, opt.comp_min if min
			return @para if smith < 0
			armor = 0 if armor < 0
			comp = 0 if comp < 0
			case @recipe
			when String
				opt.irep.para_call(para, smith, comp)
			when Enumerable
				opt.irep.para_call(para, smith, armor, comp)
			else
				raise BrokenRecipeError
			end
		end
		def search(target, para: @para, **kw)
			opt = temp_opt(**kw)
			@recipe.search(para, target, opt: opt)
		end
		def ir(**kw)
			temp_opt(**kw).irep
		end
	end
end
class String
	def to_recipe(**kw)
		Mgmg::Recipe.new(self, **kw)
	end
end
module Enumerable
	def to_recipe(**kw)
		Mgmg::Recipe.new(self, **kw)
	end
end
