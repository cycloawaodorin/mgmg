module Mgmg
	using Refiner
	class TPolynomial
		def initialize(mat, kind, star, main_m, sub_m)
			@mat, @kind, @star, @main, @sub = mat, kind, star, main_m, sub_m
		end
		attr_accessor :mat, :kind, :star, :main, :sub
		def initialize_copy(obj)
			@mat, @kind, @star, @main, @sub = obj.mat.dup, obj.kind, obj.star, obj.main, obj.sub
		end
		def evaluate(smith, comp=smith)
			@mat.map_with_index do |e, i, j|
				e * (smith**i) * (comp**j)
			end.sum
		end
		def to_s(fmt=nil)
			foo = []
			(@mat.col_size-1).downto(0) do |c|
				bar = []
				(@mat.row_size-1).downto(0) do |s|
					value = @mat.body[s][c]
					baz = str(value, fmt)
					case s
					when 0
						# nothing to do
					when 1
						baz << 'S'
					else
						baz << "S^#{s}"
					end
					bar << baz if value != 0
				end
				case bar.length
				when 0
					next
				when 1
					bar = bar[0]
				else
					bar = "(#{bar.join('+')})"
				end
				case c
				when 0
					# nothing to do
				when 1
					bar << 'C'
				else
					bar << "C^#{c}"
				end
				foo << bar
			end
			foo.join('+').tap{|r| break str(0.quo(1), fmt) if r==''}
		end
		private def str(value, fmt)
			ret = case fmt
			when NilClass
				value.to_s
			when String
				fmt % value
			when Symbol
				value.__send__(fmt)
			when Proc
				fmt.call(value)
			else
				raise
			end
			if ret[0] == '-' || ( /\//.match(ret) && ret[0] != '(' )
				"(#{ret})"
			else
				ret
			end
		end
		def inspect(fmt=->(r){"Rational(#{r.numerator}, #{r.denominator})"})
			foo = []
			(@mat.col_size-1).downto(0) do |c|
				bar = []
				(@mat.row_size-1).downto(0) do |s|
					value = @mat.body[s][c]
					bar << str(value, fmt)
				end
				buff = bar[0]
				buff = "#{buff}*s+#{bar[1]}" if 1 < bar.length
				2.upto(bar.length-1) do |i|
					buff = "(#{buff})*s+#{bar[i]}"
				end
				foo << buff
			end
			ret = foo[0]
			1.upto(foo.length-1) do |i|
				ret = "(#{ret})*c+#{foo[i]}"
			end
			ret
		end
		def leading(fmt=nil)
			value = self[-1, -1]
			if fmt.nil?
				value
			else
				str(value, fmt)
			end
		end
		def smith_balance(other, order=-1)
			o_org = order
			order += @mat.col_size if order < 0
			if order < 0 || @mat.col_size <= order || other.mat.col_size <= order then
				raise ArgumentError, "given order #{o_org} is out of range [-max(#{@mat.col_size}, #{other.mat.col_size}), max(#{@mat.col_size}, #{other.mat.col_size})-1]"
			end
			a, b, c, d = @mat.body[1][order], @mat.body[0][order], other.mat.body[1][order], other.mat.body[0][order]
			if a == c
				return( b == d )
			else
				return( (d-b).quo(a-c) )
			end
		end
		def smith_fix(smith, fmt=nil)
			foo = []
			(@mat.col_size-1).downto(0) do |c|
				bar = 0
				(@mat.row_size-1).downto(0) do |s|
					bar += ( @mat.body[s][c] * (smith**s) )
				end
				bar = str(bar, fmt)
				case c
				when 0
					# nothing to do
				when 1
					bar << 'C'
				else
					bar << "C^#{c}"
				end
				foo << bar
			end
			foo.join('+')
		end
		
		alias :+@ :dup
		def -@
			ret = self.dup
			ret.mat.scalar!(-1)
			ret
		end
		def +(other)
			mat = @mat.padd(other.mat)
			self.class.new(mat, 28, 0, 12, 12)
		end
		def -(other)
			mat = @mat.padd(other.mat.scalar(-1))
			self.class.new(mat, 28, 0, 12, 12)
		end
		def scalar(val)
			ret = self.dup
			ret.mat.scalar!(val)
			ret
		end
		alias :* :scalar
		def quo(val)
			ret = self.dup
			ret.mat.scalar!(1.quo(val))
			ret
		end
		alias :/ :quo
		
		def partial_derivative(variable)
			case variable.to_s
			when /\Ac/i
				if @mat.col_size <= 1
					self.class.new(Mat.new(1, 1, 0), 28, 0, 12, 12)
				else
					mat = Mat.new(@mat.row_size, @mat.col_size-1) do |i, j|
						@mat.body[i][j+1] * (j+1)
					end
					self.class.new(mat, 28, 0, 12, 12)
				end
			when /\As/i
				if @mat.row_size <= 1
					self.class.new(Mat.new(1, 1, 0), 28, 0, 12, 12)
				else
					mat = Mat.new(@mat.row_size-1, @mat.col_size) do |i, j|
						@mat.body[i+1][j] * (i+1)
					end
					self.class.new(mat, 28, 0, 12, 12)
				end
			else
				raise ArgumentError, "the argument must be `s' or `c', not `#{variable}'"
			end
		end
		def smith_eff(smith, comp=smith)
			partial_derivative('s').evaluate(smith, comp).quo(2*(smith-1))
		end
		def comp_eff(smith, comp=smith)
			partial_derivative('c').evaluate(smith, comp).quo(4*(comp-1))
		end
		def eff(smith, comp=smith)
			[smith_eff(smith, comp), comp_eff(smith, comp)]
		end
		
		def [](i, j)
			if (i < 0 && @mat.body.size < -i) || (j < 0 && @mat.body[0].size < -j)
				raise IndexError, "(#{i}, #{j}) is out of (#{@mat.body.size}, #{@mat.body[0].size})"
			end
			begin
				ret = @mat.body[i][j]
			rescue NoMethodError
				return 0
			end
			ret.nil? ? 0 : ret
		end
	end
	class << TPolynomial
		ParamIndex = Hash.new
		%i|attack phydef magdef hp mp str dex speed magic|.each.with_index do |s, i|
			ParamIndex.store(s, i)
			ParamIndex.store(i, i)
			ParamIndex.store(Equip::ParamList[i], i)
		end
		def from_equip(equip, para)
			new(Mat.new(1, 1, equip.para[ParamIndex[para]]), equip.kind, equip.star, equip.main, equip.sub)
		end
		def smith(str, para)
			unless m = /\A(.+)\((.+\d+),?(.+\d+)\)\Z/.match(str)
				raise ArgumentError.new("given string `#{str}' is unparsable as a smithing recipe")
			end
			kind = EquipIndex[m[1].to_sym]
			main_m, main_s, main_mc = Equip.__send__(:parse_material, m[2])
			sub_m, sub_s, sub_mc = Equip.__send__(:parse_material, m[3])
			para = ParamIndex[para]
			
			c = ( Equip9[kind][para] * Main9[main_m][para] ).cdiv(100).quo( main_mc==sub_mc ? 200 : 100 )
			new(Mat.v_array(c*Sub9[sub_m][para], c), kind, (main_s+sub_s).div(2), main_mc, sub_mc)
		end
		def compose(main, sub, para)
			main_k, sub_k = main.kind, sub.kind
			main_s, sub_s = main.star, sub.star
			main_main, sub_main = main.main, sub.main
			main_sub, sub_sub = main.sub, sub.sub
			para = ParamIndex[para]
			
			if Equip9[main_k][para] == 0
				c = 0.quo(1)
			else
				c = ( 100 + Equip9[main_k][para] - Equip9[sub_k][para] + Material9[main_main][para] - Material9[sub_main][para] +
					(main_s-sub_s)*5 - ( ( main_main==sub_main && main_main != 9 ) ? 30 : 0 ) ).quo( main_k==sub_k ? 40000 : 20000 )
			end
			mat = main.mat.padd(sub.mat.pprod(Mat.h_array(c*Equip9[main_k][para], c)))
			new(mat, main_k, main_s+sub_s, main_sub, sub_main)
		end
		def build(str, para, left_associative: true)
			str = Mgmg.check_string(str)
			_para = ParamIndex[para]
			if _para.nil?
				raise ArgumentError, "unknown parameter symbol `#{para.inspect}' given"
			end
			stack, str = build_sub0([], str, _para)
			build_sub(stack, str, _para, left_associative)
		end
		private def build_sub0(stack, str, para)
			SystemEquip.each do |k, v|
				stack << from_equip(v, para)
				str = str.gsub(k, "<#{stack.length-1}>")
			end
			[stack, str]
		end
		private def build_sub(stack, str, para, lassoc)
			if m = /\A(.*\+?)\[([^\[\]]+)\](\+?[^\[]*)\Z/.match(str)
				stack << build_sub(stack, m[2], para, lassoc)
				build_sub(stack, "#{m[1]}<#{stack.length-1}>#{m[3]}", para, lassoc)
			elsif m = ( lassoc ? /\A(.+)\+(.+?)\Z/ : /\A(.+?)\+(.+)\Z/ ).match(str)
				compose(build_sub(stack, m[1], para, lassoc), build_sub(stack, m[2], para, lassoc), para)
			elsif m = /\A\<(\d+)\>\Z/.match(str)
				stack[m[1].to_i]
			else
				smith(str, para)
			end
		end
	end
end
