module Mgmg
	using Refiner
	class Equip
		ParamList = %w|攻撃 物防 魔防 HP MP 腕力 器用 素早 魔力|
		ElementList = %w|火 地 水|
		EqPosList = %w|武 頭 胴 腕 足 飾|
		def initialize(kind, weight, star, main_m, sub_m, para, element)
			@kind, @weight, @star, @main, @sub, @para, @element = kind, weight, star, main_m, sub_m, para, element
			@total_cost = Vec[0, 0, 0]
			@history, @min_levels = [self], Hash.new
		end
		attr_accessor :kind, :weight, :star, :main, :sub, :para, :element, :total_cost, :history, :min_levels
		def initialize_copy(other)
			@kind = other.kind
			@weight = other.weight
			@star = other.star
			@main = other.main
			@sub = other.sub
			@para = other.para.dup
			@element = other.element.dup
			@total_cost = other.total_cost.dup
			@history = other.history.dup
			@min_levels = other.min_levels.dup
		end
		
		def compose(other, level, outsourcing=false)
			self.class.compose(self, other, level, outsourcing)
		end
		
		def to_s
			par = @para.map.with_index{|e, i| e==0 ? nil : "#{ParamList[i]}:#{e.comma3}"}.compact
			elm = @element.map.with_index{|e, i| e==0 ? nil : "#{ElementList[i]}#{e}"}.compact
			unless elm.empty?
				par << "EL:#{elm.join('')}"
			end
			if @kind == 28
				ep = @star.map.with_index{|e, i| e==0 ? nil : "#{EqPosList[i]}:#{e}"}.compact
				"複数装備#{@weight}(#{ep.join(', ')})[#{par.join(', ')}]"
			else
				"#{EquipName[@kind]}#{@weight}☆#{@star}(#{MaterialClass[@main]}#{MaterialClass[@sub]})[#{par.join(', ')}]"
			end
		end
		def inspect
			par = @para.map.with_index{|e, i| "#{ParamList[i]}:#{e}"}
			par << ( "EL:" + @element.map.with_index{|e, i| "#{ElementList[i]}#{e}"}.join('') )
			tc = "<コスト:" + @total_cost.map.with_index{|e, i| "#{ElementList[i]}#{e}"}.join('') + '>'
			if @kind == 28
				ep = @star.map.with_index{|e, i| "#{EqPosList[i]}:#{e}"}
				"複数装備#{@weight}(#{ep.join(', ')})[#{par.join(', ')}]#{tc}"
			else
				"#{EquipName[@kind]}#{@weight}☆#{@star}(#{MaterialClass[@main]}#{MaterialClass[@sub]})[#{par.join(', ')}]#{tc}"
			end
		end
		
		def min_level
			if @kind == 28
				ret = [0, 0]
				@min_levels.each do |str, ml|
					if str.build(-1).kind < 8
						if ret[0] < ml
							ret[0] = ml
						end
					else
						if ret[1] < ml
							ret[1] = ml
						end
					end
				end
				ret
			else
				@min_levels.values.append(0).max
			end
		end
		
		def para_call(para)
			method(para).call
		end
		
		%i|attack phydef magdef hp mp str dex speed magic|.each.with_index do |s, i|
			define_method(s){ @para[i] }
		end
		def atkstr
			attack()+str()
		end
		def atk_sd
			attack()*2+str()+dex()
		end
		def dex_as
			attack()+str()+dex()*2
		end
		def mag_das
			magic()*4+dex_as()
		end
		[:fire, :earth, :water].each.with_index do |s, i|
			define_method(s){ @element[i] }
		end
		
		def power
			case @kind
			when 0, 1
				atk_sd()*2
			when 2, 3
				atkstr()*4
			when 4
				[dex_as()*2, mag_das()].max
			when 5
				dex_as()*2
			when 6, 7
				[magic()*8, atkstr()*4].max
			when 28
				(@para.sum*4)-((hp()+mp())*3)
			else
				ret = @para.max
				if ret == magdef()
					ret*2+magic()
				else
					ret*2
				end
			end
		end
		def magmag
			magdef()*2+magic()
		end
		def fpower
			if @kind < 8 || @kind == 28
				power().fdiv(4)
			else
				power().fdiv(2)
			end
		end
		
		def smith_cost(outsourcing=false)
			if outsourcing
				if @kind < 8
					(@star**2)*2+@para.sum+hp().cdiv(4)-hp()+mp().cdiv(4)-mp()
				else
					(@star**2)+@para.sum+hp().cdiv(4)-hp()+mp().cdiv(4)-mp()
				end
			else
				if @kind < 8
					((@star**2)*2+@para.sum+hp().cdiv(4)-hp()+mp().cdiv(4)-mp()).div(2)
				else
					((@star**2)+@para.sum+hp().cdiv(4)-hp()+mp().cdiv(4)-mp()).div(2)
				end
			end
		end
		def comp_cost(outsourcing=false)
			if outsourcing
				[(@star**2)*5+@para.sum+hp().cdiv(4)-hp()+mp().cdiv(4)-mp(), 0].max
			else
				[((@star**2)*5+@para.sum+hp().cdiv(4)-hp()+mp().cdiv(4)-mp()).div(2), 0].max
			end
		end
		alias :cost :comp_cost
		
		def add!(other)
			if @kind == 28
				if other.kind == 28
					@star.add!(other.star)
				else
					@star[EquipPosition[other.kind]] += 1
				end
			else
				@star = Vec.new(6, 0)
				@star[EquipPosition[@kind]] = 1
				@kind = 28
				if other.kind == 28
					@star.add!(other.star)
				else
					@star[EquipPosition[other.kind]] += 1
				end
			end
			@weight += other.weight
			@main = 12
			@sub = 12
			@para.add!(other.para)
			@element.add!(other.element)
			@total_cost.add!(other.total_cost)
			@history.concat(other.history)
			@min_levels.merge!(other.min_levels)
			self
		end
		def +(other)
			self.dup.add!(other)
		end
		def coerce(other)
			if other == 0
				zero = self.class.new(28, 0, Vec.new(6, 0), 12, 12, Vec.new(9, 0), Vec.new(3, 0))
				zero.history.clear
				[zero, self]
			else
				raise TypeError, "Mgmg::Equip can't be coerced into other than 0"
			end
		end
	end
	
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
			ret.min_levels.merge!(main.min_levels, sub.min_levels)
			ret.history = [*main.history, *sub.history, ret]
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
			ret.min_levels.store(str, str.min_level)
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
		
		def min_comp(str, left_associative: true)
			str = Mgmg.check_string(str)
			stack, str = minc_sub0([], str)
			(minc_sub(stack, str, left_associative)[1]-1)*3
		end
		private def minc_sub0(stack, str)
			SystemEquip.each do |k, v|
				if Regexp.compile(k).match(str)
					stack << v.star
					str = str.gsub(k, "<#{stack.length-1}>")
				end
			end
			[stack, str]
		end
		private def minc_sub(stack, str, lassoc)
			if m = /\A(.*\+?)\[([^\[\]]+)\](\+?[^\[]*)\Z/.match(str)
				stack << minc_sub(stack, m[2], lassoc)[0]
				minc_sub(stack, "#{m[1]}<#{stack.length-1}>#{m[3]}", lassoc)
			elsif m = ( lassoc ? /\A(.+)\+(.+?)\Z/ : /\A(.+?)\+(.+)\Z/ ).match(str)
				a, _ = minc_sub(stack, m[1], lassoc)
				b, _ = minc_sub(stack, m[2], lassoc)
				[a+b, [a, b].max]
			elsif m = /\A\<(\d+)\>\Z/.match(str)
				[stack[m[1].to_i], 1]
			else
				[smith(str, 0, true).star, 1]
			end
		end
		
		def min_smith(str, left_associative: true)
			str = Mgmg.check_string(str)
			stack, str = mins_sub0([], str)
			(([mins_sub(stack, str, left_associative)]+stack).max-1)*3
		end
		private def mins_sub0(stack, str)
			SystemEquip.each do |k, v|
				if Regexp.compile(k).match(str)
					stack << 0
					str = str.gsub(k, "<#{stack.length-1}>")
				end
			end
			[stack, str]
		end
		private def mins_sub(stack, str, lassoc)
			if m = /\A(.*\+?)\[([^\[\]]+)\](\+?[^\[]*)\Z/.match(str)
				stack << mins_sub(stack, m[2], lassoc)
				mins_sub(stack, "#{m[1]}<#{stack.length-1}>#{m[3]}", lassoc)
			elsif m = ( lassoc ? /\A(.+)\+(.+?)\Z/ : /\A(.+?)\+(.+)\Z/ ).match(str)
				[mins_sub(stack, m[1], lassoc), mins_sub(stack, m[2], lassoc)].max
			elsif m = /\A\<(\d+)\>\Z/.match(str)
				1
			else
				mins_sub2(str)
			end
		end
		private def mins_sub2(str)
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
			[main_s, sub_s].max
		end
	end
end
