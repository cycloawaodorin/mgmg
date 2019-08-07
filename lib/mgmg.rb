require "mgmg/version"
require 'mgmg/const'

module Mgmg
	class << Equip
		def build(str, s_level, c_level, left_associative: true)
			str = Mgmg.check_string(str)
			stack, str = build_sub0([], str)
			build_sub(stack, str, s_level, c_level, left_associative)
		end
		private def build_sub0(stack, str)
			SystemEquip.each do |k, v|
				if Regexp.compile(k).match(str)
					stack << v
					str = str.gsub(k, "<#{stack.length-1}>")
				end
			end
			[stack, str]
		end
		private def build_sub(stack, str, s_level, c_level, lassoc)
			if m = /\A(.*\+?)\[([^\[\]]+)\](\+?[^\[]*)\Z/.match(str)
				stack << build_sub(stack, m[2], s_level, c_level, lassoc)
				build_sub(stack, "#{m[1]}<#{stack.length-1}>#{m[3]}", s_level, c_level, lassoc)
			elsif m = ( lassoc ? /\A(.+)\+(.+?)\Z/ : /\A(.+?)\+(.+)\Z/ ).match(str)
				if c_level < 0
					compose(build_sub(stack, m[1], s_level, c_level, lassoc), build_sub(stack, m[2], s_level, c_level, lassoc), 0, true)
				else
					compose(build_sub(stack, m[1], s_level, c_level, lassoc), build_sub(stack, m[2], s_level, c_level, lassoc), c_level, false)
				end
			elsif m = /\A\<(\d+)\>\Z/.match(str)
				stack[m[1].to_i]
			else
				if s_level < 0
					smith(str, 0, true)
				else
					smith(str, s_level, false)
				end
			end
		end
		
		def compose(main, sub, level, outsourcing)
			main_k, sub_k = main.kind, sub.kind
			main_s, sub_s = main.star, sub.star
			main_main, sub_main = main.main, sub.main
			main_sub, sub_sub = main.sub, sub.sub
			para = Vec.new(9, 0)
			ele = Vec.new(3, 0)
			
			# 9パラメータ
			coef = Equip9[main_k].dup
			para[] = coef
			para.add!(level).e_div!(2)
			para.e_mul!(sub.para).e_div!(100)
			coef.sub!(Equip9[sub_k])
			coef.add!( 100 + (main_s-sub_s)*5 - ( ( main_main==sub_main && main_main != 9 ) ? 30 : 0 ) )
			coef.add!(Material9[main_main]).sub!(Material9[sub_main])
			coef.e_mul!(EquipFilter[main_k])
			para.e_mul!(coef).e_div!( main_k==sub_k ? 200 : 100 )
			para.add!(main.para)
			
			# エレメント
			ele[] = sub.element
			ele.e_mul!([75, level].min).e_div!( main_k==sub_k ? 200 : 100 )
			ele.add!(main.element)
			
			ret = new(main_k, main.weight+sub.weight, main_s+sub_s, main_sub, sub_main, para, ele)
			ret.total_cost.add!(main.total_cost).add!(sub.total_cost)
			ret.total_cost[1] += ret.comp_cost(outsourcing)
			ret
		end
		
		def smith(str, level, outsourcing)
			str = Mgmg.check_string(str)
			unless m = /\A(.+)\((.+\d+),?(.+\d+)\)\Z/.match(str)
				raise InvalidSmithError.new(str)
			end
			kind = EquipIndex[m[1].to_sym]
			unless kind
				raise InvalidEquipClassError.new(m[1])
			end
			main_m, main_s, main_mc = parse_material(m[2])
			sub_m, sub_s, sub_mc = parse_material(m[3])
			para = Vec.new(9, 0)
			ele = Vec.new(3, 0)
			
			# 9パラメータ
			para[] = Equip9[kind]
			para.e_mul!(Main9[main_m]).e_div!(100)
			coef = Sub9[sub_m].dup
			coef.add!(level)
			para.e_mul!(coef).e_div!( main_mc==sub_mc ? 200 : 100 )
			
			# エレメント
			ele[] = MainEL[main_m]
			ele.e_mul!(SubEL[sub_m]).e_div!(6)
			
			# 重量
			weight = ( ( EquipWeight[kind] + SubWeight[sub_m] - level.div(2) ) * ( MainWeight[main_m] ) ).div(10000)
			
			ret = new(kind, ( weight<1 ? 1 : weight ), (main_s+sub_s).div(2), main_mc, sub_mc, para, ele)
			if kind < 8
				ret.total_cost[0] = ret.smith_cost(outsourcing)
			else
				ret.total_cost[2] = ret.smith_cost(outsourcing)
			end
			ret
		end
		
		def min_level(str, weight=1)
			str = Mgmg.check_string(str)
			unless m = /\A(.+)\((.+\d+),?(.+\d+)\)\Z/.match(str)
				raise InvalidSmithError.new(str)
			end
			kind = EquipIndex[m[1].to_sym]
			main_m, main_s, = parse_material(m[2])
			sub_m, sub_s, = parse_material(m[3])
			
			q, r = ((weight+1)*10000).divmod(MainWeight[main_m])
			l = ( EquipWeight[kind] + SubWeight[sub_m] - q + ( r==0 ? 1 : 0 ) )*2
			[(main_s-1)*3, (sub_s-1)*3, l].max
		end
		
		private def parse_material(str)
			m = /\A.+?(\d+)\Z/.match(str)
			mat = MaterialIndex[str.to_sym]
			if m.nil? || mat.nil?
				raise InvalidMaterialError.new(str)
			end
			[mat, m[1].to_i, mat<90 ? mat.div(10): 9]
		end
	end
end

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
		puts "with levels (#{smith}, #{comp}) yields (#{pstr}, #{builded.total_cost})"
		puts "  #{builded}"
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
