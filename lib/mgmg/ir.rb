module Mgmg
	using Refiner
	class IR
		Cache = Hash.new
		class Const
			def initialize(value)
				@value = value
			end
			attr_accessor :value
			def initialize_copy(other)
				@value = other.value
			end
			def evaluate(s, c)
				@value
			end
			def evaluate3(s, a, c)
				@value
			end
			def to_s
				@value.to_s
			end
		end
		class Smith
			def initialize(sub9, coef, den, sa=nil)
				@sub9, @coef, @den, @sa = sub9, coef, den, sa
			end
			attr_accessor :sub9, :coef, :den, :sa
			def initialize_copy(other)
				@sub9, @coef, @den, @sa = other.sub9, other.coef, other.den, other.sa
			end
			def evaluate(s, c)
				((s+@sub9)*@coef).div(@den)
			end
			def evaluate3(s, a, c)
				if @sa==:a
					((a+@sub9)*@coef).div(@den)
				else
					((s+@sub9)*@coef).div(@den)
				end
			end
			def to_s
				if sa==:a
					"[#{@coef}(a+#{@sub9})/#{den}]"
				else
					"[#{@coef}(s+#{@sub9})/#{den}]"
				end
			end
		end
		class Compose
			def initialize(main, sub, equip9, coef, den)
				@main, @sub, @equip9, @coef, @den = main, sub, equip9, coef, den
			end
			attr_accessor :main, :sub, :equip9, :coef, :den
			def initialize_copy(other)
				@main, @sub = other.main.dup, other.sub.dup
				@equip9, @coef, @den = other.equip9, other.coef, other.den
			end
			def evaluate(s, c)
				@main.evaluate(s, c) + ( ( @sub.evaluate(s, c) * (c+@equip9).div(2) ).cdiv(100) * @coef ).cdiv(@den)
			end
			def evaluate3(s, a, c)
				@main.evaluate3(s, a, c) + ( ( @sub.evaluate3(s, a, c) * (c+@equip9).div(2) ).cdiv(100) * @coef ).cdiv(@den)
			end
			def to_s
				ms, ss = @main.to_s, @sub.to_s
				if ss == '0'
					ms
				else
					if ms == '0'
						"[[#{ss}[(c+#{@equip9})/2]/100]/#{@den}]"
					else
						"#{ms}+[[#{ss}[(c+#{@equip9})/2]/100]/#{@den}]"
					end
				end
			end
		end
		class Multi
			def initialize(body)
				@body = body
			end
			attr_accessor :body
			def initialize_copy(other)
				@body = other.body.dup
			end
			def evaluate(s, c)
				@body.sum do |e|
					e.evaluate(s, c)
				end
			end
			def evaluate3(s, a, c)
				@body.sum do |e|
					e.evaluate3(s, a, c)
				end
			end
			def to_s
				@body.map(&:to_s).join('+')
			end
			class << self
				def sum(a, b)
					unconsts, const = [], Const.new(0)
					case a
					when Multi
						if a.body[0].kind_of?(Const)
							const.value += a.body[0].value
							unconsts = a.body[1..(-1)]
						else
							unconsts = a.body.dup
						end
					when Const
						const.value += a.value
					else
						unconsts << a
					end
					case b
					when Multi
						if b.body[0].kind_of?(Const)
							const.value += b.body[0].value
							unconsts.concat(b.body[1..(-1)])
						else
							unconsts.concat(b.body)
						end
					when Const
						const.value += b.value
					else
						unconsts << b
					end
					body = ( const.value == 0 ? unconsts : [const, *unconsts] )
					case body.size
					when 0
						const
					when 1
						body[0]
					else
						new(body)
					end
				end
			end
		end
		def initialize(kind, star, main_m, sub_m, para, rein=[])
			@kind, @star, @main, @sub, @para = kind, star, main_m, sub_m, para
			add_reinforcement(rein)
		end
		def add_reinforcement(rein)
			@rein = if rein.kind_of?(Array)
				rein.map do |r|
					Reinforcement.compile(r)
				end
			else
				[Reinforcement.compile(rein)]
			end
			self
		end
		attr_accessor :kind, :star, :main, :sub, :para, :rein
		def initialize_copy(other)
			@kind = other.kind
			@star = other.star.dup
			@main = other.main
			@sub = other.sub
			@para = other.para.dup
			@rein = other.rein.dup
		end
		
		def compose(other)
			self.class.compose(self, other)
		end
		
		def to_s
			par = @para.map.with_index{|e, i| e.to_s=='0' ? nil : "#{Mgmg::Equip::ParamList[i]}:#{e.to_s}"}.compact
			if @kind == 28
				ep = @star.map.with_index{|e, i| e==0 ? nil : "#{Mgmg::Equip::EqPosList[i]}:#{e}"}.compact
				"複数装備(#{ep.join(', ')})<#{par.join(', ')}>#{@rein.empty? ? '' : '{'+@rein.join(',')+'}'}"
			else
				"#{EquipName[@kind]}☆#{@star}(#{MaterialClass[@main]}#{MaterialClass[@sub]})<#{par.join(', ')}>#{@rein.empty? ? '' : '{'+@rein.join(',')+'}'}"
			end
		end
		
		def para_call(para, s, ac, x=nil)
			if x.nil?
				method(para).call(s, ac)
			else
				method(para).call(s, ac, x)
			end
		end
		
		%i|attack phydef magdef hp mp str dex speed magic|.each.with_index do |sym, i|
			define_method(sym) do |s=nil, ac=s, x=nil|
				ret = if s.nil?
					@para[i]
				elsif x.nil?
					@para[i].evaluate(s, ac)
				else
					@para[i].evaluate3(s, ac, x)
				end
				@rein.each do |r|
					if r.vec[i] != 0
						ret *= (100+r.vec[i]).quo(100)
					end
				end
				ret.to_ii
			end
		end
		def atkstr(s, ac, x=nil)
			attack(s, ac, x)+str(s, ac, x)
		end
		def atk_sd(s, ac, x=nil)
			( attack(s, ac, x)+str(s, ac, x).quo(2)+dex(s, ac, x).quo(2) ).to_ii
		end
		def dex_as(s, ac, x=nil)
			( attack(s, ac, x).quo(2)+str(s, ac, x).quo(2)+dex(s, ac, x) ).to_ii
		end
		def mag_das(s, ac, x=nil)
			( magic(s, ac, x)+dex_as(s, ac, x).quo(2) ).to_ii
		end
		def magic2(s, ac, x=nil)
			magic(s, ac, x)*2
		end
		def magmag(s, ac, x=nil)
			( magdef(s, ac, x)+magic(s, ac, x).quo(2) ).to_ii
		end
		def pmdef(s, ac, x=nil)
			[phydef(s, ac, x), magmag(s, ac, x)].min
		end
		def hs(s, ac, x=nil)
			hp(s, ac, x)+str(s, ac, x)
		end
		
		def power(s, a=s, c=a.tap{a=s})
			case @kind
			when 0, 1
				atk_sd(s, c)
			when 2, 3
				atkstr(s, c)
			when 4
				[dex_as(s, c), mag_das(s, c)].max
			when 5
				dex_as(s, c)
			when 6, 7
				[magic(s, c)*2, atkstr(s, c)].max
			when 28
				( @para.enum_for(:sum).with_index do |e, i|
					x = e.evaluate3(s, a, c)
					@rein.each do |r|
						if r.vec[i] != 0
							x *= (100+r.vec[i]).quo(100)
						end
					end
					x
				end - ((hp(s, a, c)+mp(s, a, c))*3.quo(4)) ).to_ii
			else
				ret = @para.map.with_index do |e, i|
					x = e.evaluate3(s, a, c)
					@rein.each do |r|
						if r.vec[i] != 0
							x *= (100+r.vec[i]).quo(100)
						end
					end
					x
				end.max.to_ii
				if ret == magdef(s, a, c)
					( ret+magic(s, a, c).quo(2) ).to_ii
				else
					ret
				end
			end
		end
		def fpower(s, a=s, c=a.tap{a=s})
			power(s, a, c).to_f
		end
		
		def smith_cost(s, c=s, outsourcing=false)
			if outsourcing
				if @kind < 8
					(@star**2)*2+@para.sum{|e| e.evaluate(s, c)}+hp(s, c).cdiv(4)-hp(s, c)+mp(s, c).cdiv(4)-mp(s, c)
				else
					(@star**2)+@para.sum{|e| e.evaluate(s, c)}+hp(s, c).cdiv(4)-hp(s, c)+mp(s, c).cdiv(4)-mp(s, c)
				end
			else
				if @kind < 8
					((@star**2)*2+@para.sum{|e| e.evaluate(s, c)}+hp(s, c).cdiv(4)-hp(s, c)+mp(s, c).cdiv(4)-mp(s, c)).div(2)
				else
					((@star**2)+@para.sum{|e| e.evaluate(s, c)}+hp(s, c).cdiv(4)-hp(s, c)+mp(s, c).cdiv(4)-mp(s, c)).div(2)
				end
			end
		end
		def comp_cost(s, c=s, outsourcing=false)
			if outsourcing
				[(@star**2)*5+@para.sum{|e| e.evaluate(s, c)}+hp().cdiv(4)-hp()+mp().cdiv(4)-mp(), 0].max.div(2)
			else
				[((@star**2)*5+@para.sum{|e| e.evaluate(s, c)}+hp().cdiv(4)-hp()+mp().cdiv(4)-mp()).div(2), 0].max.div(2)
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
			@main, @sub = 12, 12
			@para = Array.new(9) do |i|
				Multi.sum(self.para[i], other.para[i])
			end
			self
		end
		def +(other)
			self.dup.add!(other)
		end
		Zero = self.new(28, Vec.new(6, 0).freeze, 12, 12, Array.new(9){Const.new(0)}.freeze)
		Zero.rein.freeze; Zero.freeze
		
		class << self
			def build(str, left_associative: true, reinforcement: [], include_system_equips: true)
				str = Mgmg.check_string(str)
				stack = []
				stack, str = build_sub0(stack, str) if include_system_equips
				build_sub(stack, str, left_associative).add_reinforcement(reinforcement)
			end
			private def build_sub0(stack, str)
				SystemEquip.each do |k, v|
					if SystemEquipRegexp[k].match(str)
						stack << from_equip(v)
						str = str.gsub(k, "<#{stack.length-1}>")
					end
				end
				[stack, str]
			end
			private def build_sub(stack, str, lassoc)
				if m = /\A(.*\+?)\[([^\[\]]+)\](\+?[^\[]*)\Z/.match(str)
					stack << build_sub(stack, m[2], lassoc)
					build_sub(stack, "#{m[1]}<#{stack.length-1}>#{m[3]}", lassoc)
				elsif m = ( lassoc ? /\A(.+)\+(.+?)\Z/ : /\A(.+?)\+(.+)\Z/ ).match(str)
					compose(build_sub(stack, m[1], lassoc), build_sub(stack, m[2], lassoc))
				elsif m = /\A\<(\d+)\>\Z/.match(str)
					stack[m[1].to_i]
				else
					smith(str)
				end
			end
			
			def compose(main, sub)
				main_k, sub_k = main.kind, sub.kind
				main_s, sub_s = main.star, sub.star
				main_main, sub_main = main.main, sub.main
				main_sub, sub_sub = main.sub, sub.sub
				
				coef = Equip9[main_k].dup
				coef.sub!(Equip9[sub_k])
				coef.add!( 100 + (main_s-sub_s)*5 - ( ( main_main==sub_main && main_main != 9 ) ? 30 : 0 ) )
				coef.add!(Material9[main_main]).sub!(Material9[sub_main])
				den = ( main_k==sub_k ? 200 : 100 )
				para = Array.new(9) do |i|
					if EquipFilter[main_k][i] == 0
						main.para[i]
					else
						Mgmg::IR::Compose.new(main.para[i], sub.para[i], Equip9[main_k][i], coef[i], den)
					end
				end
				
				new(main_k, main_s+sub_s, main_sub, sub_main, para)
			end
			def smith(str)
				str = Mgmg.check_string(str)
				return Cache[str].dup if Cache.has_key?(str)
				unless m = /\A(.+)\((.+\d+),?(.+\d+)\)\Z/.match(str)
					raise InvalidSmithError.new(str)
				end
				kind = EquipIndex[m[1].to_sym]
				unless kind
					raise InvalidEquipClassError.new(m[1])
				end
				main_m, main_s, main_mc = Mgmg.parse_material(m[2])
				sub_m, sub_s, sub_mc = Mgmg.parse_material(m[3])
				sa = ( Mgmg::EquipPosition[kind] == 0 ? :s : :a )
				
				coef = Equip9[kind].dup
				coef.e_mul!(Main9[main_m]).e_div!(100)
				den = ( main_mc==sub_mc ? 200 : 100 )
				para = Array.new(9) do |i|
					if coef[i] == 0
						Mgmg::IR::Const.new(0)
					else
						Mgmg::IR::Smith.new(Sub9[sub_m][i], coef[i], den, sa)
					end
				end
				
				ret = new(kind, (main_s+sub_s).div(2), main_mc, sub_mc, para)
				Cache.store(str, ret.freeze)
				ret.dup
			end
			def from_equip(equip)
				para = equip.para.map do |value|
					Mgmg::IR::Const.new(value)
				end
				new(equip.kind, equip.star, equip.main, equip.sub, para)
			end
		end
	end
end
