require_relative './mgmg/version'
require_relative './mgmg/utils'
require_relative './mgmg/const'
require_relative './mgmg/equip'
require_relative './mgmg/poly'
require_relative './mgmg/ir'
require_relative './mgmg/system_equip'
require_relative './mgmg/cuisine'
require_relative './mgmg/reinforce'
require_relative './mgmg/search'
require_relative './mgmg/optimize'

class String
	def min_level(w=1)
		Mgmg::Equip.min_level(self, w)
	end
	def min_levels(w=1, left_associative: true)
		build(-1, -1, left_associative: left_associative).min_levels(w)
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
	def ir(left_associative: true, reinforcement: [])
		Mgmg::IR.build(self, left_associative: left_associative, reinforcement: reinforcement)
	end
	def poly(para=:cost, left_associative: true)
		la = left_associative
		case para
		when :atkstr
			self.poly(:attack, left_associative: la) + self.poly(:str, left_associative: la)
		when :atk_sd
			self.poly(:attack, left_associative: la) + self.poly(:str, left_associative: la).quo(2) + self.poly(:dex, left_associative: la).quo(2)
		when :dex_as
			self.poly(:dex, left_associative: la) + self.poly(:attack, left_associative: la).quo(2) + self.poly(:str, left_associative: la).quo(2)
		when :mag_das
			self.poly(:magic, left_associative: la) + self.poly(:dex_as, left_associative: la).quo(2)
		when :magmag
			self.poly(:magdef, left_associative: la) + self.poly(:magic, left_associative: la).quo(2)
		when :pmdef
			pd = self.poly(:phydef, left_associative: la)
			md = self.poly(:magmag, left_associative: la)
			pd <= md ? pd : md
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
	def show(smith=-1, comp=smith, left_associative: true, para: :power, reinforcement: [])
		rein = case reinforcement
		when Array
			reinforcement.map{|r| Mgmg::Reinforcement.compile(r)}
		else
			[Mgmg::Reinforcement.compile(reinforcement)]
		end
		built = self.build(smith, comp, left_associative: left_associative).reinforce(*rein)
		pstr = '%.3f' % built.para_call(para)
		pstr.sub!(/\.?0+\Z/, '')
		puts "Building"
		puts "  #{self}"
		rein = rein.empty? ? '' : " reinforced by {#{rein.join(',')}}"
		puts "with levels (#{smith}, #{comp})#{rein} yields (#{pstr}, #{built.total_cost})"
		puts "  #{built}"
	end
	def phydef_optimize(smith=nil, comp=smith, left_associative: true, magdef_maximize: true)
		Mgmg::Optimize.phydef_optimize(self, smith, comp, left_associative: left_associative, magdef_maximize: magdef_maximize)
	end
	def buster_optimize(smith=nil, comp=smith, left_associative: true)
		Mgmg::Optimize.buster_optimize(self, smith, comp, left_associative: left_associative)
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
	def ir(left_associative: true, reinforcement: [])
		self.map do |str|
			str.ir(left_associative: left_associative)
		end.sum.add_reinforcement(reinforcement)
	end
	def show(smith=-1, armor=smith, comp=armor.tap{armor=smith}, left_associative: true, para: :power, reinforcement: [])
		rein = case reinforcement
		when Array
			reinforcement.map{|r| Mgmg::Reinforcement.compile(r)}
		else
			[Mgmg::Reinforcement.compile(reinforcement)]
		end
		built = self.build(smith, armor, comp, left_associative: left_associative).reinforce(*rein)
		pstr = '%.3f' % built.para_call(para)
		pstr.sub!(/\.?0+\Z/, '')
		puts "Building"
		puts "  #{self.join(', ')}"
		rein = rein.empty? ? '' : " reinforced by {#{rein.join(',')}}"
		puts "with levels (#{smith}, #{armor}, #{comp})#{rein} yields (#{pstr}, #{built.total_cost})"
		puts "  #{built}"
	end
	def min_levels(w=1, left_associative: true)
		build(-1, -1, -1, left_associative: left_associative).min_levels(w)
	end
	def min_level(w=1, left_associative: true)
		ret = [0, 0]
		build(-1, -1, -1, left_associative: left_associative).min_levels(w).each do |str, level|
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
