module Mgmg
	CacheMLS = Hash.new
	using Refiner
	class Equip
		Cache, CacheML = Hash.new, Hash.new
		ParamList = %w|攻撃 物防 魔防 HP MP 腕力 器用 素早 魔力|
		ElementList = %w|火 地 水|
		EqPosList = %w|武 頭 胴 腕 足 飾|
		def initialize(kind, weight, star, main_m, sub_m, para, element)
			@kind, @weight, @star, @main, @sub, @para, @element = kind, weight, star, main_m, sub_m, para, element
			@total_cost = Vec[0, 0, 0]
			@history, @min_levels = [self], Hash.new
		end
		attr_accessor :kind, :weight, :star, :main, :sub, :para, :element, :total_cost, :history
		def initialize_copy(other)
			@kind = other.kind
			@weight = other.weight
			@star = other.star.dup
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
		
		def min_levels(w=1)
			if w == 1
				@min_levels
			else
				@min_levels.map do |key, value|
					[key, Equip.min_level(key, w)]
				end.to_h
			end
		end
		def min_levels_max(w=1)
			if @kind == 28
				ret = [-1, -1]
				min_levels(w).each do |str, ml|
					if str.build.kind < 8
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
				min_levels(w).values.append(-1).max
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
			( attack()+str().quo(2)+dex().quo(2) ).to_ii
		end
		def dex_as
			( attack().quo(2)+str().quo(2)+dex() ).to_ii
		end
		def mag_das
			( magic()+dex_as().quo(2) ).to_ii
		end
		def magic2
			magic()*2
		end
		def hs
			hp()+str()
		end
		[:fire, :earth, :water].each.with_index do |s, i|
			define_method(s){ @element[i] }
		end
		
		def power
			case @kind
			when 0, 1
				atk_sd()
			when 2, 3
				atkstr()
			when 4
				[dex_as(), mag_das()].max
			when 5
				dex_as()
			when 6, 7
				[magic()*2, atkstr()].max
			when 28
				( @para.sum-((hp()+mp())*3.quo(4)) ).to_ii
			else
				ret = @para.max
				if ret == magdef()
					( ret+magic().quo(2) ).to_ii
				else
					ret
				end
			end
		end
		def magmag
			( magdef()+magic().quo(2) ).to_ii
		end
		def fpower
			power().to_f
		end
		def pmdef
			[phydef(), magmag()].min
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
				[(@star**2)*5+@para.sum+hp().cdiv(4)-hp()+mp().cdiv(4)-mp(), 0].max.div(2)
			else
				[((@star**2)*5+@para.sum+hp().cdiv(4)-hp()+mp().cdiv(4)-mp()).div(2), 0].max.div(2)
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
			@main, @sub = 12, 12
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
		Zero = self.new(28, 0, Vec.new(6, 0).freeze, 12, 12, Vec.new(9, 0).freeze, Vec.new(3, 0).freeze)
		Zero.total_cost.freeze; Zero.history.clear.freeze
		Zero.freeze
		
		class << self
			def build(str, s_level, c_level, left_associative: true, include_system_equips: true)
				str = Mgmg.check_string(str)
				stack = []
				stack, str = build_sub0(stack, str) if include_system_equips
				build_sub(stack, str, s_level, c_level, left_associative)
			end
			private def build_sub0(stack, str)
				SystemEquip.each do |k, v|
					if SystemEquipRegexp[k].match(str)
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
				cc = ret.comp_cost(outsourcing)
				ret.total_cost[1] += cc
				ret.total_cost[main_k < 8 ? 0 : 2] += cc
				ret.min_levels.merge!(main.min_levels, sub.min_levels)
				ret.history = [*main.history, *sub.history, ret]
				ret
			end
			
			def smith(str, level, outsourcing)
				str = Mgmg.check_string(str)
				return Cache[str].dup if level==0 && Cache.has_key?(str)
				unless m = /\A(.+)\((.+\d+),?(.+\d+)\)\Z/.match(str)
					raise InvalidSmithError.new(str)
				end
				kind = EquipIndex[m[1].to_sym]
				unless kind
					raise InvalidEquipClassError.new(m[1])
				end
				main_m, main_s, main_mc = Mgmg.parse_material(m[2])
				sub_m, sub_s, sub_mc = Mgmg.parse_material(m[3])
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
				ret.total_cost[kind < 8 ? 0 : 2] += ret.smith_cost(outsourcing)
				ret.min_levels.store(str, Equip.min_level(str))
				Cache.store(str, ret.freeze) if level==0
				ret.dup
			end
			
			def min_level(str, weight=1)
				str = Mgmg.check_string(str)
				key = [str.dup.freeze, weight].freeze
				return CacheML[key] if CacheML.has_key?(key)
				unless m = /\A(.+)\((.+\d+),?(.+\d+)\)\Z/.match(str)
					raise InvalidSmithError.new(str)
				end
				kind = EquipIndex[m[1].to_sym]
				main_m, main_s, = Mgmg.parse_material(m[2])
				sub_m, sub_s, = Mgmg.parse_material(m[3])
				
				q, r = ((weight+1)*10000).divmod(MainWeight[main_m])
				l = ( EquipWeight[kind] + SubWeight[sub_m] - q + ( r==0 ? 1 : 0 ) )*2
				ret = [(main_s-1)*3, (sub_s-1)*3, l].max
				CacheML.store(key, ret)
				ret
			end
			
			def min_comp(str, opt: Option.new)
				str = Mgmg.check_string(str)
				stack = []
				stack, str = minc_sub0(stack, str) if opt.include_system_equips
				(minc_sub(stack, str, opt.left_associative)[1]-1)*3
			end
			private def minc_sub0(stack, str)
				SystemEquip.each do |k, v|
					if SystemEquipRegexp[k].match(str)
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
			
			def min_smith(str, opt: Option.new)
				str = Mgmg.check_string(str)
				stack = []
				stack, str = mins_sub0(stack, str) if opt.include_system_equips
				ret = (([mins_sub(stack, str, opt.left_associative)]+stack).max-1)*3
				ret < 0 ? -1 : ret
			end
			private def mins_sub0(stack, str)
				SystemEquip.each do |k, v|
					if SystemEquipRegexp[k].match(str)
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
					0
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
				main_m, main_s, main_mc = Mgmg.parse_material(m[2])
				sub_m, sub_s, sub_mc = Mgmg.parse_material(m[3])
				[main_s, sub_s].max
			end
		end
	end
end
