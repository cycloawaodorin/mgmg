require_relative './mgmg/version'
require_relative './mgmg/utils'
require_relative './mgmg/const'
require_relative './mgmg/equip'
require_relative './mgmg/poly'
require_relative './mgmg/ir'
require_relative './mgmg/system_equip'
require_relative './mgmg/cuisine'
require_relative './mgmg/reinforce'
require_relative './mgmg/option'
require_relative './mgmg/recipe'
require_relative './mgmg/search'
require_relative './mgmg/optimize'

class String
	using Mgmg::Refiner
	def to_recipe(para=:power, allow_over20: false, **kw)
		ret = Mgmg::Recipe.new(self, para, **kw)
		raise Mgmg::Over20Error, ret.ir.star if (!allow_over20 and 20<ret.ir.star)
		ret
	end
	def min_weight(opt: Mgmg::Option.new)
		build(build(opt:).min_levels_max, opt:).weight
	end
	def max_weight(include_outsourcing=false, opt: Mgmg::Option.new)
		if include_outsourcing
			build(-1, opt:).weight
		else
			build(min_smith(opt:), opt:).weight
		end
	end
	def min_level(w=0, include_outsourcing=false, opt: Mgmg::Option.new)
		key = [self.dup.freeze, w, include_outsourcing, opt.left_associative].freeze
		return Mgmg::CacheMLS[key] if Mgmg::CacheMLS.has_key?(key)
		ret = __min_level_sub(w, include_outsourcing, opt)
		Mgmg::CacheMLS.store(key, ret)
		ret
	end
	private def __min_level_sub(w, include_outsourcing, opt)
		built = build(-1, opt:)
		w = build(built.min_levels_max, -1, opt:).weight - w if w <= 0
		return -1 if include_outsourcing && built.weight <= w
		ms = min_smith(opt:)
		return ms if build(ms, opt:).weight <= w
		ary = [ms]
		4.downto(1) do |wi| # 単品の最大重量は[斧|重鎧](金10石10)の5
			built.min_levels(wi).values.each do |v|
				(ary.include?(v) or ary << v) if ms < v
			end
		end
		ary.sort.each do |l|
			return l if build(l, opt:).weight <= w
		end
		raise ArgumentError, "w=`#{w}' is given, but the minimum weight for the recipe is `#{min_weight(opt:)}'."
	end
	def min_levels(w=1, opt: Mgmg::Option.new)
		build(opt:).min_levels(w)
	end
	def min_levels_max(w=1, opt: Mgmg::Option.new)
		min_levels(w, opt:).values.append(-1).max
	end
	def min_smith(opt: Mgmg::Option.new)
		Mgmg::Equip.min_smith(self, opt:)
	end
	def min_comp(opt: Mgmg::Option.new)
		Mgmg::Equip.min_comp(self, opt:)
	end
	def build(smith=-1, comp=smith, opt: Mgmg::Option.new)
		Mgmg::Equip.build(self, smith, comp, left_associative: opt.left_associative, include_system_equips: opt.include_system_equips).reinforce(*opt.reinforcement)
	end
	def ir(opt: Mgmg::Option.new)
		Mgmg::IR.build(self, left_associative: opt.left_associative, reinforcement: opt.reinforcement, include_system_equips: opt.include_system_equips)
	end
	def poly(para=:cost, opt: Mgmg::Option.new)
		case para
		when :atkstr
			self.poly(:attack, opt:) + self.poly(:str, opt:)
		when :atk_sd
			self.poly(:attack, opt:) + self.poly(:str, opt:).quo(2) + self.poly(:dex, opt:).quo(2)
		when :dex_as
			self.poly(:dex, opt:) + self.poly(:attack, opt:).quo(2) + self.poly(:str, opt:).quo(2)
		when :mag_das
			self.poly(:magic, opt:) + self.poly(:dex_as, opt:).quo(2)
		when :magic2
			self.poly(:magic, opt:).scalar(2)
		when :magmag
			self.poly(:magdef, opt:) + self.poly(:magic, opt:).quo(2)
		when :pmdef
			pd = self.poly(:phydef, opt:)
			md = self.poly(:magmag, opt:)
			pd <= md ? pd : md
		when :hs
			self.poly(:hp, opt:) + self.poly(:str, opt:)
		when :cost
			if opt.include_system_equips and Mgmg::SystemEquip.has_key?(self) then
				return Mgmg::TPolynomial.new(Mgmg::Mat.new(1, 1, 0.quo(1)), 28, 0, 12, 12)
			end
			built = self.build(-1, opt:)
			const = (built.star**2) * ( /\+/.match(self) ? 5 : ( built.kind < 8 ? 2 : 1 ) )
			ret = poly(:attack, opt:) + poly(:phydef, opt:) + poly(:magdef, opt:)
			ret += poly(:hp, opt:).quo(4) + poly(:mp, opt:).quo(4)
			ret += poly(:str, opt:) + poly(:dex, opt:) + poly(:speed, opt:) + poly(:magic, opt:)
			ret.mat.body[0][0] += const
			ret
		else
			Mgmg::TPolynomial.build(self, para, left_associative: opt.left_associative, include_system_equips: opt.include_system_equips)
		end
	end
	def eff(para, smith, comp=smith, opt: Mgmg::Option.new)
		a = build(smith, comp, opt:).para_call(para)
		b = build(smith+1, comp, opt:).para_call(para)
		c = build(smith, comp+2, opt:).para_call(para)
		sden = smith==0 ? 1 : 2*smith-1
		cden = comp==0 ? 4 : 8*comp
		[(b-a).quo(sden), (c-a).quo(cden)]
	end
	def peff(para, smith, comp=smith, opt: Mgmg::Option.new)
		poly(para, opt:).eff(smith, comp)
	end
	def show(smith=-1, comp=smith, para: :power, name: nil, opt: Mgmg::Option.new)
		rein = case opt.reinforcement
		when Array
			opt.reinforcement.map{|r| Mgmg::Reinforcement.compile(r)}
		else
			[Mgmg::Reinforcement.compile(opt.reinforcement)]
		end
		name = self if name.nil?
		built = build(smith, comp, opt:)
		pstr = '%.3f' % built.para_call(para)
		pstr.sub!(/\.?0+\Z/, '')
		puts "With levels (#{smith}, #{comp}: #{Mgmg.exp(smith, comp).comma3}), building"
		puts "  #{name}"
		rein = rein.empty? ? '' : "reinforced by {#{rein.join(',')}} "
		puts "#{rein}yields (#{pstr}, #{built.total_cost})"
		puts "  #{built}"
	end
	def phydef_optimize(smith=nil, comp=smith, opt: Mgmg::Option.new)
		Mgmg::Optimize.phydef_optimize(self, smith, comp, opt:)
	end
	def buster_optimize(smith=nil, comp=smith, opt: Mgmg::Option.new)
		Mgmg::Optimize.buster_optimize(self, smith, comp, opt:)
	end
