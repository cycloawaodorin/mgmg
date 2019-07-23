module Mgmg
	using(Module.new do
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
		end
	end)
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
	class Equip
		ParamList = %w|攻撃 物防 魔防 HP MP 腕力 器用 素早 魔力|
		ElementList = %w|火 地 水|
		EqPosList = %w|武 頭 胴 腕 足 飾|
		def initialize(kind, weight, star, main_m, sub_m, para, element)
			@kind, @weight, @star, @main, @sub, @para, @element = kind, weight, star, main_m, sub_m, para, element
			@total_cost = Vec[0, 0, 0]
		end
		attr_accessor :kind, :weight, :star, :main, :sub, :para, :element, :total_cost
		def initialize_copy(other)
			@kind = other.kind
			@weight = other.weight
			@star = other.star
			@main = other.main
			@sub = other.sub
			@para = other.para.dup
			@element = other.element.dup
			@total_cost = other.total_cost.dup
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
					@star.add(other.star)
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
			self
		end
		def +(other)
			self.dup.add!(other)
		end
		def coerce(other)
			if other == 0
				[self.class.new(28, 0, Vec.new(6, 0), 12, 12, Vec.new(9, 0), Vec.new(3, 0)), self]
			else
				raise TypeError, "Mgmg::Equip can't be coerced into other than 0"
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
		def scalar(value)
			dup.map_with_index! do |e, i, j|
				e * value
			end
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
	class TPolynomial
		def initialize(mat, kind, star, main_m, sub_m)
			@mat, @kind, @star, @main, @sub = mat, kind, star, main_m, sub_m
		end
		attr_accessor :mat, :kind, :star, :main, :sub
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
			foo.join('+')
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
				raise ArgumentError.new('given argument is unparsable')
			end
			kind = EquipIndex[m[1].to_sym]
			main_m, main_s, main_mc = Equip.__send__(:parse_material, m[2])
			sub_m, sub_s, sub_mc = Equip.__send__(:parse_material, m[3])
			para = ParamIndex[para]
			
			c = ( Equip9[kind][para] * Main9[main_m][para] ).quo( main_mc==sub_mc ? 20000 : 10000 )
			new(Mat.v_array(c*Sub9[sub_m][para], c), kind, (main_s+sub_s).div(2), main_mc, sub_mc)
		end
		def compose(main, sub, para)
			main_k, sub_k = main.kind, sub.kind
			main_s, sub_s = main.star, sub.star
			main_main, sub_main = main.main, sub.main
			main_sub, sub_sub = main.sub, sub.sub
			para = ParamIndex[para]
			
			c = ( 100 + Equip9[main_k][para] - Equip9[sub_k][para] + Material9[main_main][para] - Material9[sub_main][para] +
				(main_s-sub_s)*5 - ( ( main_main==sub_main && main_main != 9 ) ? 30 : 0 ) ).quo( main_k==sub_k ? 40000 : 20000 )
			mat = main.mat.padd(sub.mat.pprod(Mat.h_array(c*Equip9[main_k][para], c)))
			new(mat, main_k, main_s+sub_s, main_sub, sub_main)
		end
		def build(str, para, left_associative: true)
			para = ParamIndex[para]
			stack, str = build_sub0([], str, para)
			build_sub(stack, str.gsub(/[\s　]/, ''), para, left_associative)
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
	MaterialIndex = {
		'鉄1':  0, '鉄2':  1, '鉄3':  2, '鉄4':  3, '鉄5':  4, '鉄6':  5, '鉄7':  6, '鉄8':  7, '鉄9':  8, '鉄10':  9,
		'木1': 10, '木2': 11, '木3': 12, '木4': 13, '木5': 14, '木6': 15, '木7': 16, '木8': 17, '木9': 18, '木10': 19,
		'綿1': 20, '綿2': 21, '綿3': 22, '綿4': 23, '綿5': 24, '綿6': 25, '綿7': 26, '綿8': 27, '綿9': 28, '綿10': 29,
		'皮1': 30, '皮2': 31, '皮3': 32, '皮4': 33, '皮5': 34, '皮6': 35, '皮7': 36, '皮8': 37, '皮9': 38, '皮10': 39,
		'骨1': 40, '骨2': 41, '骨3': 42, '骨4': 43, '骨5': 44, '骨6': 45, '骨7': 46, '骨8': 47, '骨9': 48, '骨10': 49,
		'牙1': 50, '牙2': 51, '牙3': 52, '牙4': 53, '牙5': 54, '牙6': 55, '牙7': 56, '牙8': 57, '牙9': 58, '牙10': 59,
		'宝1': 60, '宝2': 61, '宝3': 62, '宝4': 63, '宝5': 64, '宝6': 65, '宝7': 66, '宝8': 67, '宝9': 68, '宝10': 69,
		'水1': 70, '水2': 71, '水3': 72, '水4': 73, '水5': 74, '水6': 75, '水7': 76, '水8': 77, '水9': 78, '水10': 79,
		'石1': 80, '石2': 81, '石3': 82, '石4': 83, '石5': 84, '石6': 85, '石7': 86, '石8': 87, '石9': 88, '石10': 89,
		'金3': 90, '金6': 91, '金10': 92, '火玉5': 93, '火玉10': 94, '地玉5': 95, '地玉10': 96, '水玉5': 97, '水玉10': 98, '玉5': 99, '玉10': 100
	}
	MaterialClass = [
	 '鉄', '木', '綿', '皮', '骨', '牙', '宝', '水', '石', '貴', '特', 'ゼ'
	]
	EquipIndex = {
	 '短剣': 0, '双短剣': 1, '剣': 2, '斧': 3, '弓': 4, '弩': 5, '杖': 6, '本': 7,
	 '短': 0, '双': 1, '双剣': 1, 'ボウガン': 5, 'ボーガン': 5, 'ボ': 5,
	 '兜': 8, '額当て': 9, '帽子': 10, 'フード': 11, '重鎧': 12, '軽鎧': 13, '服': 14, 'ローブ': 15,
	 '盾': 16, '小手': 17, 'グローブ': 18, '腕輪': 19, 'すね当て': 20, 'ブーツ': 21, '靴': 22, 'サンダル': 23,
	 'ブローチ': 24, '指輪': 25, '首飾り': 26, '耳飾り': 27,
	 '額': 9, '帽': 10, 'フ': 11, '重': 12, '軽': 13, '法衣':15, '法':15, 'ロ': 15, '小': 17, 'グ': 18, '手袋': 18, '腕': 19,
	 '脛当て': 20, '脛': 20, 'す': 20, 'ブー': 21, 'サ': 23, 'ブロ': 24, '指': 25, '耳': 26, '首': 27
	}
	EquipName = [
	 '短剣', '双短剣', '剣', '斧', '弓', '弩', '杖', '本',
	 '兜', '額当て', '帽子', 'フード', '重鎧', '軽鎧', '服', 'ローブ',
	 '盾', '小手', 'グローブ', '腕輪', 'すね当て', 'ブーツ', '靴', 'サンダル',
	 'ブローチ', '指輪', '首飾り', '耳飾り', '複数装備'
	]
	EquipPosition = [
	 0, 0, 0, 0, 0, 0, 0, 0,
	 1, 1, 1, 1, 2, 2, 2, 2,
	 3, 3, 3, 3, 4, 4, 4, 4,
	 5, 5, 5, 5, 6
	]
	#        攻   物   防  HP   MP   腕   器   速   魔
	Material9 = [
		Vec[ 10,  20,  10,  11,  20,  10,  30,  10,  30], # 鉄
		Vec[ 30,  10,  30,  33,  10,  30,  10,  20,  10], # 木
		Vec[ 10,  40,  10,  33,   5,  35,  30,  20,  10], # 綿
		Vec[ 30,  40,  40,   5,   5,  30,  40,  10,  10], # 皮
		Vec[ 10,  10,  40,  38,  40,  20,  10,  10,  10], # 骨
		Vec[ 10,  20,  20,   5,   5,  20,  20,  10,  20], # 牙
		Vec[ 10,  10,  25,  27,  25,  25,  25,  25,  25], # 宝
		Vec[ 20,  25,  15,   0,  30,  30,  25,  25,  10], # 水
		Vec[ 10,  20,  20,  11,  10,  10,  10,  10,  20], # 石
		Vec[ 50,  50,  50,  50,  50,  50,  50,  50,  50], # 貴
		Vec[ 10,  20,  10,  11,  20,  10,  30,  10,  30], # 特
		Vec[  0,   0,   0,   0,   0,   0,   0,   0,   0]  # ゼ
	]
	#        攻   物   防   HP   MP   腕   器   速   魔
	Equip9 = [
		Vec[ 75,   0,   0,   0,   0,   0,  40,  50,   0], # 短剣
		Vec[ 90,   0,   0,   0,   0,   0,  30,  40,   0], # 双短剣
		Vec[100,  20,   0,  10,   0,   0,   0,   0,   0], # 剣
		Vec[130,   0,   0,   0,   0,  20,   0,   0,   0], # 斧
		Vec[ 80,   0,   0,   0,   0,   0,  60,  10,  10], # 弓
		Vec[ 70,   0,   0,   0,  10,   0,  50,  20,   0], # 弩
		Vec[ 40,   0,   0,   0,  30,   0,   0,   0, 100], # 杖
		Vec[ 70,   0,  20,   0,  20,   0,   0,   0,  80], # 本
		Vec[  0,  50,   0,  50,   0,   0,   0,   0,   0], # 兜
		Vec[  0,  30,  10,  35,   0,   0,   0,   0,   0], # 額当て
		Vec[  0,  20,  25,  25,  25,   0,   0,   0,   0], # 帽子
		Vec[  0,  20,  40,  15,  35,   0,   0,   0,   0], # フード
		Vec[  0, 100,  20,   0,   0,   0,   0,   0,   0], # 重鎧
		Vec[  0,  80,  40,   0,   0,   0,   0,   0,   0], # 軽鎧
		Vec[  0,  60,  60,   0,   0,   0,  20,   0,   0], # 服
		Vec[  0,  50,  90,   0,   0,   0,   0,   0,  20], # ローブ
		Vec[  0,  70,  50,   0,   0,   0,   0,   0,   0], # 盾
		Vec[ 20,  40,  30,   0,   0,   0,   0,   0,   0], # 小手
		Vec[  0,  40,  50,   0,   0,   0,  30,   0,   0], # グローブ
		Vec[  0,  30,  60,   0,   0,   0,   0,   0,  30], # 腕輪
		Vec[  0,  65,  20,   0,   0,   0,   0,   0,   0], # すね当て
		Vec[  0,  40,  40,   0,   0,   0,   0,  30,   0], # ブーツ
		Vec[  0,  30,  30,   0,   0,   0,   0,  50,   0], # 靴
		Vec[  0,  20,  50,   0,   0,   0,   0,  40,   0], # サンダル
		Vec[  0,   0,   0,   0,   0,  50,   0,   0,   0], # ブローチ
		Vec[  0,   0,   0,   0,   0,   0,  50,   0,   0], # 指輪
		Vec[  0,   0,   0,   0,   0,   0,   0,  60,   0], # 首飾り
		Vec[  0,   0,   0,   0,   0,   0,   0,   0,  50]  # 耳飾り
	]
	#        攻   物   防   HP   MP   腕   器   速   魔
	#      攻 物 防 HP MP 腕 器 速 魔
	EquipFilter = [
		Vec[1, 0, 0, 0, 0, 0, 1, 1, 0], # 短剣
		Vec[1, 0, 0, 0, 0, 0, 1, 1, 0], # 双短剣
		Vec[1, 1, 0, 1, 0, 0, 0, 0, 0], # 剣
		Vec[1, 0, 0, 0, 0, 1, 0, 0, 0], # 斧
		Vec[1, 0, 0, 0, 0, 0, 1, 1, 1], # 弓
		Vec[1, 0, 0, 0, 1, 0, 1, 1, 0], # 弩
		Vec[1, 0, 0, 0, 1, 0, 0, 0, 1], # 杖
		Vec[1, 0, 1, 0, 1, 0, 0, 0, 1], # 本
		Vec[0, 1, 0, 1, 0, 0, 0, 0, 0], # 兜
		Vec[0, 1, 1, 1, 0, 0, 0, 0, 0], # 額当て
		Vec[0, 1, 1, 1, 1, 0, 0, 0, 0], # 帽子
		Vec[0, 1, 1, 1, 1, 0, 0, 0, 0], # フード
		Vec[0, 1, 1, 0, 0, 0, 0, 0, 0], # 重鎧
		Vec[0, 1, 1, 0, 0, 0, 0, 0, 0], # 軽鎧
		Vec[0, 1, 1, 0, 0, 0, 1, 0, 0], # 服
		Vec[0, 1, 1, 0, 0, 0, 0, 0, 1], # ローブ
		Vec[0, 1, 1, 0, 0, 0, 0, 0, 0], # 盾
		Vec[1, 1, 1, 0, 0, 0, 0, 0, 0], # 小手
		Vec[0, 1, 1, 0, 0, 0, 1, 0, 0], # グローブ
		Vec[0, 1, 1, 0, 0, 0, 0, 0, 1], # 腕輪
		Vec[0, 1, 1, 0, 0, 0, 0, 0, 0], # すね当て
		Vec[0, 1, 1, 0, 0, 0, 0, 1, 0], # ブーツ
		Vec[0, 1, 1, 0, 0, 0, 0, 1, 0], # 靴
		Vec[0, 1, 1, 0, 0, 0, 0, 1, 0], # サンダル
		Vec[0, 0, 0, 0, 0, 1, 0, 0, 0], # ブローチ
		Vec[0, 0, 0, 0, 0, 0, 1, 0, 0], # 指輪
		Vec[0, 0, 0, 0, 0, 0, 0, 1, 0], # 首飾り
		Vec[0, 0, 0, 0, 0, 0, 0, 0, 1]  # 耳飾り
	]
	#      攻 物 防 HP MP 腕 器 速 魔
	EquipWeight = [
		 90, 115, 120, 170, 140, 150, 120, 130, # 武器
		110,  70,  50,  40, 170, 120,  70,  50, # 頭，胴
		120,  70,  40,  20, 100,  70,  40,  10, # 腕，足
		 90,  90,  90,  90 # 装飾品
	]
	#     1    2    3    4    5    6    7    8    9   10
	MainWeight = [
		180, 183, 186, 189, 192, 195, 198, 201, 204, 207, # 鉄
		130, 133, 136, 139, 142, 145, 148, 151, 154, 157, # 木
		100, 103, 106, 109, 112, 115, 118, 121, 124, 127, # 綿
		140, 143, 146, 149, 152, 155, 158, 161, 164, 167, # 皮
		120, 123, 126, 129, 132, 135, 138, 141, 144, 147, # 骨
		120, 123, 126, 129, 132, 135, 138, 141, 144, 147, # 牙
		140, 143, 146, 149, 152, 155, 158, 161, 164, 167, # 宝
		110, 113, 116, 119, 122, 125, 128, 131, 134, 137, # 水
		190, 193, 196, 199, 202, 205, 208, 211, 214, 217, # 石
		200, 220, 220, 140, 200, 140, 200, 140, 200, 140, 200 # 貴
	]
	#    1   2   3   4   5   6   7   8   9  10
	SubWeight = [
		30, 35, 40, 45, 50, 55, 60, 65, 70, 75, # 鉄
		20, 25, 30, 35, 40, 45, 50, 55, 60, 65, # 木
		 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, # 綿
		10, 15, 20, 25, 30, 35, 40, 45, 50, 55, # 皮
		10, 15, 20, 25, 30, 35, 40, 45, 50, 55, # 骨
		10, 15, 20, 25, 30, 35, 40, 45, 50, 55, # 牙
		15, 20, 25, 30, 35, 40, 45, 50, 55, 60, # 宝
		 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, # 水
		40, 45, 50, 55, 60, 65, 70, 75, 80, 85, # 石
		30, 30, 30, 25, 40, 25, 40, 25, 40, 25, 40 # 貴
	]
	#       攻撃 物防 魔防  HP   MP  腕力 器用 素早 魔力
	Main9 = [
		Vec[ 16,  11,   3,  14,   1,   5,   3,   2,   1], # 鉄1
		Vec[ 20,  15,   4,  20,   1,   7,   4,   2,   1], # 鉄2
		Vec[ 27,  22,   6,  28,   2,  10,   6,   4,   2], # 鉄3
		Vec[ 35,  30,   8,  38,   2,  13,   8,   5,   2], # 鉄4
		Vec[ 46,  41,  11,  52,   3,  18,  11,   7,   3], # 鉄5
		Vec[ 60,  55,  15,  70,   5,  25,  15,  10,   5], # 鉄6
		Vec[ 75,  70,  19,  90,   6,  32,  19,  12,   6], # 鉄7
		Vec[ 94,  89,  24, 113,   8,  40,  24,  16,   8], # 鉄8
		Vec[115, 110,  30, 140,  10,  50,  30,  20,  10], # 鉄9
		Vec[138, 133,  36, 169,  12,  60,  36,  24,  12], # 鉄10
		Vec[ 10,   3,   4,   3,   2,   4,  11,   2,   3], # 木1
		Vec[ 12,   4,   5,   4,   2,   5,  15,   2,   4], # 木2
		Vec[ 15,   6,   8,   6,   4,   8,  22,   4,   6], # 木3
		Vec[ 18,   8,  11,   8,   5,  11,  30,   5,   8], # 木4
		Vec[ 23,  11,  15,  11,   7,  15,  41,   7,  11], # 木5
		Vec[ 30,  15,  20,  15,  10,  20,  55,  10,  15], # 木6
		Vec[ 37,  19,  25,  19,  12,  25,  70,  12,  19], # 木7
		Vec[ 45,  24,  32,  24,  16,  32,  89,  16,  24], # 木8
		Vec[ 55,  30,  40,  30,  20,  40, 110,  20,  30], # 木9
		Vec[ 65,  36,  48,  36,  24,  48, 133,  24,  36], # 木10
		Vec[  6,   3,  11,   5,   3,   1,   5,   5,   4], # 綿1
		Vec[  6,   4,  15,   7,   4,   1,   7,   7,   5], # 綿2
		Vec[  7,   6,  22,  10,   6,   2,  10,  10,   8], # 綿3
		Vec[  7,   8,  30,  13,   8,   2,  13,  13,  11], # 綿4
		Vec[  8,  11,  41,  18,  11,   3,  18,  18,  15], # 綿5
		Vec[ 10,  15,  55,  25,  15,   5,  25,  25,  20], # 綿6
		Vec[ 11,  19,  70,  32,  19,   6,  32,  32,  25], # 綿7
		Vec[ 13,  24,  89,  40,  24,   8,  40,  40,  32], # 綿8
		Vec[ 15,  30, 110,  50,  30,  10,  50,  50,  40], # 綿9
		Vec[ 17,  36, 133,  60,  36,  12,  60,  60,  48], # 綿10
		Vec[  8,   8,   7,  11,   2,   8,   5,   5,   4], # 皮1
		Vec[  9,  11,  10,  15,   2,  11,   7,   7,   5], # 皮2
		Vec[ 11,  16,  14,  22,   4,  16,  10,  10,   8], # 皮3
		Vec[ 13,  22,  19,  30,   5,  22,  13,  13,  11], # 皮4
		Vec[ 16,  30,  26,  41,   7,  30,  18,  18,  15], # 皮5
		Vec[ 20,  40,  35,  55,  10,  40,  25,  25,  20], # 皮6
		Vec[ 24,  51,  45,  70,  12,  51,  32,  32,  25], # 皮7
		Vec[ 29,  64,  56,  89,  16,  64,  40,  40,  32], # 皮8
		Vec[ 35,  80,  70, 110,  20,  80,  50,  50,  40], # 皮9
		Vec[ 41,  96,  84, 133,  24,  96,  60,  60,  48], # 皮10
		Vec[  7,   1,   4,   1,   4,   1,   5,   5,  11], # 骨1
		Vec[  7,   1,   5,   1,   5,   1,   7,   7,  15], # 骨2
		Vec[  9,   2,   8,   2,   8,   2,  10,  10,  22], # 骨3
		Vec[ 10,   2,  11,   2,  11,   2,  13,  13,  30], # 骨4
		Vec[ 12,   3,  15,   3,  15,   3,  18,  18,  41], # 骨5
		Vec[ 15,   5,  20,   5,  20,   5,  25,  25,  55], # 骨6
		Vec[ 17,   6,  25,   6,  25,   6,  32,  32,  70], # 骨7
		Vec[ 21,   8,  32,   8,  32,   8,  40,  40,  89], # 骨8
		Vec[ 25,  10,  40,  10,  40,  10,  50,  50, 110], # 骨9
		Vec[ 29,  12,  48,  12,  48,  12,  60,  60, 133], # 骨10
		Vec[ 13,   1,   5,   5,   1,   7,   7,   8,   3], # 牙1
		Vec[ 16,   1,   7,   7,   1,  10,  10,  11,   4], # 牙2
		Vec[ 21,   2,  10,  10,   2,  14,  14,  16,   6], # 牙3
		Vec[ 27,   2,  13,  13,   2,  19,  19,  22,   8], # 牙4
		Vec[ 35,   3,  18,  18,   3,  26,  26,  30,  11], # 牙5
		Vec[ 45,   5,  25,  25,   5,  35,  35,  40,  15], # 牙6
		Vec[ 56,   6,  32,  32,   6,  45,  45,  51,  19], # 牙7
		Vec[ 69,   8,  40,  40,   8,  56,  56,  64,  24], # 牙8
		Vec[ 85,  10,  50,  50,  10,  70,  70,  80,  30], # 牙9
		Vec[101,  12,  60,  60,  12,  84,  84,  96,  36], # 牙10
		Vec[  6,   1,   1,   5,   5,  10,   6,  10,   6], # 宝1
		Vec[  6,   1,   1,   7,   7,  14,   8,  14,   8], # 宝2
		Vec[  7,   2,   2,  10,  10,  20,  12,  20,  12], # 宝3
		Vec[  7,   2,   2,  13,  13,  27,  16,  27,  16], # 宝4
		Vec[  8,   3,   3,  18,  18,  37,  22,  37,  22], # 宝5
		Vec[ 10,   5,   5,  25,  25,  50,  30,  50,  30], # 宝6
		Vec[ 11,   6,   6,  32,  32,  64,  38,  64,  38], # 宝7
		Vec[ 13,   8,   8,  40,  40,  81,  48,  81,  48], # 宝8
		Vec[ 15,  10,  10,  50,  50, 100,  60, 100,  60], # 宝9
		Vec[ 17,  12,  12,  60,  60, 121,  72, 121,  72], # 宝10
		Vec[ 10,   1,   5,  11,   3,   5,   3,   8,   6], # 水1
		Vec[ 12,   1,   7,  15,   4,   7,   4,  11,   8], # 水2
		Vec[ 15,   2,  10,  22,   6,  10,   6,  16,  12], # 水3
		Vec[ 18,   2,  13,  30,   8,  13,   8,  22,  16], # 水4
		Vec[ 23,   3,  18,  41,  11,  18,  11,  30,  22], # 水5
		Vec[ 30,   5,  25,  55,  15,  25,  15,  40,  30], # 水6
		Vec[ 37,   6,  32,  70,  19,  32,  19,  51,  38], # 水7
		Vec[ 45,   8,  40,  89,  24,  40,  24,  64,  48], # 水8
		Vec[ 55,  10,  50, 110,  30,  50,  30,  80,  60], # 水9
		Vec[ 65,  12,  60, 133,  36,  60,  36,  96,  72], # 水10
		Vec[  8,   5,   2,  22,   5,   3,   2,   1,   2], # 石1
		Vec[  9,   7,   2,  31,   7,   4,   2,   1,   2], # 石2
		Vec[ 11,  10,   4,  44,  10,   6,   4,   2,   4], # 石3
		Vec[ 13,  13,   5,  61,  13,   8,   5,   2,   5], # 石4
		Vec[ 16,  18,   7,  83,  18,  11,   7,   3,   7], # 石5
		Vec[ 20,  25,  10, 110,  25,  15,  10,   5,  10], # 石6
		Vec[ 24,  32,  12, 141,  32,  19,  12,   6,  12], # 石7
		Vec[ 29,  40,  16, 178,  40,  24,  16,   8,  16], # 石8
		Vec[ 35,  50,  20, 220,  50,  30,  20,  10,  20], # 石9
		Vec[ 41,  60,  24, 266,  60,  36,  24,  12,  24], # 石10
		Vec[  2,   2,   2,  10,  10,   2,   2,   2,   2], # 金3
		Vec[  4,   4,   4,  20,  20,   4,   4,   4,   4], # 金6
		Vec[  6,   6,   6,  20,  20,   6,   6,   6,   6], # 金10
		Vec[  0,   0,   0,  20,   0,  20,   0,   0,   0], # 火玉5
		Vec[  0,   0,   0,  40,   0,  40,   0,   0,   0], # 火玉10
		Vec[  0,   0,   0,   0,   0,   0,  20,  20,   0], # 地玉5
		Vec[  0,   0,   0,   0,   0,   0,  40,  40,   0], # 地玉10
		Vec[  0,   0,   0,   0,  20,   0,   0,   0,  20], # 水玉5
		Vec[  0,   0,   0,   0,  40,   0,   0,   0,  40], # 水玉10
		Vec[  0,   0,   0,  20,  20,  20,  20,  20,  20], # 玉5
		Vec[  0,   0,   0,  40,  40,  40,  40,  40,  40]  # 玉10
	]
	#       攻撃 物防 魔防  HP   MP  腕力 器用 素早 魔力
	Sub9 = [
		Vec[110, 120, 110, 111, 120, 110, 130, 110, 130], # 鉄1
		Vec[115, 125, 115, 115, 125, 115, 135, 115, 135], # 鉄2
		Vec[120, 130, 120, 122, 130, 120, 140, 120, 140], # 鉄3
		Vec[125, 135, 125, 130, 135, 125, 145, 125, 145], # 鉄4
		Vec[130, 140, 130, 141, 140, 130, 150, 130, 150], # 鉄5
		Vec[135, 145, 135, 155, 145, 135, 155, 135, 155], # 鉄6
		Vec[140, 150, 140, 170, 150, 140, 160, 140, 160], # 鉄7
		Vec[145, 155, 145, 189, 155, 145, 165, 145, 165], # 鉄8
		Vec[150, 160, 150, 210, 160, 150, 170, 150, 170], # 鉄9
		Vec[155, 165, 155, 233, 165, 155, 175, 155, 175], # 鉄10
		Vec[130, 110, 130, 133, 110, 130, 110, 120, 110], # 木1
		Vec[135, 115, 135, 147, 115, 135, 115, 125, 115], # 木2
		Vec[140, 120, 140, 166, 120, 140, 120, 130, 120], # 木3
		Vec[145, 125, 145, 191, 125, 145, 125, 135, 125], # 木4
		Vec[150, 130, 150, 224, 130, 150, 130, 140, 130], # 木5
		Vec[155, 135, 155, 265, 135, 155, 135, 145, 135], # 木6
		Vec[160, 140, 160, 312, 140, 160, 140, 150, 140], # 木7
		Vec[165, 145, 165, 367, 145, 165, 145, 155, 145], # 木8
		Vec[170, 150, 170, 430, 150, 170, 150, 160, 150], # 木9
		Vec[175, 155, 175, 499, 155, 175, 155, 165, 155], # 木10
		Vec[110, 140, 110, 133, 105, 135, 130, 120, 110], # 綿1
		Vec[115, 145, 115, 147, 110, 140, 135, 125, 115], # 綿2
		Vec[120, 150, 120, 166, 115, 145, 140, 130, 120], # 綿3
		Vec[125, 155, 125, 191, 120, 150, 145, 135, 125], # 綿4
		Vec[130, 160, 130, 224, 125, 155, 150, 140, 130], # 綿5
		Vec[135, 165, 135, 265, 130, 160, 155, 145, 135], # 綿6
		Vec[140, 170, 140, 312, 135, 165, 160, 150, 140], # 綿7
		Vec[145, 175, 145, 367, 140, 170, 165, 155, 145], # 綿8
		Vec[150, 180, 150, 430, 145, 175, 170, 160, 150], # 綿9
		Vec[155, 185, 155, 499, 150, 180, 175, 165, 155], # 綿10
		Vec[130, 140, 140, 105, 105, 130, 140, 110, 110], # 皮1
		Vec[135, 145, 145, 107, 110, 135, 145, 115, 115], # 皮2
		Vec[140, 150, 150, 110, 115, 140, 150, 120, 120], # 皮3
		Vec[145, 155, 155, 113, 120, 145, 155, 125, 125], # 皮4
		Vec[150, 160, 160, 118, 125, 150, 160, 130, 130], # 皮5
		Vec[155, 165, 165, 125, 130, 155, 165, 135, 135], # 皮6
		Vec[160, 170, 170, 132, 135, 160, 170, 140, 140], # 皮7
		Vec[165, 175, 175, 140, 140, 165, 175, 145, 145], # 皮8
		Vec[170, 180, 180, 150, 145, 170, 180, 150, 150], # 皮9
		Vec[175, 185, 185, 160, 150, 175, 185, 155, 155], # 皮10
		Vec[110, 110, 140, 138, 140, 120, 110, 110, 110], # 骨1
		Vec[115, 115, 145, 154, 145, 125, 115, 115, 115], # 骨2
		Vec[120, 120, 150, 176, 150, 130, 120, 120, 120], # 骨3
		Vec[125, 125, 155, 205, 155, 135, 125, 125, 125], # 骨4
		Vec[130, 130, 160, 243, 160, 140, 130, 130, 130], # 骨5
		Vec[135, 135, 165, 290, 165, 145, 135, 135, 135], # 骨6
		Vec[140, 140, 170, 344, 170, 150, 140, 140, 140], # 骨7
		Vec[145, 145, 175, 408, 175, 155, 145, 145, 145], # 骨8
		Vec[150, 150, 180, 480, 180, 160, 150, 150, 150], # 骨9
		Vec[155, 155, 185, 560, 185, 165, 155, 155, 155], # 骨10
		Vec[110, 120, 120, 105, 105, 120, 120, 110, 120], # 牙1
		Vec[115, 125, 125, 107, 110, 125, 125, 115, 125], # 牙2
		Vec[120, 130, 130, 110, 115, 130, 130, 120, 130], # 牙3
		Vec[125, 135, 135, 113, 120, 135, 135, 125, 135], # 牙4
		Vec[130, 140, 140, 118, 125, 140, 140, 130, 140], # 牙5
		Vec[135, 145, 145, 125, 130, 145, 145, 135, 145], # 牙6
		Vec[140, 150, 150, 132, 135, 150, 150, 140, 150], # 牙7
		Vec[145, 155, 155, 140, 140, 155, 155, 145, 155], # 牙8
		Vec[150, 160, 160, 150, 145, 160, 160, 150, 160], # 牙9
		Vec[155, 165, 165, 160, 150, 165, 165, 155, 165], # 牙10
		Vec[110, 110, 125, 127, 125, 125, 125, 125, 125], # 宝1
		Vec[115, 115, 130, 139, 130, 130, 130, 130, 130], # 宝2
		Vec[120, 120, 135, 154, 135, 135, 135, 135, 135], # 宝3
		Vec[125, 125, 140, 175, 140, 140, 140, 140, 140], # 宝4
		Vec[130, 130, 145, 202, 145, 145, 145, 145, 145], # 宝5
		Vec[135, 135, 150, 235, 150, 150, 150, 150, 150], # 宝6
		Vec[140, 140, 155, 274, 155, 155, 155, 155, 155], # 宝7
		Vec[145, 145, 160, 319, 160, 160, 160, 160, 160], # 宝8
		Vec[150, 150, 165, 370, 165, 165, 165, 165, 165], # 宝9
		Vec[155, 155, 170, 427, 170, 170, 170, 170, 170], # 宝10
		Vec[120, 125, 115, 100, 130, 130, 125, 125, 110], # 水1
		Vec[125, 130, 120, 100, 135, 135, 130, 130, 115], # 水2
		Vec[130, 135, 125, 100, 140, 140, 135, 135, 120], # 水3
		Vec[135, 140, 130, 100, 145, 145, 140, 140, 125], # 水4
		Vec[140, 145, 135, 100, 150, 150, 145, 145, 130], # 水5
		Vec[145, 150, 140, 100, 155, 155, 150, 150, 135], # 水6
		Vec[150, 155, 145, 100, 160, 160, 155, 155, 140], # 水7
		Vec[155, 160, 150, 100, 165, 165, 160, 160, 145], # 水8
		Vec[160, 165, 155, 100, 170, 170, 165, 165, 150], # 水9
		Vec[165, 170, 160, 100, 175, 175, 170, 170, 155], # 水10
		Vec[110, 120, 120, 111, 110, 110, 110, 110, 120], # 石1
		Vec[115, 125, 125, 115, 115, 115, 115, 115, 125], # 石2
		Vec[120, 130, 130, 122, 120, 120, 120, 120, 130], # 石3
		Vec[125, 135, 135, 130, 125, 125, 125, 125, 135], # 石4
		Vec[130, 140, 140, 141, 130, 130, 130, 130, 140], # 石5
		Vec[135, 145, 145, 155, 135, 135, 135, 135, 145], # 石6
		Vec[140, 150, 150, 170, 140, 140, 140, 140, 150], # 石7
		Vec[145, 155, 155, 189, 145, 145, 145, 145, 155], # 石8
		Vec[150, 160, 160, 210, 150, 150, 150, 150, 160], # 石9
		Vec[155, 165, 165, 233, 155, 155, 155, 155, 165], # 石10
		Vec[150, 150, 150, 150, 150, 150, 150, 150, 150], # 金3
		Vec[175, 175, 175, 175, 175, 175, 175, 175, 175], # 金6
		Vec[200, 200, 200, 200, 200, 200, 200, 200, 200], # 金10
		Vec[100, 100, 140, 140, 140, 140, 140, 140, 140], # 火玉5
		Vec[100, 100, 160, 160, 160, 160, 160, 160, 160], # 火玉10
		Vec[100, 100, 140, 140, 140, 140, 140, 140, 140], # 地玉5
		Vec[100, 100, 160, 160, 160, 160, 160, 160, 160], # 地玉10
		Vec[100, 100, 140, 140, 140, 140, 140, 140, 140], # 水玉5
		Vec[100, 100, 160, 160, 160, 160, 160, 160, 160], # 水玉10
		Vec[100, 100, 140, 140, 140, 140, 140, 140, 140], # 玉5
		Vec[100, 100, 160, 160, 160, 160, 160, 160, 160]  # 玉10
	]
	#       攻撃 物防 魔防  HP   MP  腕力 器用 素早 魔力
	#      火 地 水
	MainEL = [
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 鉄
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 鉄
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 木
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 木
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 綿
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 綿
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 皮
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 皮
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 骨
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 骨
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 牙
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 牙
		Vec[1, 0, 0], Vec[1, 0, 0], Vec[1, 0, 0], Vec[1, 0, 0], Vec[1, 0, 0], # 宝
		Vec[1, 0, 0], Vec[1, 0, 0], Vec[1, 0, 0], Vec[1, 0, 0], Vec[1, 0, 0], # 宝
		Vec[0, 0, 1], Vec[0, 0, 1], Vec[0, 0, 1], Vec[0, 0, 1], Vec[0, 0, 1], # 水
		Vec[0, 0, 1], Vec[0, 0, 1], Vec[0, 0, 1], Vec[0, 0, 1], Vec[0, 0, 1], # 水
		Vec[0, 1, 0], Vec[0, 1, 0], Vec[0, 1, 0], Vec[0, 1, 0], Vec[0, 1, 0], # 石
		Vec[0, 1, 0], Vec[0, 1, 0], Vec[0, 1, 0], Vec[0, 1, 0], Vec[0, 1, 0], # 石
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[2, 0, 0], Vec[3, 0, 0], # 貴
		Vec[0, 2, 0], Vec[0, 3, 0], Vec[0, 0, 2], Vec[0, 0, 3], Vec[2, 2, 2], Vec[3, 3, 3] # 貴
	]
	#      火 地 水
	SubEL = [
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 鉄
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 鉄
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 木
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 木
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 綿
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 綿
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 皮
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 皮
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 骨
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 骨
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 牙
		Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], Vec[0, 0, 0], # 牙
		Vec[0, 0, 3], Vec[0, 0, 3], Vec[2, 0, 4], Vec[2, 0, 4], Vec[2, 0, 4], # 宝
		Vec[3, 0, 4], Vec[3, 0, 4], Vec[3, 0, 4], Vec[3, 0, 6], Vec[4, 0, 6], # 宝
		Vec[0, 3, 0], Vec[0, 3, 0], Vec[0, 4, 2], Vec[0, 4, 2], Vec[0, 4, 2], # 水
		Vec[0, 4, 3], Vec[0, 4, 3], Vec[0, 4, 3], Vec[0, 6, 3], Vec[0, 6, 4], # 水
		Vec[3, 0, 0], Vec[3, 0, 0], Vec[4, 2, 0], Vec[4, 2, 0], Vec[4, 2, 0], # 石
		Vec[4, 3, 0], Vec[4, 3, 0], Vec[4, 3, 0], Vec[6, 3, 0], Vec[6, 4, 0], # 石
		Vec[3, 3, 3], Vec[4, 4, 4], Vec[6, 6, 6], Vec[3, 0, 4], Vec[4, 0, 6], # 貴
		Vec[4, 3, 0], Vec[6, 4, 0], Vec[0, 4, 3], Vec[0, 6, 4], Vec[4, 4, 4], Vec[6, 6, 6] # 貴
	]
	SystemEquip = {
		'安物の短剣'       => Equip.new( 0, 1,  1,  0, 10, Vec[  10,    0,    0,    0,    0,    0,    4,    5,    0], Vec[0, 0, 0]),
		'量産品の短剣'     => Equip.new( 0, 1,  2,  0, 10, Vec[  15,    0,    0,    0,    0,    0,    6,    7,    0], Vec[0, 0, 0]),
		'一般的な短剣'     => Equip.new( 0, 1,  3,  0, 10, Vec[  21,    0,    0,    0,    0,    0,    8,   10,    0], Vec[0, 0, 0]),
		'良質な短剣'       => Equip.new( 0, 1,  4,  0, 10, Vec[  30,    0,    0,    0,    0,    0,   12,   15,    0], Vec[0, 0, 0]),
		'業物の短剣'       => Equip.new( 0, 1,  5,  0, 10, Vec[  41,    0,    0,    0,    0,    0,   16,   20,    0], Vec[0, 0, 0]),
		'名のある短剣'     => Equip.new( 0, 1,  6,  0, 10, Vec[  55,    0,    0,    0,    0,    0,   22,   27,    0], Vec[0, 0, 0]),
		'匠の短剣'         => Equip.new( 0, 1,  7,  0, 10, Vec[  71,    0,    0,    0,    0,    0,   28,   35,    0], Vec[0, 0, 0]),
		'竜殺しの短剣'     => Equip.new( 0, 1,  8,  0, 10, Vec[  90,    0,    0,    0,    0,    0,   36,   45,    0], Vec[0, 0, 0]),
		'光り輝く短剣'     => Equip.new( 0, 1,  9,  0, 10, Vec[ 111,    0,    0,    0,    0,    0,   44,   55,    0], Vec[0, 0, 0]),
		'安物の双短剣'     => Equip.new( 1, 2,  1,  0, 10, Vec[  13,    0,    0,    0,    0,    0,    3,    4,    0], Vec[0, 0, 0]),
		'量産品の双短剣'   => Equip.new( 1, 2,  2,  0, 10, Vec[  19,    0,    0,    0,    0,    0,    4,    6,    0], Vec[0, 0, 0]),
		'一般的な双短剣'   => Equip.new( 1, 2,  3,  0, 10, Vec[  27,    0,    0,    0,    0,    0,    6,    8,    0], Vec[0, 0, 0]),
		'良質な双短剣'     => Equip.new( 1, 2,  4,  0, 10, Vec[  39,    0,    0,    0,    0,    0,    9,   12,    0], Vec[0, 0, 0]),
		'業物の双短剣'     => Equip.new( 1, 2,  5,  0, 10, Vec[  53,    0,    0,    0,    0,    0,   12,   16,    0], Vec[0, 0, 0]),
		'名のある双短剣'   => Equip.new( 1, 2,  6,  0, 10, Vec[  71,    0,    0,    0,    0,    0,   16,   22,    0], Vec[0, 0, 0]),
		'匠の双短剣'       => Equip.new( 1, 2,  7,  0, 10, Vec[  92,    0,    0,    0,    0,    0,   21,   28,    0], Vec[0, 0, 0]),
		'竜殺しの双短剣'   => Equip.new( 1, 2,  8,  0, 10, Vec[ 117,    0,    0,    0,    0,    0,   27,   36,    0], Vec[0, 0, 0]),
		'光り輝く双短剣'   => Equip.new( 1, 2,  9,  0, 10, Vec[ 144,    0,    0,    0,    0,    0,   33,   44,    0], Vec[0, 0, 0]),
		'安物の剣'         => Equip.new( 2, 2,  1,  0, 10, Vec[  13,    2,    0,    4,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の剣'       => Equip.new( 2, 2,  2,  0, 10, Vec[  19,    3,    0,    6,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な剣'       => Equip.new( 2, 2,  3,  0, 10, Vec[  27,    4,    0,    8,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質な剣'         => Equip.new( 2, 2,  4,  0, 10, Vec[  39,    6,    0,   12,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物の剣'         => Equip.new( 2, 2,  5,  0, 10, Vec[  53,    8,    0,   16,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のある剣'       => Equip.new( 2, 2,  6,  0, 10, Vec[  71,   11,    0,   22,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠の剣'           => Equip.new( 2, 2,  7,  0, 10, Vec[  92,   14,    0,   28,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの剣'       => Equip.new( 2, 2,  8,  0, 10, Vec[ 117,   18,    0,   36,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く剣'       => Equip.new( 2, 2,  9,  0, 10, Vec[ 144,   22,    0,   44,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物の斧'         => Equip.new( 3, 3,  1,  0, 10, Vec[  19,    0,    0,    0,    0,    2,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の斧'       => Equip.new( 3, 3,  2,  0, 10, Vec[  23,    0,    0,    0,    0,    3,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な斧'       => Equip.new( 3, 3,  3,  0, 10, Vec[  40,    0,    0,    0,    0,    4,    0,    0,    0], Vec[0, 0, 0]),
		'良質な斧'         => Equip.new( 3, 3,  4,  0, 10, Vec[  57,    0,    0,    0,    0,    6,    0,    0,    0], Vec[0, 0, 0]),
		'業物の斧'         => Equip.new( 3, 3,  5,  0, 10, Vec[  78,    0,    0,    0,    0,    8,    0,    0,    0], Vec[0, 0, 0]),
		'名のある斧'       => Equip.new( 3, 3,  6,  0, 10, Vec[ 104,    0,    0,    0,    0,   11,    0,    0,    0], Vec[0, 0, 0]),
		'匠の斧'           => Equip.new( 3, 3,  7,  0, 10, Vec[ 135,    0,    0,    0,    0,   14,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの斧'       => Equip.new( 3, 3,  8,  0, 10, Vec[ 171,    0,    0,    0,    0,   18,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く斧'       => Equip.new( 3, 3,  9,  0, 10, Vec[ 211,    0,    0,    0,    0,   22,    0,    0,    0], Vec[0, 0, 0]),
		'安物の弓'         => Equip.new( 4, 2,  1,  0, 10, Vec[   8,    0,    0,    0,    0,    0,   10,    1,    1], Vec[0, 0, 0]),
		'量産品の弓'       => Equip.new( 4, 2,  2,  0, 10, Vec[  12,    0,    0,    0,    0,    0,   15,    1,    1], Vec[0, 0, 0]),
		'一般的な弓'       => Equip.new( 4, 2,  3,  0, 10, Vec[  17,    0,    0,    0,    0,    0,   21,    2,    2], Vec[0, 0, 0]),
		'良質な弓'         => Equip.new( 4, 2,  4,  0, 10, Vec[  24,    0,    0,    0,    0,    0,   30,    3,    3], Vec[0, 0, 0]),
		'業物の弓'         => Equip.new( 4, 2,  5,  0, 10, Vec[  33,    0,    0,    0,    0,    0,   41,    4,    4], Vec[0, 0, 0]),
		'名のある弓'       => Equip.new( 4, 2,  6,  0, 10, Vec[  44,    0,    0,    0,    0,    0,   55,    5,    5], Vec[0, 0, 0]),
		'匠の弓'           => Equip.new( 4, 2,  7,  0, 10, Vec[  57,    0,    0,    0,    0,    0,   71,    7,    7], Vec[0, 0, 0]),
		'竜殺しの弓'       => Equip.new( 4, 2,  8,  0, 10, Vec[  72,    0,    0,    0,    0,    0,   90,    9,    9], Vec[0, 0, 0]),
		'光り輝く弓'       => Equip.new( 4, 2,  9,  0, 10, Vec[  89,    0,    0,    0,    0,    0,  111,   11,   11], Vec[0, 0, 0]),
		'安物の弩'         => Equip.new( 5, 2,  1,  0, 10, Vec[   7,    0,    0,    0,    1,    0,    9,    2,    0], Vec[0, 0, 0]),
		'量産品の弩'       => Equip.new( 5, 2,  2,  0, 10, Vec[  10,    0,    0,    0,    1,    0,   13,    3,    0], Vec[0, 0, 0]),
		'一般的な弩'       => Equip.new( 5, 2,  3,  0, 10, Vec[  14,    0,    0,    0,    2,    0,   19,    4,    0], Vec[0, 0, 0]),
		'良質な弩'         => Equip.new( 5, 2,  4,  0, 10, Vec[  21,    0,    0,    0,    3,    0,   27,    6,    0], Vec[0, 0, 0]),
		'業物の弩'         => Equip.new( 5, 2,  5,  0, 10, Vec[  28,    0,    0,    0,    4,    0,   37,    8,    0], Vec[0, 0, 0]),
		'名のある弩'       => Equip.new( 5, 2,  6,  0, 10, Vec[  38,    0,    0,    0,    5,    0,   49,   11,    0], Vec[0, 0, 0]),
		'匠の弩'           => Equip.new( 5, 2,  7,  0, 10, Vec[  49,    0,    0,    0,    7,    0,   64,   14,    0], Vec[0, 0, 0]),
		'竜殺しの弩'       => Equip.new( 5, 2,  8,  0, 10, Vec[  63,    0,    0,    0,    9,    0,   81,   18,    0], Vec[0, 0, 0]),
		'光り輝く弩'       => Equip.new( 5, 2,  9,  0, 10, Vec[  77,    0,    0,    0,   11,    0,  100,   22,    0], Vec[0, 0, 0]),
		'安物の杖'         => Equip.new( 6, 2,  1,  0, 10, Vec[   5,    0,    0,    0,    3,    0,    0,    0,   11], Vec[0, 0, 0]),
		'量産品の杖'       => Equip.new( 6, 2,  2,  0, 10, Vec[   7,    0,    0,    0,    4,    0,    0,    0,   16], Vec[0, 0, 0]),
		'一般的な杖'       => Equip.new( 6, 2,  3,  0, 10, Vec[  10,    0,    0,    0,    6,    0,    0,    0,   23], Vec[0, 0, 0]),
		'良質な杖'         => Equip.new( 6, 2,  4,  0, 10, Vec[  15,    0,    0,    0,    9,    0,    0,    0,   33], Vec[0, 0, 0]),
		'業物の杖'         => Equip.new( 6, 2,  5,  0, 10, Vec[  20,    0,    0,    0,   12,    0,    0,    0,   45], Vec[0, 0, 0]),
		'名のある杖'       => Equip.new( 6, 2,  6,  0, 10, Vec[  27,    0,    0,    0,   16,    0,    0,    0,   60], Vec[0, 0, 0]),
		'匠の杖'           => Equip.new( 6, 2,  7,  0, 10, Vec[  35,    0,    0,    0,   21,    0,    0,    0,   78], Vec[0, 0, 0]),
		'竜殺しの杖'       => Equip.new( 6, 2,  8,  0, 10, Vec[  45,    0,    0,    0,   27,    0,    0,    0,   99], Vec[0, 0, 0]),
		'光り輝く杖'       => Equip.new( 6, 2,  9,  0, 10, Vec[  55,    0,    0,    0,   33,    0,    0,    0,  122], Vec[0, 0, 0]),
		'安物の本'         => Equip.new( 7, 2,  1,  0, 10, Vec[   8,    0,    2,    0,    2,    0,    0,    0,    8], Vec[0, 0, 0]),
		'量産品の本'       => Equip.new( 7, 2,  2,  0, 10, Vec[  12,    0,    3,    0,    3,    0,    0,    0,   12], Vec[0, 0, 0]),
		'一般的な本'       => Equip.new( 7, 2,  3,  0, 10, Vec[  17,    0,    4,    0,    4,    0,    0,    0,   17], Vec[0, 0, 0]),
		'良質な本'         => Equip.new( 7, 2,  4,  0, 10, Vec[  24,    0,    6,    0,    6,    0,    0,    0,   24], Vec[0, 0, 0]),
		'業物の本'         => Equip.new( 7, 2,  5,  0, 10, Vec[  33,    0,    8,    0,    8,    0,    0,    0,   33], Vec[0, 0, 0]),
		'名のある本'       => Equip.new( 7, 2,  6,  0, 10, Vec[  44,    0,   11,    0,   11,    0,    0,    0,   44], Vec[0, 0, 0]),
		'匠の本'           => Equip.new( 7, 2,  7,  0, 10, Vec[  57,    0,   14,    0,   14,    0,    0,    0,   57], Vec[0, 0, 0]),
		'竜殺しの本'       => Equip.new( 7, 2,  8,  0, 10, Vec[  72,    0,   18,    0,   18,    0,    0,    0,   72], Vec[0, 0, 0]),
		'光り輝く本'       => Equip.new( 7, 2,  9,  0, 10, Vec[  89,    0,   22,    0,   22,    0,    0,    0,   89], Vec[0, 0, 0]),
		'安物の兜'         => Equip.new( 8, 2,  1,  0, 10, Vec[   0,    5,    0,   15,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の兜'       => Equip.new( 8, 2,  2,  0, 10, Vec[   0,    8,    0,   25,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な兜'       => Equip.new( 8, 2,  3,  0, 10, Vec[   0,   12,    0,   37,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質な兜'         => Equip.new( 8, 2,  4,  0, 10, Vec[   0,   18,    0,   55,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物の兜'         => Equip.new( 8, 2,  5,  0, 10, Vec[   0,   25,    0,   77,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のある兜'       => Equip.new( 8, 2,  6,  0, 10, Vec[   0,   35,    0,  105,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠の兜'           => Equip.new( 8, 2,  7,  0, 10, Vec[   0,   45,    0,  137,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの兜'       => Equip.new( 8, 2,  8,  0, 10, Vec[   0,   58,    0,  175,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く兜'       => Equip.new( 8, 2,  9,  0, 10, Vec[   0,   72,    0,  217,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦の兜'         => Equip.new( 8, 2, 10,  0, 10, Vec[   0,   88,    0,  265,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物の額当て'     => Equip.new( 9, 1,  1,  0, 10, Vec[   0,    3,    1,   10,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の額当て'   => Equip.new( 9, 1,  2,  0, 10, Vec[   0,    5,    1,   16,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な額当て'   => Equip.new( 9, 1,  3,  0, 10, Vec[   0,    7,    2,   25,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質な額当て'     => Equip.new( 9, 1,  4,  0, 10, Vec[   0,   11,    3,   36,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物の額当て'     => Equip.new( 9, 1,  5,  0, 10, Vec[   0,   15,    5,   51,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のある額当て'   => Equip.new( 9, 1,  6,  0, 10, Vec[   0,   21,    7,   70,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠の額当て'       => Equip.new( 9, 1,  7,  0, 10, Vec[   0,   27,    9,   91,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの額当て'   => Equip.new( 9, 1,  8,  0, 10, Vec[   0,   35,   11,  116,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く額当て'   => Equip.new( 9, 1,  9,  0, 10, Vec[   0,   43,   14,  145,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦の額当て'     => Equip.new( 9, 1, 10,  0, 10, Vec[   0,   53,   17,  176,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物の帽子'       => Equip.new(10, 1,  1,  0, 10, Vec[   0,    2,    2,    7,    2,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の帽子'     => Equip.new(10, 1,  2,  0, 10, Vec[   0,    3,    3,   11,    3,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な帽子'     => Equip.new(10, 1,  3,  0, 10, Vec[   0,    5,    5,   17,    5,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質な帽子'       => Equip.new(10, 1,  4,  0, 10, Vec[   0,    7,    7,   25,    7,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物の帽子'       => Equip.new(10, 1,  5,  0, 10, Vec[   0,   10,   10,   36,   10,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のある帽子'     => Equip.new(10, 1,  6,  0, 10, Vec[   0,   14,   14,   49,   14,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠の帽子'         => Equip.new(10, 1,  7,  0, 10, Vec[   0,   18,   18,   64,   18,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの帽子'     => Equip.new(10, 1,  8,  0, 10, Vec[   0,   23,   23,   81,   23,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く帽子'     => Equip.new(10, 1,  9,  0, 10, Vec[   0,   29,   29,  101,   29,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦の帽子'       => Equip.new(10, 1, 10,  0, 10, Vec[   0,   35,   35,  123,   35,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物のフード'     => Equip.new(11, 1,  1,  0, 10, Vec[   0,    2,    4,    4,    3,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品のフード'   => Equip.new(11, 1,  2,  0, 10, Vec[   0,    3,    6,    6,    5,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的なフード'   => Equip.new(11, 1,  3,  0, 10, Vec[   0,    5,   10,   10,    7,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質なフード'     => Equip.new(11, 1,  4,  0, 10, Vec[   0,    7,   14,   14,   11,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物のフード'     => Equip.new(11, 1,  5,  0, 10, Vec[   0,   10,   20,   20,   15,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のあるフード'   => Equip.new(11, 1,  6,  0, 10, Vec[   0,   14,   28,   28,   21,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠のフード'       => Equip.new(11, 1,  7,  0, 10, Vec[   0,   18,   36,   36,   27,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しのフード'   => Equip.new(11, 1,  8,  0, 10, Vec[   0,   23,   46,   46,   35,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝くフード'   => Equip.new(11, 1,  9,  0, 10, Vec[   0,   29,   58,   58,   43,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦のフード'     => Equip.new(11, 1, 10,  0, 10, Vec[   0,   35,   70,   70,   53,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物の重鎧'       => Equip.new(12, 3,  1,  0, 10, Vec[   0,   12,    2,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の重鎧'     => Equip.new(12, 3,  2,  0, 10, Vec[   0,   20,    3,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な重鎧'     => Equip.new(12, 3,  3,  0, 10, Vec[   0,   30,    5,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質な重鎧'       => Equip.new(12, 3,  4,  0, 10, Vec[   0,   44,    7,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物の重鎧'       => Equip.new(12, 3,  5,  0, 10, Vec[   0,   62,   10,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のある重鎧'     => Equip.new(12, 3,  6,  0, 10, Vec[   0,   84,   14,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠の重鎧'         => Equip.new(12, 3,  7,  0, 10, Vec[   0,  110,   18,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの重鎧'     => Equip.new(12, 3,  8,  0, 10, Vec[   0,  140,   23,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く重鎧'     => Equip.new(12, 3,  9,  0, 10, Vec[   0,  174,   29,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦の重鎧'       => Equip.new(12, 3, 10,  0, 10, Vec[   0,  212,   35,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物の軽鎧'       => Equip.new(13, 2,  1,  0, 10, Vec[   0,    8,    4,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の軽鎧'     => Equip.new(13, 2,  2,  0, 10, Vec[   0,   13,    6,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な軽鎧'     => Equip.new(13, 2,  3,  0, 10, Vec[   0,   20,   10,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質な軽鎧'       => Equip.new(13, 2,  4,  0, 10, Vec[   0,   29,   14,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物の軽鎧'       => Equip.new(13, 2,  5,  0, 10, Vec[   0,   41,   20,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のある軽鎧'     => Equip.new(13, 2,  6,  0, 10, Vec[   0,   41,   20,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠の軽鎧'         => Equip.new(13, 2,  7,  0, 10, Vec[   0,   56,   28,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの軽鎧'     => Equip.new(13, 2,  8,  0, 10, Vec[   0,   73,   36,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く軽鎧'     => Equip.new(13, 2,  9,  0, 10, Vec[   0,   93,   46,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦の軽鎧'       => Equip.new(13, 2, 10,  0, 10, Vec[   0,  116,   58,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物の服'         => Equip.new(14, 1,  1,  0, 10, Vec[   0,    6,    6,    0,    0,    0,    3,    0,    0], Vec[0, 0, 0]),
		'量産品の服'       => Equip.new(14, 1,  2,  0, 10, Vec[   0,   10,   10,    0,    0,    0,    5,    0,    0], Vec[0, 0, 0]),
		'一般的な服'       => Equip.new(14, 1,  3,  0, 10, Vec[   0,   15,   15,    0,    0,    0,    7,    0,    0], Vec[0, 0, 0]),
		'良質な服'         => Equip.new(14, 1,  4,  0, 10, Vec[   0,   22,   22,    0,    0,    0,   11,    0,    0], Vec[0, 0, 0]),
		'業物の服'         => Equip.new(14, 1,  5,  0, 10, Vec[   0,   31,   31,    0,    0,    0,   15,    0,    0], Vec[0, 0, 0]),
		'名のある服'       => Equip.new(14, 1,  6,  0, 10, Vec[   0,   42,   42,    0,    0,    0,   21,    0,    0], Vec[0, 0, 0]),
		'匠の服'           => Equip.new(14, 1,  7,  0, 10, Vec[   0,   55,   55,    0,    0,    0,   27,    0,    0], Vec[0, 0, 0]),
		'竜殺しの服'       => Equip.new(14, 1,  8,  0, 10, Vec[   0,   70,   70,    0,    0,    0,   35,    0,    0], Vec[0, 0, 0]),
		'光り輝く服'       => Equip.new(14, 1,  9,  0, 10, Vec[   0,   87,   87,    0,    0,    0,   43,    0,    0], Vec[0, 0, 0]),
		'歴戦の服'         => Equip.new(14, 1, 10,  0, 10, Vec[   0,  106,  106,    0,    0,    0,   53,    0,    0], Vec[0, 0, 0]),
		'安物のローブ'     => Equip.new(15, 1,  1,  0, 10, Vec[   0,    5,    9,    0,    0,    0,    0,    0,    3], Vec[0, 0, 0]),
		'量産品のローブ'   => Equip.new(15, 1,  2,  0, 10, Vec[   0,    8,   15,    0,    0,    0,    0,    0,    5], Vec[0, 0, 0]),
		'一般的なローブ'   => Equip.new(15, 1,  3,  0, 10, Vec[   0,   12,   22,    0,    0,    0,    0,    0,    7], Vec[0, 0, 0]),
		'良質なローブ'     => Equip.new(15, 1,  4,  0, 10, Vec[   0,   18,   33,    0,    0,    0,    0,    0,   11], Vec[0, 0, 0]),
		'業物のローブ'     => Equip.new(15, 1,  5,  0, 10, Vec[   0,   25,   46,    0,    0,    0,    0,    0,   15], Vec[0, 0, 0]),
		'名のあるローブ'   => Equip.new(15, 1,  6,  0, 10, Vec[   0,   35,   63,    0,    0,    0,    0,    0,   21], Vec[0, 0, 0]),
		'匠のローブ'       => Equip.new(15, 1,  7,  0, 10, Vec[   0,   45,   82,    0,    0,    0,    0,    0,   27], Vec[0, 0, 0]),
		'竜殺しのローブ'   => Equip.new(15, 1,  8,  0, 10, Vec[   0,   58,  105,    0,    0,    0,    0,    0,   35], Vec[0, 0, 0]),
		'光り輝くローブ'   => Equip.new(15, 1,  9,  0, 10, Vec[   0,   72,  130,    0,    0,    0,    0,    0,   43], Vec[0, 0, 0]),
		'歴戦のローブ'     => Equip.new(15, 1, 10,  0, 10, Vec[   0,   88,  159,    0,    0,    0,    0,    0,   53], Vec[0, 0, 0]),
		'安物の盾'         => Equip.new(16, 2,  1,  0, 10, Vec[   0,    7,    5,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の盾'       => Equip.new(16, 2,  2,  0, 10, Vec[   0,   11,    8,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な盾'       => Equip.new(16, 2,  3,  0, 10, Vec[   0,   17,   12,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質な盾'         => Equip.new(16, 2,  4,  0, 10, Vec[   0,   25,   18,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物の盾'         => Equip.new(16, 2,  5,  0, 10, Vec[   0,   36,   25,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のある盾'       => Equip.new(16, 2,  6,  0, 10, Vec[   0,   49,   35,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠の盾'           => Equip.new(16, 2,  7,  0, 10, Vec[   0,   64,   45,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの盾'       => Equip.new(16, 2,  8,  0, 10, Vec[   0,   81,   58,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く盾'       => Equip.new(16, 2,  9,  0, 10, Vec[   0,  101,   72,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦の盾'         => Equip.new(16, 2, 10,  0, 10, Vec[   0,  123,   88,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物の小手'       => Equip.new(17, 1,  1,  0, 10, Vec[   3,    4,    3,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品の小手'     => Equip.new(17, 1,  2,  0, 10, Vec[   5,    6,    5,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的な小手'     => Equip.new(17, 1,  3,  0, 10, Vec[   7,   10,    7,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質な小手'       => Equip.new(17, 1,  4,  0, 10, Vec[  11,   14,   11,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物の小手'       => Equip.new(17, 1,  5,  0, 10, Vec[  15,   20,   15,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のある小手'     => Equip.new(17, 1,  6,  0, 10, Vec[  21,   28,   21,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠の小手'         => Equip.new(17, 1,  7,  0, 10, Vec[  27,   36,   27,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しの小手'     => Equip.new(17, 1,  8,  0, 10, Vec[  35,   46,   35,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝く小手'     => Equip.new(17, 1,  9,  0, 10, Vec[  43,   58,   43,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦の小手'       => Equip.new(17, 1, 10,  0, 10, Vec[  53,   70,   53,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物のグローブ'   => Equip.new(18, 1,  1,  0, 10, Vec[   0,    4,    5,    0,    0,    0,    3,    0,    0], Vec[0, 0, 0]),
		'量産品のグローブ' => Equip.new(18, 1,  2,  0, 10, Vec[   0,    6,    8,    0,    0,    0,    5,    0,    0], Vec[0, 0, 0]),
		'一般的なグローブ' => Equip.new(18, 1,  3,  0, 10, Vec[   0,   10,   12,    0,    0,    0,    7,    0,    0], Vec[0, 0, 0]),
		'良質なグローブ'   => Equip.new(18, 1,  4,  0, 10, Vec[   0,   14,   18,    0,    0,    0,   11,    0,    0], Vec[0, 0, 0]),
		'業物のグローブ'   => Equip.new(18, 1,  5,  0, 10, Vec[   0,   20,   25,    0,    0,    0,   15,    0,    0], Vec[0, 0, 0]),
		'名のあるグローブ' => Equip.new(18, 1,  6,  0, 10, Vec[   0,   28,   35,    0,    0,    0,   21,    0,    0], Vec[0, 0, 0]),
		'匠のグローブ'     => Equip.new(18, 1,  7,  0, 10, Vec[   0,   36,   45,    0,    0,    0,   27,    0,    0], Vec[0, 0, 0]),
		'竜殺しのグローブ' => Equip.new(18, 1,  8,  0, 10, Vec[   0,   46,   58,    0,    0,    0,   35,    0,    0], Vec[0, 0, 0]),
		'光り輝くグローブ' => Equip.new(18, 1,  9,  0, 10, Vec[   0,   58,   72,    0,    0,    0,   43,    0,    0], Vec[0, 0, 0]),
		'歴戦のグローブ'   => Equip.new(18, 1, 10,  0, 10, Vec[   0,   70,   88,    0,    0,    0,   53,    0,    0], Vec[0, 0, 0]),
		'安物の腕輪'       => Equip.new(19, 1,  1,  0, 10, Vec[   0,    3,    6,    0,    0,    0,    0,    0,    3], Vec[0, 0, 0]),
		'量産品の腕輪'     => Equip.new(19, 1,  2,  0, 10, Vec[   0,    5,   10,    0,    0,    0,    0,    0,    5], Vec[0, 0, 0]),
		'一般的な腕輪'     => Equip.new(19, 1,  3,  0, 10, Vec[   0,    7,   15,    0,    0,    0,    0,    0,    7], Vec[0, 0, 0]),
		'良質な腕輪'       => Equip.new(19, 1,  4,  0, 10, Vec[   0,   11,   22,    0,    0,    0,    0,    0,   11], Vec[0, 0, 0]),
		'業物の腕輪'       => Equip.new(19, 1,  5,  0, 10, Vec[   0,   15,   31,    0,    0,    0,    0,    0,   15], Vec[0, 0, 0]),
		'名のある腕輪'     => Equip.new(19, 1,  6,  0, 10, Vec[   0,   21,   42,    0,    0,    0,    0,    0,   21], Vec[0, 0, 0]),
		'匠の腕輪'         => Equip.new(19, 1,  7,  0, 10, Vec[   0,   27,   44,    0,    0,    0,    0,    0,   27], Vec[0, 0, 0]),
		'竜殺しの腕輪'     => Equip.new(19, 1,  8,  0, 10, Vec[   0,   35,   70,    0,    0,    0,    0,    0,   35], Vec[0, 0, 0]),
		'光り輝く腕輪'     => Equip.new(19, 1,  9,  0, 10, Vec[   0,   43,   87,    0,    0,    0,    0,    0,   43], Vec[0, 0, 0]),
		'歴戦の腕輪'       => Equip.new(19, 1, 10,  0, 10, Vec[   0,   53,  106,    0,    0,    0,    0,    0,   53], Vec[0, 0, 0]),
		'安物のすね当て'   => Equip.new(20, 2,  1,  0, 10, Vec[   0,    7,    2,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'量産品のすね当て' => Equip.new(20, 2,  2,  0, 10, Vec[   0,   11,    3,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'一般的なすね当て' => Equip.new(20, 2,  3,  0, 10, Vec[   0,   17,    5,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'良質なすね当て'   => Equip.new(20, 2,  4,  0, 10, Vec[   0,   25,    7,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'業物のすね当て'   => Equip.new(20, 2,  5,  0, 10, Vec[   0,   36,   10,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'名のあるすね当て' => Equip.new(20, 2,  6,  0, 10, Vec[   0,   49,   14,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'匠のすね当て'     => Equip.new(20, 2,  7,  0, 10, Vec[   0,   64,   18,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しのすね当て' => Equip.new(20, 2,  8,  0, 10, Vec[   0,   81,   23,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝くすね当て' => Equip.new(20, 2,  9,  0, 10, Vec[   0,  101,   29,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦のすね当て'   => Equip.new(20, 2, 10,  0, 10, Vec[   0,  123,   35,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'安物のブーツ'     => Equip.new(21, 1,  1,  0, 10, Vec[   0,    4,    4,    0,    0,    0,    0,    2,    0], Vec[0, 0, 0]),
		'量産品のブーツ'   => Equip.new(21, 1,  2,  0, 10, Vec[   0,    6,    6,    0,    0,    0,    0,    3,    0], Vec[0, 0, 0]),
		'一般的なブーツ'   => Equip.new(21, 1,  3,  0, 10, Vec[   0,   10,   10,    0,    0,    0,    0,    5,    0], Vec[0, 0, 0]),
		'良質なブーツ'     => Equip.new(21, 1,  4,  0, 10, Vec[   0,   14,   14,    0,    0,    0,    0,    7,    0], Vec[0, 0, 0]),
		'業物のブーツ'     => Equip.new(21, 1,  5,  0, 10, Vec[   0,   20,   20,    0,    0,    0,    0,   10,    0], Vec[0, 0, 0]),
		'名のあるブーツ'   => Equip.new(21, 1,  6,  0, 10, Vec[   0,   28,   28,    0,    0,    0,    0,   14,    0], Vec[0, 0, 0]),
		'匠のブーツ'       => Equip.new(21, 1,  7,  0, 10, Vec[   0,   36,   36,    0,    0,    0,    0,   18,    0], Vec[0, 0, 0]),
		'竜殺しのブーツ'   => Equip.new(21, 1,  8,  0, 10, Vec[   0,   46,   46,    0,    0,    0,    0,   23,    0], Vec[0, 0, 0]),
		'光り輝くブーツ'   => Equip.new(21, 1,  9,  0, 10, Vec[   0,   58,   58,    0,    0,    0,    0,   29,    0], Vec[0, 0, 0]),
		'歴戦のブーツ'     => Equip.new(21, 1, 10,  0, 10, Vec[   0,   70,   70,    0,    0,    0,    0,   35,    0], Vec[0, 0, 0]),
		'安物の靴'         => Equip.new(22, 1,  1,  0, 10, Vec[   0,    3,    3,    0,    0,    0,    0,    4,    0], Vec[0, 0, 0]),
		'量産品の靴'       => Equip.new(22, 1,  2,  0, 10, Vec[   0,    5,    5,    0,    0,    0,    0,    6,    0], Vec[0, 0, 0]),
		'一般的な靴'       => Equip.new(22, 1,  3,  0, 10, Vec[   0,    7,    7,    0,    0,    0,    0,   10,    0], Vec[0, 0, 0]),
		'良質な靴'         => Equip.new(22, 1,  4,  0, 10, Vec[   0,   11,   11,    0,    0,    0,    0,   14,    0], Vec[0, 0, 0]),
		'業物の靴'         => Equip.new(22, 1,  5,  0, 10, Vec[   0,   15,   15,    0,    0,    0,    0,   20,    0], Vec[0, 0, 0]),
		'名のある靴'       => Equip.new(22, 1,  6,  0, 10, Vec[   0,   21,   21,    0,    0,    0,    0,   28,    0], Vec[0, 0, 0]),
		'匠の靴'           => Equip.new(22, 1,  7,  0, 10, Vec[   0,   27,   27,    0,    0,    0,    0,   36,    0], Vec[0, 0, 0]),
		'竜殺しの靴'       => Equip.new(22, 1,  8,  0, 10, Vec[   0,   35,   35,    0,    0,    0,    0,   46,    0], Vec[0, 0, 0]),
		'光り輝く靴'       => Equip.new(22, 1,  9,  0, 10, Vec[   0,   43,   43,    0,    0,    0,    0,   58,    0], Vec[0, 0, 0]),
		'歴戦の靴'         => Equip.new(22, 1, 10,  0, 10, Vec[   0,   53,   53,    0,    0,    0,    0,   70,    0], Vec[0, 0, 0]),
		'安物のサンダル'   => Equip.new(23, 1,  1,  0, 10, Vec[   0,    2,    5,    0,    0,    0,    0,    3,    0], Vec[0, 0, 0]),
		'量産品のサンダル' => Equip.new(23, 1,  2,  0, 10, Vec[   0,    3,    8,    0,    0,    0,    0,    5,    0], Vec[0, 0, 0]),
		'一般的なサンダル' => Equip.new(23, 1,  3,  0, 10, Vec[   0,    5,   12,    0,    0,    0,    0,    7,    0], Vec[0, 0, 0]),
		'良質なサンダル'   => Equip.new(23, 1,  4,  0, 10, Vec[   0,    7,   18,    0,    0,    0,    0,   11,    0], Vec[0, 0, 0]),
		'業物のサンダル'   => Equip.new(23, 1,  5,  0, 10, Vec[   0,   10,   25,    0,    0,    0,    0,   15,    0], Vec[0, 0, 0]),
		'名のあるサンダル' => Equip.new(23, 1,  6,  0, 10, Vec[   0,   14,   35,    0,    0,    0,    0,   21,    0], Vec[0, 0, 0]),
		'匠のサンダル'     => Equip.new(23, 1,  7,  0, 10, Vec[   0,   18,   45,    0,    0,    0,    0,   27,    0], Vec[0, 0, 0]),
		'竜殺しのサンダル' => Equip.new(23, 1,  8,  0, 10, Vec[   0,   23,   58,    0,    0,    0,    0,   35,    0], Vec[0, 0, 0]),
		'光り輝くサンダル' => Equip.new(23, 1,  9,  0, 10, Vec[   0,   29,   72,    0,    0,    0,    0,   43,    0], Vec[0, 0, 0]),
		'歴戦のサンダル'   => Equip.new(23, 1, 10,  0, 10, Vec[   0,   35,   88,    0,    0,    0,    0,   53,    0], Vec[0, 0, 0]),
		'安物のブローチ'   => Equip.new(24, 1,  1,  0, 10, Vec[   0,    0,    0,    0,    0,    5,    0,    0,    0], Vec[0, 0, 0]),
		'量産品のブローチ' => Equip.new(24, 1,  2,  0, 10, Vec[   0,    0,    0,    0,    0,    8,    0,    0,    0], Vec[0, 0, 0]),
		'一般的なブローチ' => Equip.new(24, 1,  3,  0, 10, Vec[   0,    0,    0,    0,    0,   12,    0,    0,    0], Vec[0, 0, 0]),
		'良質なブローチ'   => Equip.new(24, 1,  4,  0, 10, Vec[   0,    0,    0,    0,    0,   18,    0,    0,    0], Vec[0, 0, 0]),
		'業物のブローチ'   => Equip.new(24, 1,  5,  0, 10, Vec[   0,    0,    0,    0,    0,   25,    0,    0,    0], Vec[0, 0, 0]),
		'名のあるブローチ' => Equip.new(24, 1,  6,  0, 10, Vec[   0,    0,    0,    0,    0,   35,    0,    0,    0], Vec[0, 0, 0]),
		'匠のブローチ'     => Equip.new(24, 1,  7,  0, 10, Vec[   0,    0,    0,    0,    0,   45,    0,    0,    0], Vec[0, 0, 0]),
		'竜殺しのブローチ' => Equip.new(24, 1,  8,  0, 10, Vec[   0,    0,    0,    0,    0,   58,    0,    0,    0], Vec[0, 0, 0]),
		'光り輝くブローチ' => Equip.new(24, 1,  9,  0, 10, Vec[   0,    0,    0,    0,    0,   72,    0,    0,    0], Vec[0, 0, 0]),
		'歴戦のブローチ'   => Equip.new(24, 1, 10,  0, 10, Vec[   0,    0,    0,    0,    0,   88,    0,    0,    0], Vec[0, 0, 0]),
		'安物の指輪'       => Equip.new(25, 1,  1,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    5,    0,    0], Vec[0, 0, 0]),
		'量産品の指輪'     => Equip.new(25, 1,  2,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    8,    0,    0], Vec[0, 0, 0]),
		'一般的な指輪'     => Equip.new(25, 1,  3,  0, 10, Vec[   0,    0,    0,    0,    0,    0,   12,    0,    0], Vec[0, 0, 0]),
		'良質な指輪'       => Equip.new(25, 1,  4,  0, 10, Vec[   0,    0,    0,    0,    0,    0,   18,    0,    0], Vec[0, 0, 0]),
		'業物の指輪'       => Equip.new(25, 1,  5,  0, 10, Vec[   0,    0,    0,    0,    0,    0,   25,    0,    0], Vec[0, 0, 0]),
		'名のある指輪'     => Equip.new(25, 1,  6,  0, 10, Vec[   0,    0,    0,    0,    0,    0,   35,    0,    0], Vec[0, 0, 0]),
		'匠の指輪'         => Equip.new(25, 1,  7,  0, 10, Vec[   0,    0,    0,    0,    0,    0,   45,    0,    0], Vec[0, 0, 0]),
		'竜殺しの指輪'     => Equip.new(25, 1,  8,  0, 10, Vec[   0,    0,    0,    0,    0,    0,   58,    0,    0], Vec[0, 0, 0]),
		'光り輝く指輪'     => Equip.new(25, 1,  9,  0, 10, Vec[   0,    0,    0,    0,    0,    0,   72,    0,    0], Vec[0, 0, 0]),
		'歴戦の指輪'       => Equip.new(25, 1, 10,  0, 10, Vec[   0,    0,    0,    0,    0,    0,   88,    0,    0], Vec[0, 0, 0]),
		'安物の首飾り'     => Equip.new(26, 1,  1,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    5,    0], Vec[0, 0, 0]),
		'量産品の首飾り'   => Equip.new(26, 1,  2,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    8,    0], Vec[0, 0, 0]),
		'一般的な首飾り'   => Equip.new(26, 1,  3,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,   12,    0], Vec[0, 0, 0]),
		'良質な首飾り'     => Equip.new(26, 1,  4,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,   18,    0], Vec[0, 0, 0]),
		'業物の首飾り'     => Equip.new(26, 1,  5,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,   25,    0], Vec[0, 0, 0]),
		'名のある首飾り'   => Equip.new(26, 1,  6,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,   35,    0], Vec[0, 0, 0]),
		'匠の首飾り'       => Equip.new(26, 1,  7,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,   45,    0], Vec[0, 0, 0]),
		'竜殺しの首飾り'   => Equip.new(26, 1,  8,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,   58,    0], Vec[0, 0, 0]),
		'光り輝く首飾り'   => Equip.new(26, 1,  9,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,   72,    0], Vec[0, 0, 0]),
		'歴戦の首飾り'     => Equip.new(26, 1, 10,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,   88,    0], Vec[0, 0, 0]),
		'安物の耳飾り'     => Equip.new(27, 1,  1,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,    5], Vec[0, 0, 0]),
		'量産品の耳飾り'   => Equip.new(27, 1,  2,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,    8], Vec[0, 0, 0]),
		'一般的な耳飾り'   => Equip.new(27, 1,  3,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,   12], Vec[0, 0, 0]),
		'良質な耳飾り'     => Equip.new(27, 1,  4,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,   18], Vec[0, 0, 0]),
		'業物の耳飾り'     => Equip.new(27, 1,  5,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,   25], Vec[0, 0, 0]),
		'名のある耳飾り'   => Equip.new(27, 1,  6,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,   35], Vec[0, 0, 0]),
		'匠の耳飾り'       => Equip.new(27, 1,  7,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,   45], Vec[0, 0, 0]),
		'竜殺しの耳飾り'   => Equip.new(27, 1,  8,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,   58], Vec[0, 0, 0]),
		'光り輝く耳飾り'   => Equip.new(27, 1,  9,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,   72], Vec[0, 0, 0]),
		'歴戦の耳飾り'     => Equip.new(27, 1, 10,  0, 10, Vec[   0,    0,    0,    0,    0,    0,    0,    0,   88], Vec[0, 0, 0]),
		'紫色小太刀'       => Equip.new( 0, 1, 10,  0,  5, Vec[ 200,    0,    0,    0,    0,    0,    0,   80,    0], Vec[0, 0, 0]),
		'氷炎二刀'         => Equip.new( 1, 2, 10,  0,  5, Vec[ 170,    0,    0,    0,    0,    0,    0,    0,  100], Vec[1, 0, 1]),
		'ムーンライト'     => Equip.new( 2, 2, 10,  0,  4, Vec[ 270,    0,    0,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'大腿骨砕き'       => Equip.new( 3, 3, 10,  0,  8, Vec[ 250,    0,    0,    0,    0,   20,    0,    0,    0], Vec[0, 0, 0]),
		'小竜咆哮'         => Equip.new( 4, 1, 10,  1,  4, Vec[  50,    0,    0,    0,    0,    0,  120,   50,    0], Vec[0, 0, 0]),
		'軍用弩'           => Equip.new( 5, 2, 10,  3,  0, Vec[ 300,    0,    0,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'大樹の杖'         => Equip.new( 6, 1, 10,  1,  6, Vec[   0,    0,   50,    0,   20,    0,    0,    0,  170], Vec[0, 0, 0]),
		'闇の書'           => Equip.new( 7, 1, 10, 11,  4, Vec[   0,    0,    0,    0,    0,    0,    0,    0,  200], Vec[0, 0, 0]),
		'グランクニーヴ'   => Equip.new( 0, 2, 10,  0,  5, Vec[ 150,    0,   50,    0,    0,    0,  100,   80,    0], Vec[1, 1, 1]),
		'デグルガウス'     => Equip.new( 1, 3, 10,  0,  5, Vec[ 220,    0,    0,    0,    0,   10,   20,   75,   60], Vec[0, 0, 0]),
		'竜剣ラウ'         => Equip.new( 2, 3, 10,  0,  4, Vec[ 240,   50,    0,  100,    0,    0,   50,    0,  100], Vec[0, 0, 0]),
		'覇王戦斧'         => Equip.new( 3, 4, 10,  0,  8, Vec[ 350,    0,    0,  100,    0,   50,    0,   20,    0], Vec[0, 0, 0]),
		'サジタリウス'     => Equip.new( 4, 3, 10,  1,  4, Vec[ 100,    0,    0,   50,    0,   30,  200,   30,   30], Vec[1, 1, 1]),
		'炎龍の息吹'       => Equip.new( 5, 3, 10,  3,  0, Vec[ 100,    0,    0,    0,   10,    0,  140,   30,    0], Vec[5, 0, 0]),
		'万物の杖'         => Equip.new( 6, 2, 10,  1,  6, Vec[  50,    0,    0,   20,   20,    0,   50,    0,  250], Vec[0, 0, 0]),
		'聖典'             => Equip.new( 7, 2, 10, 11,  4, Vec[ 100,    0,  100,   50,    0,    0,    0,    0,  200], Vec[0, 0, 0]),
		'陽炎の兜'         => Equip.new( 8, 3, 10,  2,  8, Vec[   0,  150,  100, 1000,    0,    0,    0,    0,    0], Vec[3, 0, 0]),
		'ボロボロな服'     => Equip.new(14, 1,  1,  2, 10, Vec[   0,    2,    1,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'異界の法衣'       => Equip.new(15, 2, 10,  2, 10, Vec[   0,  100,  400,  100,   10,    0,    0,    0,   50], Vec[1, 1, 1]),
		'竜盾デグノル'     => Equip.new(16, 3, 10,  2, 10, Vec[   0,  300,  250,  300,    0,    0,  150,    0,    0], Vec[0, 0, 3]),
		'天鬼の靴'         => Equip.new(22, 2, 10,  2, 10, Vec[   0,  100,  200,    0,   50,    0,    0,  200,    0], Vec[0, 3, 0]),
		'古びたペンダント' => Equip.new(27, 1, 10,  0,  6, Vec[   0,    0,    0,   50,    5,    0,    0,    0,    0], Vec[1, 1, 1]),
		'劣悪な短剣'       => Equip.new( 0, 1,  1,  0, 10, Vec[   5,    0,    0,    0,    0,    0,    1,    1,    0], Vec[0, 0, 0]),
		'劣悪な双短剣'     => Equip.new( 1, 2,  1,  0, 10, Vec[   7,    0,    0,    0,    0,    0,    0,    1,    0], Vec[0, 0, 0]),
		'劣悪な剣'         => Equip.new( 2, 2,  1,  0, 10, Vec[   6,    0,    0,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'劣悪な斧'         => Equip.new( 3, 3,  1,  0, 10, Vec[   9,    0,    0,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'劣悪な弓'         => Equip.new( 4, 1,  1,  1, 10, Vec[   3,    0,    0,    0,    0,    0,    4,    0,    0], Vec[0, 0, 0]),
		'劣悪な弩'         => Equip.new( 5, 2,  1,  1, 10, Vec[   4,    0,    0,    0,    0,    0,    2,    0,    0], Vec[0, 0, 0]),
		'劣悪な杖'         => Equip.new( 6, 2,  1,  4, 10, Vec[   1,    0,    0,    0,    0,    0,    0,    0,    5], Vec[0, 0, 0]),
		'劣悪な本'         => Equip.new( 7, 2,  1, 11, 10, Vec[   5,    0,    0,    0,    0,    0,    0,    0,    3], Vec[0, 0, 0]),
		'劣悪な重鎧'       => Equip.new(12, 3,  1,  0, 10, Vec[   0,    7,    0,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'劣悪な軽鎧'       => Equip.new(13, 2,  1,  3, 10, Vec[   0,    4,    0,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'劣悪な服'         => Equip.new(14, 1,  1,  2, 10, Vec[   0,    2,    1,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'劣悪なローブ'     => Equip.new(15, 1,  1,  2, 10, Vec[   0,    1,    3,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'劣悪な盾'         => Equip.new(16, 1,  1,  0, 10, Vec[   0,    4,    0,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0]),
		'劣悪な小手'       => Equip.new(17, 1,  1,  0, 10, Vec[   0,    2,    0,    0,    0,    0,    0,    0,    0], Vec[0, 0, 0])
	}
end
