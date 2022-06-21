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
require_relative './mgmg/search'
require_relative './mgmg/optimize'

class String
	def min_level(w=1)
		Mgmg::Equip.min_level(self, w)
	end
	def min_levels(w=1, opt: Mgmg::Option.new)
		build(-1, -1, opt: opt).min_levels(w)
	end
	def min_smith(opt: Mgmg::Option.new)
		Mgmg::Equip.min_smith(self, opt: opt)
	end
	def min_comp(opt: Mgmg::Option.new)
		Mgmg::Equip.min_comp(self, opt: opt)
	end
	def build(smith=-1, comp=smith, opt: Mgmg::Option.new)
		Mgmg::Equip.build(self, smith, comp, left_associative: opt.left_associative).reinforce(*opt.reinforcement)
	end
	def ir(opt: Mgmg::Option.new)
		Mgmg::IR.build(self, left_associative: opt.left_associative, reinforcement: opt.reinforcement)
	end
	def poly(para=:cost, opt: Mgmg::Option.new)
		case para
		when :atkstr
			self.poly(:attack, opt: opt) + self.poly(:str, opt: opt)
		when :atk_sd
			self.poly(:attack, opt: opt) + self.poly(:str, opt: opt).quo(2) + self.poly(:dex, opt: opt).quo(2)
		when :dex_as
			self.poly(:dex, opt: opt) + self.poly(:attack, opt: opt).quo(2) + self.poly(:str, opt: opt).quo(2)
		when :mag_das
			self.poly(:magic, opt: opt) + self.poly(:dex_as, opt: opt).quo(2)
		when :magmag
			self.poly(:magdef, opt: opt) + self.poly(:magic, opt: opt).quo(2)
		when :pmdef
			pd = self.poly(:phydef, opt: opt)
			md = self.poly(:magmag, opt: opt)
			pd <= md ? pd : md
		when :cost
			if Mgmg::SystemEquip.keys.include?(self)
				return Mgmg::TPolynomial.new(Mgmg::Mat.new(1, 1, 0.quo(1)), 28, 0, 12, 12)
			end
			built = self.build(-1, opt: opt)
			const = (built.star**2) * ( /\+/.match(self) ? 5 : ( built.kind < 8 ? 2 : 1 ) )
			ret = poly(:attack, opt: opt) + poly(:phydef, opt: opt) + poly(:magdef, opt: opt)
			ret += poly(:hp, opt: opt).quo(4) + poly(:mp, opt: opt).quo(4)
			ret += poly(:str, opt: opt) + poly(:dex, opt: opt) + poly(:speed, opt: opt) + poly(:magic, opt: opt)
			ret.mat.body[0][0] += const
			ret
		else
			Mgmg::TPolynomial.build(self, para, left_associative: opt.left_associative)
		end
	end
	def eff(para, smith, comp=smith, opt: Mgmg::Option.new)
		a = build(smith, comp, opt: opt).para_call(para)
		b = build(smith+1, comp, opt: opt).para_call(para)
		c = build(smith, comp+2, opt: opt).para_call(para)
		sden = smith==0 ? 1 : 2*smith-1
		cden = comp==0 ? 4 : 8*comp
		[(b-a).quo(sden), (c-a).quo(cden)]
	end
	def peff(para, smith, comp=smith, opt: Mgmg::Option.new)
		poly(para, opt: opt).eff(smith, comp)
	end
	def show(smith=-1, comp=smith, para: :power, opt: Mgmg::Option.new)
		rein = case opt.reinforcement
		when Array
			opt.reinforcement.map{|r| Mgmg::Reinforcement.compile(r)}
		else
			[Mgmg::Reinforcement.compile(opt.reinforcement)]
		end
		built = build(smith, comp, opt: opt)
		pstr = '%.3f' % built.para_call(para)
		pstr.sub!(/\.?0+\Z/, '')
		puts "Building"
		puts "  #{self}"
		rein = rein.empty? ? '' : " reinforced by {#{rein.join(',')}}"
		puts "with levels (#{smith}, #{comp})#{rein} yields (#{pstr}, #{built.total_cost})"
		puts "  #{built}"
	end
	def phydef_optimize(smith=nil, comp=smith, opt: Mgmg::Option.new)
		Mgmg::Optimize.phydef_optimize(self, smith, comp, opt: opt)
	end
	def buster_optimize(smith=nil, comp=smith, opt: Mgmg::Option.new)
		Mgmg::Optimize.buster_optimize(self, smith, comp, opt: opt)
	end
end
module Enumerable
	def build(smith=-1, armor=smith, comp=armor.tap{armor=smith}, opt: Mgmg::Option.new)
		opt = opt.dup
		rein = opt.reinforcement
		opt.reinforcement = []
		self.sum do |str|
			m = /\A\[*([^\+]+)/.match(str)
			if Mgmg::EquipPosition[m[1].build(0).kind] == 0
				str.build(smith, comp, opt: opt)
			else
				str.build(armor, comp, opt: opt)
			end
		end.reinforce(*rein)
	end
	def ir(opt: Mgmg::Option.new)
		self.sum do |str|
			str.ir(opt: opt)
		end.add_reinforcement(opt.reinforcement)
	end
	def show(smith=-1, armor=smith, comp=armor.tap{armor=smith}, para: :power, opt: Mgmg::Option.new)
		rein = case opt.reinforcement
		when Array
			opt.reinforcement.map{|r| Mgmg::Reinforcement.compile(r)}
		else
			[Mgmg::Reinforcement.compile(opt.reinforcement)]
		end
		built = self.build(smith, armor, comp, opt: opt)
		pstr = '%.3f' % built.para_call(para)
		pstr.sub!(/\.?0+\Z/, '')
		puts "Building"
		puts "  #{self.join(', ')}"
		rein = rein.empty? ? '' : " reinforced by {#{rein.join(',')}}"
		puts "with levels (#{smith}, #{armor}, #{comp})#{rein} yields (#{pstr}, #{built.total_cost})"
		puts "  #{built}"
	end
	def min_levels(w=1, opt: Mgmg::Option.new)
		build(-1, -1, -1, opt: opt).min_levels(w)
	end
	def min_level(w=1, opt: Mgmg::Option.new)
		ret = [0, 0]
		build(-1, -1, -1, opt: opt).min_levels(w).each do |str, level|
			m = /\A\[*([^\+]+)/.match(str)
			if Mgmg::EquipPosition[m[1].build(0).kind] == 0
				ret[0] = [ret[0], level].max
			else
				ret[1] = [ret[1], level].max
			end
		end
		ret
	end
	def min_smith(opt: Mgmg::Option.new)
		ret = [0, 0]
		self.each do |str|
			s = Mgmg::Equip.min_smith(str, opt: opt)
			m = /\A\[*([^\+]+)/.match(str)
			if Mgmg::EquipPosition[m[1].build(0).kind] == 0
				ret[0] = [ret[0], s].max
			else
				ret[1] = [ret[1], s].max
			end
		end
		ret
	end
	def min_comp(opt: Mgmg::Option.new)
		self.map do |str|
			Mgmg::Equip.min_comp(str, opt: opt)
		end.max
	end
end
