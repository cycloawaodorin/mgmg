module Mgmg
	module Refiner
		refine Module do
			private def private_module_function(sym)
				module_function(sym)
				singleton_class.instance_eval do
					private(sym)
				end
			end
		end
		refine Integer do
			def comma3
				self.to_s.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,')
			end
			
			# 0への丸めを行う整数除
			def cdiv(other)
				if self < 0
					-(-self).div(other)
				else
					self.div(other)
				end
			end
			
			alias :to_ii :itself
		end
		refine Float do
			alias :cdiv :quo # Floatの場合は普通の割り算
			def comma3
				s = (self*100).round.to_s
				if s[0] == '-'
					g, s = '-', s[1..(-1)]
				else
					g = ''
				end
				raise unless %r|\A\d+\Z|.match(s)
				case s.length
				when 1
					if s == '0'
						'0.0'
					else
						g+'0.0'+s
					end
				when 2
					if s[1] == '0'
						g+'0.'+s[0]
					else
						g+'0.'+s
					end
				else
					i, d = s[0..(-3)], s[(-2)..(-1)]
					d = d[0] if d[1] == '0'
					g+i.gsub(/(\d)(?=(\d{3})+(?!\d))/, '\1,') + '.' + d
				end
			rescue
				self.to_s
			end
		end
		refine Rational do
			alias :cdiv :quo # Rationalの場合は普通の割り算
			def comma3
				if self.denominator == 1
					self.numerator.comma3
				else
					self.to_f.comma3
				end
			end
			
			def to_ii
				if self.denominator == 1
					self.numerator
				else
					self
				end
			end
		end
	end
	using Refiner
	
	class InvalidCharacterError < StandardError
		def initialize(match)
			@wchar = match[0]
			super("`#{@wchar}' is not a valid character for recipes")
		end
		attr_accessor :wchar
	end
	class InvalidBracketError < StandardError; end
	class InvalidSmithError < StandardError
		def initialize(str)
			@recipe = str
			super("`#{@recipe}' is not a valid recipe for smithing")
		end
		attr_accessor :recipe
	end
	class InvalidMaterialError < StandardError
		def initialize(str)
			@material = str
			super("`#{@material}' is not a valid material name")
		end
		attr_accessor :material
	end
	class InvalidEquipClassError < StandardError
		def initialize(str)
			@equip = str
			super("`#{@equip}' is not a valid equip class name")
		end
		attr_accessor :equip
	end
	class InvalidReinforcementNameError < StandardError
		def initialize(str)
			@name = str
			super("Unknown skill or preset cuisine name `#{@name}' is given.")
		end
		attr_accessor :name
	end
	class InvalidRecipeError < StandardError
		def initialize(msg=nil)
			if msg.nil?
				super("Neither String nor Enumerable recipe was set.")
			else
				super(msg)
			end
		end
	end
	class Over20Error < StandardError
		def initialize(star)
			super("The star of given recipe is #{star}. It can't be built since the star is over 20.")
		end
	end
	class SearchCutException < StandardError; end
	class UnexpectedError < StandardError
		def initialize()
			super("There is a bug in `mgmg' gem. Please report to https://github.com/cycloawaodorin/mgmg/issues .")
		end
	end
	
	module_function def exp(smith, armor, comp=armor.tap{armor=0})
		if armor <= 0
			if smith <= 0
				if comp <= 0
					0
				else
					(2*((comp-1)**2)) + 2
				end
			else
				if comp <= 0
					((smith-1)**2) + 1
				else
					((smith-1)**2) + (2*((comp-1)**2)) + 3
				end
			end
		else
			if smith <= 0
				if comp <= 0
					((armor-1)**2) + 1
				else
					((armor-1)**2) + (2*((comp-1)**2)) + 3
				end
			else
				if comp <= 0
					((smith-1)**2) + ((armor-1)**2) + 2
				else
					((smith-1)**2) + ((armor-1)**2) + (2*((comp-1)**2)) + 4
				end
			end
		end
	end
	module_function def invexp2(exp, comp)
		raise ArgumentError, "exp must be finite" unless exp.finite?
		begin
			ret = Math.sqrt(exp - (2*((comp-1)**2)) - 3).floor + 2
		rescue Math::DomainError
			return -1
		end
		if Mgmg.exp(ret, comp) <= exp
			ret
		else
			ret-1
		end
	end
	module_function def invexp2c(exp, s)
		raise ArgumentError, "exp must be finite" unless exp.finite?
		begin
			ret = Math.sqrt((exp - (((s-1)**2)) - 3).quo(2)).floor + 2
		rescue Math::DomainError
			return -1
		end
		if Mgmg.exp(s, ret) <= exp
			ret
		else
			ret-1
		end
	end
	module_function def invexp3(exp, sa, comp)
		raise ArgumentError, "exp must be finite" unless exp.finite?
		return invexp2(exp, comp) if sa < 0
		begin
			ret = Math.sqrt(exp - ((sa-1)**2) - (2*((comp-1)**2)) - 4).floor + 2
		rescue Math::DomainError
			return -1
		end
		if Mgmg.exp(ret, sa, comp) <= exp
			ret
		else
			ret-1
		end
	end
	module_function def invexp3c(exp, smith, armor)
		raise ArgumentError, "exp must be finite" unless exp.finite?
		if smith < 0
			return invexp2c(exp, armor)
		elsif armor < 0
			return invexp2c(exp, smith)
		end
		begin
			ret = Math.sqrt((exp - ((smith-1)**2) - ((armor-1)**2) - 4).quo(2)).floor + 2
		rescue Math::DomainError
			return -1
		end
		if Mgmg.exp(smith, armor, ret) <= exp
			ret
		else
			ret-1
		end
	end
	module_function def clear_cache
		CacheMLS.clear; Equip::Cache.clear; Equip::CacheML.clear; TPolynomial::Cache.clear; IR::Cache.clear
		nil
	end
	
	CharacterList = /[^\(\)\+0123456789\[\]あきくしすたてなねのびりるイウガクグサジスタダチツデトドニノフブペボムラリルロンヴー一万二光兜典刀剣劣匠双古名吹咆品哮地大天太子安宝小帽弓弩当息悪戦手指斧書服木本杖業樹歴殺水氷法火炎牙物玉王産用界異的皮盾短石砕竜紫綿耳聖脛腕腿般良色衣袋覇質軍軽輝輪重量金鉄鎧闇陽靴額飾首骨鬼龍]/.freeze
	module_function def check_string(str)
		str = str.gsub(/[\s　\\]/, '')
		if m = CharacterList.match(str)
			raise InvalidCharacterError.new(m)
		end
		levels = [0, 0]
		str.each_char do |c|
			if c == '('
				if levels[0] == 0
					levels[0] = 1
				else
					raise InvalidBracketError.new("parentheses cannot be nested")
				end
			elsif c == ')'
				if levels[0] == 0
					raise InvalidBracketError.new("parentheses must be opened before closing")
				else
					levels[0] -= 1
				end
			elsif c == '['
				if levels[0] != 0
					raise InvalidBracketError.new("brackets cannot be nested in parentheses")
				else
					levels[1] += 1
				end
			elsif c == ']'
				if levels[0] != 0
					raise InvalidBracketError.new("parentheses must be closed before closing brackets")
				elsif levels[1] == 0
					raise InvalidBracketError.new("brackets must be opened before closing")
				else
					levels[1] -= 1
				end
			end
		end
		if levels[0] != 0
			raise InvalidBracketError.new("parentheses must be closed")
		elsif levels[1] != 0
			raise InvalidBracketError.new("brackets must be closed")
		end
		str
	end
	
	module_function def parse_material(str)
		m = /\A.+?(\d+)\Z/.match(str)
		mat = MaterialIndex[str.to_sym]
		if m.nil? || mat.nil?
			raise InvalidMaterialError.new(str)
		end
		[mat, m[1].to_i, mat<90 ? mat.div(10) : 9]
	end
	
	class Vec < Array
		def add!(other)
			case other
			when Array
				self.map!.with_index do |e, i|
					e + other[i]
				end
			else
				self.map! do |e|
					e + other
				end
			end
			self
		end
		def sub!(other)
			case other
			when Array
				self.map!.with_index do |e, i|
					e - other[i]
				end
			else
				self.map! do |e|
					e - other
				end
			end
			self
		end
		def e_mul!(other)
			case other
			when Array
				self.map!.with_index do |e, i|
					e * other[i]
				end
			else
				self.map! do |e|
					e * other
				end
			end
			self
		end
		def e_div!(other)
			case other
			when Array
				self.map!.with_index do |e, i|
					e.cdiv(other[i])
				end
			else
				self.map! do |e|
					e.cdiv(other)
				end
			end
			self
		end
		def self.irange(size)
			Vec.new(size, &:itself)
		end
		def []=(*arg)
			case arg.size
			when 1
				self.replace(arg[0])
				arg[0]
			else
				super
			end
		end
	end
	
	class Mat
		def initialize(m, n, value=nil)
			if block_given?
				@body = Array.new(m) do |i|
					Array.new(n) do |j|
						yield(i, j)
					end
				end
			else
				@body = Array.new(m) do
					Array.new(n, value)
				end
			end
		end
		attr_accessor :body
		def initialize_copy(obj)
			@body = obj.body.map(&:dup)
		end
		def row_size
			@body.length
		end
		def col_size
			@body[0].length
		end
		def shape
			[row_size(), col_size()]
		end
		def each_with_index
			@body.each.with_index do |row, i|
				row.each.with_index do |e, j|
					yield(e, i, j)
				end
			end
			self
		end
		def map_with_index!
			@body.each.with_index do |row, i|
				row.map!.with_index do |e, j|
					yield(e, i, j)
				end
			end
			self
		end
		def map_with_index(&block)
			dup.map_with_index!(&block)
		end
		def submat_add!(is, js, other)
			i_s, i_e = index_treatment(is, row_size)
			j_s, j_e = index_treatment(js, col_size)
			i_s.upto(i_e).with_index do |i, io|
				row = @body[i]
				o_row = other.body[io]
				j_s.upto(j_e).with_index do |j, jo|
					row[j] += o_row[jo]
				end
			end
			self
		end
		private def index_treatment(idx, max)
			case idx
			when Integer
				[idx, idx]
			when Range
				if idx.exclude_end?
					[idx.first, idx.last-1]
				else
					[idx.first, idx.last]
				end
			when Array
				[idx[0], idx[0]+idx[1]-1]
			when nil
				[0, max]
			else
				raise ArgumentError, "#{idx.class} is not available for Mat index"
			end.map! do |i|
				i < 0 ? max-i : i
			end
		end
		def scalar!(value)
			self.map_with_index! do |e, i, j|
				e * value
			end
		end
		def scalar(value)
			self.dup.scalar!(value)
		end
		def sum
			@body.map(&:sum).sum
		end
		def pprod(other)
			r, c = row_size, col_size
			ret = self.class.new(r+other.row_size-1, c+other.col_size-1, 0)
			other.each_with_index do |o, i, j|
				ret.submat_add!(i...(i+r), j...(j+c), scalar(o))
			end
			ret
		end
		def padd(other)
			ret = self.class.new([row_size, other.row_size].max, [col_size, other.col_size].max, 0)
			ret.submat_add!(0...row_size, 0...col_size, self)
			ret.submat_add!(0...(other.row_size), 0...(other.col_size), other)
		end
	end
	class << Mat
		def v_array(*ary)
			new(ary.length, 1) do |i, j|
				ary[i]
			end
		end
		def h_array(*ary)
			new(1, ary.length) do |i, j|
				ary[j]
			end
		end
	end
end
