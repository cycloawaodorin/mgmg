require_relative './mgmg/version'
require_relative './mgmg/utils'
require_relative './mgmg/const'
require_relative './mgmg/equip'
require_relative './mgmg/poly'
require_relative './mgmg/system_equip'
require_relative './mgmg/search'
require_relative './mgmg/optimize'

class String
	def min_level(w=1)
		Mgmg::Equip.min_level(self, w)
	end
	def min_levels(left_associative: true)
		build(-1, -1, left_associative: left_associative).min_levels
	end
	def min_smith(left_associative: true)
		Mgmg::Equip.min_smith(self, left_associative: left_associative)
	end
	def min_comp(left_associative: true)
		Mgmg::Equip.min_comp(self, left_associative: left_associative)
	end
	def build(smith=-1, comp=smith, left_associative: true)
		Mgmg::Equip.build(self, smith, comp, left_associative: left_associative)
	end
	def poly(para=:cost, left_associative: true)
		la = left_associative
		case para
		when :atkstr
			self.poly(:attack, left_associative: la) + self.poly(:str, left_associative: la)
		when :atk_sd
			self.poly(:attack) + self.poly(:str, left_associative: la).quo(2) + self.poly(:dex, left_associative: la).quo(2)
		when :dex_as
			self.poly(:dex) + self.poly(:attack, left_associative: la).quo(2) + self.poly(:str, left_associative: la).quo(2)
		when :mag_das
			self.poly(:magic) + self.poly(:dex_as, left_associative: la).quo(2)
		when :magmag
			self.poly(:magdef) + self.poly(:magic, left_associative: la).quo(2)
		when :cost
			if Mgmg::SystemEquip.keys.include?(self)
				return Mgmg::TPolynomial.new(Mgmg::Mat.new(1, 1, 0.quo(1)), 28, 0, 12, 12)
			end
			built = self.build(-1)
			const = (built.star**2) * ( /\+/.match(self) ? 5 : ( built.kind < 8 ? 2 : 1 ) )
			ret = poly(:attack, left_associative: la) + poly(:phydef, left_associative: la) + poly(:magdef, left_associative: la)
			ret += poly(:hp, left_associative: la).quo(4) + poly(:mp, left_associative: la).quo(4)
			ret += poly(:str, left_associative: la) + poly(:dex, left_associative: la) + poly(:speed, left_associative: la) + poly(:magic, left_associative: la)
			ret.mat.body[0][0] += const
			ret
		else
			Mgmg::TPolynomial.build(self, para, left_associative: la)
		end
	end
	def eff(para, smith, comp=smith, left_associative: true)
		a = build(smith, comp, left_associative: left_associative).para_call(para)
		b = build(smith+1, comp, left_associative: left_associative).para_call(para)
		c = build(smith, comp+2, left_associative: left_associative).para_call(para)
		sden = smith==0 ? 1 : 2*smith-1
		cden = comp==0 ? 4 : 8*comp
		[(b-a).quo(sden), (c-a).quo(cden)]
	end
	def peff(para, smith, comp=smith, left_associative: true)
		poly(para, left_associative: left_associative).eff(smith, comp)
	end
	def show(smith=-1, comp=smith, left_associative: true)
		built = self.build(smith, comp, left_associative: left_associative)
		pstr = '%.3f' % built.fpower
		pstr.sub!(/\.?0+\Z/, '')
		puts "Building"
		puts "  #{self}"
		puts "with levels (#{smith}, #{comp}) yields (#{pstr}, #{built.total_cost})"
		puts "  #{built}"
	end
	def phydef_optimize(smith=nil, comp=smith, left_associative: true, magdef_maximize: true)
		Mgmg::Optimize.phydef_optimize(self, smith, comp, left_associative: left_associative, magdef_maximize: magdef_maximize)
	end
end
module Enumerable
	def build(smith=-1, armor=smith, comp=armor.tap{armor=smith}, left_associative: true)
		self.map do |str|
			m = /\A\[*([^\+]+)/.match(str)
			if Mgmg::EquipPosition[m[1].build(0).kind] == 0
				str.build(smith, comp, left_associative: left_associative)
			else
				str.build(armor, comp, left_associative: left_associative)
			end
		end.sum
	end
	def min_levels(left_associative: true)
		build(-1, -1, -1, left_associative: left_associative).min_levels
	end
	def min_level(left_associative: true)
		ret = [0, 0]
		build(-1, -1, -1, left_associative: left_associative).min_levels.each do |str, level|
			m = /\A\[*([^\+]+)/.match(str)
			if Mgmg::EquipPosition[m[1].build(0).kind] == 0
				ret[0] = [ret[0], level].max
			else
				ret[1] = [ret[1], level].max
			end
		end
		ret
	end
	def min_smith(left_associative: true)
		ret = [0, 0]
		self.each do |str|
			s = Mgmg::Equip.min_smith(str, left_associative: left_associative)
			m = /\A\[*([^\+]+)/.match(str)
			if Mgmg::EquipPosition[m[1].build(0).kind] == 0
				ret[0] = [ret[0], s].max
			else
				ret[1] = [ret[1], s].max
			end
		end
		ret
	end
	def min_comp(left_associative: true)
		self.map do |str|
			Mgmg::Equip.min_comp(str, left_associative: left_associative)
		end.max
	end
end
