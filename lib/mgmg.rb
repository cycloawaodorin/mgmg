require_relative './mgmg/version'
require_relative './mgmg/utils'
require_relative './mgmg/const'
require_relative './mgmg/equip'
require_relative './mgmg/poly'
require_relative './mgmg/system_equip'

class String
	def min_level(w=1)
		Mgmg::Equip.min_level(self, w)
	end
	def build(smith, comp=smith, left_associative: true)
		Mgmg::Equip.build(self, smith, comp, left_associative: left_associative)
	end
	def poly(para, left_associative: true)
		case para
		when :atkstr
			self.poly(:attack) + self.poly(:str)
		when :atk_sd
			self.poly(:attack) + self.poly(:str).quo(2) + self.poly(:dex).quo(2)
		when :dex_as
			self.poly(:dex) + self.poly(:attack).quo(2) + self.poly(:str).quo(2)
		when :mag_das
			self.poly(:magic) + self.poly(:dex_as).quo(2)
		when :magmag
			self.poly(:magdef) + self.poly(:magic).quo(2)
		when :cost
			if Mgmg::SystemEquip.keys.include?(self)
				return Mgmg::TPolynomial.new(Mgmg::Mat.new(1, 1, 0.quo(1)), 28, 0, 12, 12)
			end
			built = self.build(-1)
			const = (built.star**2) * ( /\+/.match(self) ? 5 : ( built.kind < 8 ? 2 : 1 ) )
			ret = poly(:attack) + poly(:phydef) + poly(:magdef)
			ret += poly(:hp).quo(4) + poly(:mp).quo(4)
			ret += poly(:str) + poly(:dex) + poly(:speed) + poly(:magic)
			ret.mat.body[0][0] += const
			ret
		else
			Mgmg::TPolynomial.build(self, para, left_associative: left_associative)
		end
	end
	def show(smith, comp=smith, left_associative: true)
		built = self.build(smith, comp, left_associative: left_associative)
		pstr = '%.3f' % built.fpower
		pstr.sub!(/\.?0+\Z/, '')
		puts "Building"
		puts "  #{self}"
		puts "with levels (#{smith}, #{comp}) yields (#{pstr}, #{built.total_cost})"
		puts "  #{built}"
	end
end
module Enumerable
	def build(smith, armor=smith, comp=armor.tap{armor=smith}, left_associative: true)
		self.map do |str|
			m = /\A\[*([^\+]+)/.match(str)
			if Mgmg::EquipPosition[m[1].build(0).kind] == 0
				str.build(smith, comp, left_associative: left_associative)
			else
				str.build(armor, comp, left_associative: left_associative)
			end
		end.sum
	end
end