end
module Enumerable
	using Mgmg::Refiner
	def to_recipe(para=:power, allow_over20: false, **kw)
		unless allow_over20
			self.each do |e|
				foo = e.build(-1).star
				raise Mgmg::Over20Error, foo if 20 < foo
			end
		end
		Mgmg::Recipe.new(self, para, **kw)
	end
	def build(smith=-1, armor=smith, comp=armor.tap{armor=smith}, opt: Mgmg::Option.new)
		opt = opt.dup
		rein = opt.reinforcement
		opt.reinforcement = []
		if self.empty?
			Mgmg::Equip::Zero
		else
			self.sum(Mgmg::Equip::Zero) do |str|
				if Mgmg::EquipPosition[str.build(opt:).kind] == 0
					str.build(smith, comp, opt:)
				else
					str.build(armor, comp, opt:)
				end
			end.reinforce(*rein)
		end
	end
	def ir(opt: Mgmg::Option.new)
		self.sum(Mgmg::IR::Zero) do |str|
			str.ir(opt:)
		end.add_reinforcement(opt.reinforcement)
	end
	def show(smith=-1, armor=smith, comp=armor.tap{armor=smith}, para: :power, name: nil, opt: Mgmg::Option.new)
		rein = case opt.reinforcement
		when Array
			opt.reinforcement.map{|r| Mgmg::Reinforcement.compile(r)}
		else
			[Mgmg::Reinforcement.compile(opt.reinforcement)]
		end
		name = self.join(' ') if name.nil?
		built = self.build(smith, armor, comp, opt:)
		pstr = '%.3f' % built.para_call(para)
		pstr.sub!(/\.?0+\Z/, '')
		puts "With levels (#{smith}, #{armor}, #{comp}: #{Mgmg.exp(smith, armor, comp).comma3}), building"
		puts "  #{name}"
		rein = rein.empty? ? '' : "reinforced by {#{rein.join(',')}} "
		puts "#{rein}yields (#{pstr}, #{built.total_cost})"
		puts "  #{built}"
	end
	def min_weight(opt: Mgmg::Option.new)
		build(*build(opt:).min_levels_max, -1, opt:).weight
	end
	def max_weight(include_outsourcing=false, opt: Mgmg::Option.new)
		if include_outsourcing
			build(-1, opt:).weight
		else
			build(*min_smith(opt:), -1, opt:).weight
		end
	end
	def min_weights(opt: Mgmg::Option.new)
		weapons, armors = [], []
		each do |str|
			if Mgmg::EquipPosition[str.build(opt:).kind] == 0
				weapons << str
			else
				armors << str
			end
		end
		[weapons.min_weight(opt:), armors.min_weight(opt:)]
	end
	def max_weights(include_outsourcing=false, opt: Mgmg::Option.new)
		weapons, armors = [], []
		each do |str|
			if Mgmg::EquipPosition[str.build(opt:).kind] == 0
				weapons << str
			else
				armors << str
			end
		end
		[weapons.max_weight(include_outsourcing, opt:), armors.max_weight(include_outsourcing, opt:)]
	end
	def min_level(ws=0, wa=ws, include_outsourcing=false, opt: Mgmg::Option.new)
		weapons, armors = [], []
		each do |str|
			if Mgmg::EquipPosition[str.build(opt:).kind] == 0
				weapons << str
			else
				armors << str
			end
		end
		ms, ma = min_smith(opt:)
		rs = min_level_sub(ws, ms, 0, weapons, include_outsourcing, opt:)
		ra = min_level_sub(wa, ma, 1, armors, include_outsourcing, opt:)
		[rs, ra]
	end
	private def min_level_sub(w, ms, i, recipe, include_outsourcing, opt: Mgmg::Option.new)
		built = recipe.build(opt:)
		w = recipe.build(built.min_levels_max[i], opt:).weight - w if w <= 0
		return -1 if include_outsourcing && built.weight <= w
		return ms if recipe.build(ms, opt:).weight <= w
		ary = [ms]
		4.downto(1) do |wi|
			built.min_levels(wi).values.each do |v|
				(ary.include?(v) or ary << v) if ms << v
			end
		end
		ary.sort.each do |l|
			return l if recipe.build(l, opt:).weight <= w
		end
		raise ArgumentError, "w#{%w|s a|[i]}=`#{w}' is given, but the minimum weight for the #{%w|weapon(s) armor(s)|[i]} is `#{recipe.min_weight(opt:)}'."
	end
	def min_levels(w=1, opt: Mgmg::Option.new)
		build(opt:).min_levels(w)
	end
	def min_levels_max(w=1, opt: Mgmg::Option.new)
		ret = [-1, -1]
		min_levels(w, opt:).each do |str, level|
			if Mgmg::EquipPosition[str.build(opt:).kind] == 0
				ret[0] = [ret[0], level].max
			else
				ret[1] = [ret[1], level].max
			end
		end
		ret
	end
	def min_smith(opt: Mgmg::Option.new)
		ret = [-1, -1]
		self.each do |str|
			s = Mgmg::Equip.min_smith(str, opt:)
			if Mgmg::EquipPosition[str.build(opt:).kind] == 0
				ret[0] = [ret[0], s].max
			else
				ret[1] = [ret[1], s].max
			end
		end
		ret
	end
	def min_comp(opt: Mgmg::Option.new)
		self.map do |str|
			Mgmg::Equip.min_comp(str, opt:)
		end.append(-1).max
	end
end
