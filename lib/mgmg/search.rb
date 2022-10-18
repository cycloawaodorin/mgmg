using Mgmg::Refiner
class String
	def smith_search(para, target, comp, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		if opt.smith_max < opt.smith_min
			raise ArgumentError, "smith_min <= smith_max is needed, (smith_min, smith_max) = (#{opt.smith_min}, #{opt.smith_max}) are given"
		elsif opt.cut_exp < Float::INFINITY
			begin
				opt.smith_max = [opt.smith_max, Mgmg.invexp2(opt.cut_exp, comp)].min
			rescue
				raise Mgmg::SearchCutException
			end
		end
		if target <= opt.irep.para_call(para, opt.smith_min, comp)
			return opt.smith_min
		elsif opt.irep.para_call(para, opt.smith_max, comp) < target
			raise Mgmg::SearchCutException
		end
		while 1 < opt.smith_max - opt.smith_min do
			smith = (opt.smith_max - opt.smith_min).div(2) + opt.smith_min
			if opt.irep.para_call(para, smith, comp) < target
				opt.smith_min = smith
			else
				opt.smith_max = smith
			end
		end
		opt.smith_max
	end
	def comp_search(para, target, smith, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		if opt.comp_max < opt.comp_min
			raise ArgumentError, "comp_min <= comp_max is needed, (comp_min, comp_max) = (#{opt.comp_min}, #{opt.comp_max}) are given"
		end
		if target <= opt.irep.para_call(para, smith, opt.comp_min)
			return opt.comp_min
		elsif opt.irep.para_call(para, smith, opt.comp_max) < target
			raise Mgmg::SearchCutException
		end
		while 1 < opt.comp_max - opt.comp_min do
			comp = (opt.comp_max - opt.comp_min).div(2) + opt.comp_min
			if opt.irep.para_call(para, smith, comp) < target
				opt.comp_min = comp
			else
				opt.comp_max = comp
			end
		end
		opt.comp_max
	end
	def search(para, target, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		opt_nocut = opt.dup; opt_nocut.cut_exp = Float::INFINITY
		opt.comp_min = comp_search(para, target, opt.smith_max, opt:)
		opt.smith_max = smith_search(para, target, opt.comp_min, opt: opt_nocut)
		opt.smith_min = smith_search(para, target, opt.comp_max, opt: opt_nocut)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.comp_min)
		opt.comp_max = comp_search(para, target, opt.smith_min, opt:)
		ret = nil
		exp = Mgmg.exp(opt.smith_min, opt.comp_max)
		opt.cut_exp, ret = exp, [opt.smith_min, opt.comp_max] if exp <= opt.cut_exp
		exp = Mgmg.exp(opt.smith_max, opt.comp_min)
		opt.cut_exp, ret = exp, [opt.smith_max, opt.comp_min] if ( exp < opt.cut_exp || (ret.nil? && exp==opt.cut_exp) )
		(opt.comp_min+opt.step).step(opt.comp_max-1, opt.step) do |comp|
			break if opt.cut_exp < Mgmg.exp(opt.smith_min, comp)
			smith = smith_search(para, target, comp, opt:)
			exp = Mgmg.exp(smith, comp)
			if exp < opt.cut_exp
				opt.cut_exp, ret = exp, [smith, comp]
			elsif exp == opt.cut_exp
				if ret.nil? or opt.irep.para_call(para, *ret) < opt.irep.para_call(para, smith, comp) then
					ret = [smith, comp]
				end
			end
		rescue Mgmg::SearchCutException
		end
		if ret.nil?
			max = opt.irep.para_call(para, *find_max(para, opt.cut_exp, opt:))
			raise Mgmg::SearchCutException, "the maximum output with given cut_exp=#{opt.cut_exp.comma3} is #{max.comma3}, which does not reach given target=#{target.comma3}"
		end
		ret
	end
	
	private def minimize_smith(para, smith, comp, cur, opt)
		(smith-1).downto(opt.smith_min) do |s|
			foo = opt.irep.para_call(para, s, comp)
			if cur == foo
				smith = s
			else
				break
			end
		end
		smith
	end
	def find_max(para, max_exp, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		exp = Mgmg.exp(opt.smith_min, opt.comp_min)
		raise Mgmg::SearchCutException, "the recipe requires #{exp.comma3} experiment points, which exceeds given max_exp=#{max_exp.comma3}" if max_exp < exp
		ret = [Mgmg.invexp2(max_exp, opt.comp_min), opt.comp_min]
		max = opt.irep.para_call(para, *ret)
		(opt.comp_min+1).upto(Mgmg.invexp2c(max_exp, opt.smith_min)) do |comp|
			smith = Mgmg.invexp2(max_exp, comp)
			cur = opt.irep.para_call(para, smith, comp)
			smith = minimize_smith(para, smith, comp, cur, opt) if max <= cur
			ret, max = [smith, comp], cur if ( max < cur || ( max == cur && Mgmg.exp(smith, comp) < Mgmg.exp(*ret) ) )
		end
		ret
	end
end
module Enumerable
	def smith_search(para, target, armor, comp, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		if opt.smith_max < opt.smith_min
			raise ArgumentError, "smith_min <= smith_max is needed, (smith_min, smith_max) = (#{opt.smith_min}, #{opt.smith_max}) are given"
		elsif opt.cut_exp < Float::INFINITY
			begin
				opt.smith_max = [opt.smith_max, Mgmg.invexp3(opt.cut_exp, armor, comp)].min
			rescue
				raise Mgmg::SearchCutException
			end
		end
		if opt.irep.para_call(para, opt.smith_max, armor, comp) < target
			raise Mgmg::SearchCutException
		elsif target <= opt.irep.para_call(para, opt.smith_min, armor, comp)
			return opt.smith_min
		end
		while 1 < opt.smith_max - opt.smith_min do
			smith = (opt.smith_max - opt.smith_min).div(2) + opt.smith_min
			if opt.irep.para_call(para, smith, armor, comp) < target
				opt.smith_min = smith
			else
				opt.smith_max = smith
			end
		end
		opt.smith_max
	end
	def armor_search(para, target, smith, comp, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		if opt.armor_max < opt.armor_min
			raise ArgumentError, "armor_min <= armor_max is needed, (armor_min, armor_max) = (#{opt.armor_min}, #{opt.armor_max}) are given"
		elsif opt.cut_exp < Float::INFINITY
			begin
				opt.armor_max = [opt.armor_max, Mgmg.invexp3(opt.cut_exp, smith, comp)].min
			rescue
				raise Mgmg::SearchCutException
			end
		end
		if opt.irep.para_call(para, smith, opt.armor_max, comp) < target
			raise Mgmg::SearchCutException
		elsif target <= opt.irep.para_call(para, smith, opt.armor_min, comp)
			return opt.armor_min
		end
		while 1 < opt.armor_max - opt.armor_min do
			armor = (opt.armor_max - opt.armor_min).div(2) + opt.armor_min
			if opt.irep.para_call(para, smith, armor, comp) < target
				opt.armor_min = armor
			else
				opt.armor_max = armor
			end
		end
		opt.armor_max
	end
	def sa_search(para, target, comp, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		opt_nocut = opt.dup; opt_nocut.cut_exp = Float::INFINITY
		opt.smith_min = smith_search(para, target, opt.armor_max, comp, opt: opt_nocut)
		opt.armor_min = armor_search(para, target, opt.smith_max, comp, opt: opt_nocut)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.armor_min, comp)
		opt.smith_max = smith_search(para, target, opt.armor_min, comp, opt: opt_nocut)
		opt.armor_max = armor_search(para, target, opt.smith_min, comp, opt: opt_nocut)
		ret = nil
		exp = Mgmg.exp(opt.smith_min, opt.armor_max, comp)
		opt.cut_exp, ret = exp, [opt.smith_min, opt.armor_max] if exp <= opt.cut_exp
		exp2 = Mgmg.exp(opt.smith_max, opt.armor_min, comp)
		if exp2 < exp
			opt.cut_exp, ret = exp2, [opt.smith_max, opt.armor_min] if exp2 <= opt.cut_exp
			(opt.armor_min+1).upto(opt.armor_max-1) do |armor|
				break if opt.cut_exp < Mgmg.exp(opt.smith_min, armor, comp)
				smith = smith_search(para, target, armor, comp, opt:)
				exp = Mgmg.exp(smith, armor, comp)
				if exp < opt.cut_exp
					opt.cut_exp, ret = exp, [smith, armor]
				elsif exp == opt.cut_exp
					if ret.nil? or opt.irep.para_call(para, *ret, comp) < opt.irep.para_call(para, smith, armor, comp) then
						ret = [smith, armor]
					end
				end
			rescue Mgmg::SearchCutException
			end
		else
			(opt.smith_min+1).upto(opt.smith_max-1) do |smith|
				break if opt.cut_exp < Mgmg.exp(smith, opt.armor_min, comp)
				armor = armor_search(para, target, smith, comp, opt:)
				exp = Mgmg.exp(smith, armor, comp)
				if exp < opt.cut_exp
					opt.cut_exp, ret = exp, [smith, armor]
				elsif exp == opt.cut_exp
					if ret.nil? or opt.irep.para_call(para, *ret, comp) < opt.irep.para_call(para, smith, armor, comp) then
						ret = [smith, armor]
					end
				end
			rescue Mgmg::SearchCutException
			end
		end
		raise Mgmg::SearchCutException if ret.nil?
		ret
	end
	def comp_search(para, target, smith, armor, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		if opt.comp_max < opt.comp_min
			raise ArgumentError, "comp_min <= comp_max is needed, (comp_min, comp_max) = (#{opt.comp_min}, #{opt.comp_max}) are given"
		end
		if target <= opt.irep.para_call(para, smith, armor, opt.comp_min)
			return opt.comp_min
		elsif opt.irep.para_call(para, smith, armor, opt.comp_max) < target
			raise ArgumentError, "given comp_max=#{opt.comp_max} does not satisfies the target"
		end
		while 1 < opt.comp_max - opt.comp_min do
			comp = (opt.comp_max - opt.comp_min).div(2) + opt.comp_min
			if opt.irep.para_call(para, smith, armor, comp) < target
				opt.comp_min = comp
			else
				opt.comp_max = comp
			end
		end
		opt.comp_max
	end
	private def search_aonly(para, target, opt: Mgmg::Option.new)
		opt_nocut = opt.dup; opt_nocut.cut_exp = Float::INFINITY
		opt.armor_max = armor_search(para, target, -1, opt.comp_min, opt: opt_nocut)
		opt.armor_min = armor_search(para, target, -1, opt.comp_max, opt: opt_nocut)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.armor_min, opt.comp_min)
		opt.comp_max = comp_search(para, target, -1, opt.armor_min, opt:)
		ret = nil
		exp = Mgmg.exp(opt.armor_min, opt.comp_max)
		opt.cut_exp, ret = exp, [-1, opt.armor_min, opt.comp_max] if exp <= opt.cut_exp
		exp = Mgmg.exp(opt.armor_max, opt.comp_min)
		opt.cut_exp, ret = exp, [-1, opt.armor_max, opt.comp_min] if ( exp < opt.cut_exp || (ret.nil? && exp==opt.cut_exp) )
		(opt.comp_min+opt.step).step(opt.comp_max-1, opt.step) do |comp|
			break if opt.cut_exp < Mgmg.exp(opt.armor_min, comp)
			armor = armor_search(para, target, -1, comp, opt:)
			exp = Mgmg.exp(armor, comp)
			if exp < opt.cut_exp
				opt.cut_exp, ret = exp, [-1, armor, comp]
			elsif exp == opt.cut_exp
				if ret.nil? or opt.irep.para_call(para, *ret) < opt.irep.para_call(para, -1, armor, comp) then
					ret = [-1, armor, comp]
				end
			end
		rescue Mgmg::SearchCutException
		end
		if ret.nil?
			max = opt.irep.para_call(para, *find_max(para, opt.cut_exp, opt:))
			raise Mgmg::SearchCutException, "the maximum output with given cut_exp=#{opt.cut_exp.comma3} is #{max.comma3}, which does not reach given target=#{target.comma3}"
		end
		ret
	end
	private def search_sonly(para, target, opt: Mgmg::Option.new)
		opt_nocut = opt.dup; opt_nocut.cut_exp = Float::INFINITY
		opt.smith_max = smith_search(para, target, -1, opt.comp_min, opt: opt_nocut)
		opt.smith_min = smith_search(para, target, -1, opt.comp_max, opt: opt_nocut)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.comp_min)
		opt.comp_max = comp_search(para, target, opt.smith_min, -1, opt:)
		ret = nil
		exp = Mgmg.exp(opt.smith_min, opt.comp_max)
		opt.cut_exp, ret = exp, [opt.smith_min, -1, opt.comp_max] if exp <= opt.cut_exp
		exp = Mgmg.exp(opt.smith_max, opt.comp_min)
		opt.cut_exp, ret = exp, [opt.smith_max, -1, opt.comp_min] if ( exp < opt.cut_exp || (ret.nil? && exp==opt.cut_exp) )
		(opt.comp_min+opt.step).step(opt.comp_max-1, opt.step) do |comp|
			break if opt.cut_exp < Mgmg.exp(opt.smith_min, comp)
			smith = smith_search(para, target, -1, comp, opt:)
			exp = Mgmg.exp(smith, comp)
			if exp < opt.cut_exp
				opt.cut_exp, ret = exp, [smith, -1, comp]
			elsif exp == opt.cut_exp
				if ret.nil? or opt.irep.para_call(para, *ret) < opt.irep.para_call(para, smith, -1, comp) then
					ret = [smith, -1, comp]
				end
			end
		rescue Mgmg::SearchCutException
		end
		if ret.nil?
			max = opt.irep.para_call(para, *find_max(para, opt.cut_exp, opt:))
			raise Mgmg::SearchCutException, "the maximum output with given cut_exp=#{opt.cut_exp.comma3} is #{max.comma3}, which does not reach given target=#{target.comma3}"
		end
		ret
	end
	def search(para, target, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		opt.comp_min = comp_search(para, target, opt.smith_max, opt.armor_max, opt:)
		opt_nocut = opt.dup; opt_nocut.cut_exp = Float::INFINITY
		opt.smith_max = smith_search(para, target, opt.armor_min, opt.comp_min, opt: opt_nocut) rescue ( return search_aonly(para, target, opt:) )
		opt.armor_max = armor_search(para, target, opt.smith_min, opt.comp_min, opt: opt_nocut) rescue ( return search_sonly(para, target, opt:) )
		opt.smith_min = smith_search(para, target, opt.armor_max, opt.comp_max, opt: opt_nocut)
		opt.armor_min = armor_search(para, target, opt.smith_max, opt.comp_max, opt: opt_nocut)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.armor_min, opt.comp_min)
		opt.comp_max = comp_search(para, target, opt.smith_min, opt.armor_min, opt:)
		exp = Mgmg.exp(opt.smith_min, opt.armor_min, opt.comp_max)
		opt.cut_exp, ret = exp, [opt.smith_min, opt.armor_min,opt. comp_max] if exp <= opt.cut_exp
		(opt.comp_min).upto(opt.comp_max-1) do |comp|
			break if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.armor_min, comp)
			smith, armor = sa_search(para, target, comp, opt:)
			exp = Mgmg.exp(smith, armor, comp)
			if exp < opt.cut_exp
				opt.cut_exp, ret = exp, [smith, armor, comp]
			elsif exp == opt.cut_exp
				if ret.nil? or opt.irep.para_call(para, *ret) < opt.irep.para_call(para, smith, armor, comp) then
					ret = [smith, armor, comp]
				end
			end
		rescue Mgmg::SearchCutException
		end
		if ret.nil?
			max = opt.irep.para_call(para, *find_max(para, opt.cut_exp, opt:))
			raise Mgmg::SearchCutException, "the maximum output with given cut_exp=#{opt.cut_exp.comma3} is #{max.comma3}, which does not reach given target=#{target.comma3}"
		end
		ret
	end
	
	private def minimize_smith(para, smith, armor, comp, cur, opt)
		return -1 if opt.smith_min < 0
		(smith-1).downto(opt.smith_min) do |s|
			foo = opt.irep.para_call(para, s, armor, comp)
			if cur == foo
				smith = s
			else
				break
			end
		end
		smith
	end
	def find_max(para, max_exp, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		exp = Mgmg.exp(opt.smith_min, opt.armor_min, opt.comp_min)
		raise Mgmg::SearchCutException, "the recipe requires #{exp.comma3} experiment points, which exceeds given max_exp=#{max_exp.comma3}" if max_exp < exp
		ret = [Mgmg.invexp3(max_exp, opt.armor_min, opt.comp_min), opt.armor_min, opt.comp_min]
		max = opt.irep.para_call(para, *ret)
		(opt.comp_min).step(Mgmg.invexp3c(max_exp, opt.smith_min, opt.armor_min), opt.step) do |comp|
			opt.armor_min.upto(Mgmg.invexp3(max_exp, opt.smith_min, comp)) do |armor|
				smith = Mgmg.invexp3(max_exp, armor, comp)
				cur = opt.irep.para_call(para, smith, armor, comp)
				smith = minimize_smith(para, smith, armor, comp, cur, opt) if max <= cur
				ret, max = [smith, armor, comp], cur if ( max < cur || ( max == cur && Mgmg.exp(smith, armor, comp) < Mgmg.exp(*ret) ) )
				break if armor < 0
			end
		end
		ret
	end
end

module Mgmg
	Eighth = 1.quo(8)
	module_function def find_lowerbound(a, b, para, start, term, opt_a: Option.new, opt_b: Option.new)
		if term <= start
			raise ArgumentError, "start < term is needed, (start, term) = (#{start}, #{term}) are given"
		end
		if a.kind_of?(Recipe)
			opt_a = a.option.dup
			a = a.recipe.dup
		else
			opt_a = opt_a.dup.set_default(a)
		end
		if b.kind_of?(Recipe)
			opt_b = b.option.dup
			b = b.recipe.dup
		else
			opt_b = opt_b.dup.set_default(b)
		end
		sca, scb = a.search(para, start, opt: opt_a), b.search(para, start, opt: opt_b)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
		if eb < ea || ( ea == eb && pa < pb )
			a, b, opt_a, opt_b, sca, scb, ea, eb = b, a, opt_b, opt_a, scb, sca, eb, ea
		end
		
		loop do
			loop do
				foo = a.find_max(para, eb, opt: opt_a)
				break if sca == foo
				sca, pa = foo, opt_a.irep.para_call(para, *foo)
				scb = b.search(para, pa, opt: opt_b)
				foo = Mgmg.exp(*scb)
				break if eb == foo
				eb = foo
			end
			ea = Mgmg.exp(*sca)
			while ea<=eb
				tag = pa + Eighth
				raise Mgmg::SearchCutException, "given recipes are never reversed from start target=#{start.comma3} until term target=#{term.comma3}" if term < tag
				sca, scb = a.search(para, tag, opt: opt_a), b.search(para, tag, opt: opt_b)
				ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
				pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
				break if ea == eb && pa < pb
			end
			if eb < ea || ( ea == eb && pa < pb )
				until ea < eb || ( ea == eb && pb < pa )
					sca = a.find_max(para, ea-1, opt: opt_a)
					ea, pa = Mgmg.exp(*sca), opt_a.irep.para_call(para, *sca)
				end
				return [pa, pb]
			end
		end
		raise UnexpectedError
	end
	
	module_function def find_upperbound(a, b, para, start, opt_a: Option.new, opt_b: Option.new)
		if a.kind_of?(Recipe)
			opt_a = a.option.dup
			a = a.recipe
		else
			opt_a = opt_a.dup.set_default(a)
		end
		if b.kind_of?(Recipe)
			opt_b = b.option.dup
			b = b.recipe
		else
			opt_b = opt_b.dup.set_default(b)
		end
		sca, scb = a.search(para, start, opt: opt_a), b.search(para, start, opt: opt_b)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
		if ea < eb || ( ea == eb && pb < pa )
			a, b, opt_a, opt_b, sca, scb, ea, eb = b, a, opt_b, opt_a, scb, sca, eb, ea
		end
		
		loop do
			loop do
				foo = a.find_max(para, eb, opt: opt_a)
				break if sca == foo
				sca, pa = foo, opt_a.irep.para_call(para, *foo)
				scb = b.search(para, pa, opt: opt_b)
				foo = Mgmg.exp(*scb)
				break if eb == foo
				eb = foo
			end
			ea = Mgmg.exp(*sca)
			while ea==eb do
				res = 0
				begin
					sca = a.find_max(para, ea-1, opt: opt_a)
				rescue Mgmg::SearchCutException
					res += 1
				end
				begin
					scb = b.find_max(para, eb-1, opt: opt_b)
				rescue Mgmg::SearchCutException
					res += 1
				end
				ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
				pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
				if ea < eb || ( ea == eb && pb < pa )
					until pa < pb
						scb = b.search(para, pb+Eighth, opt: opt_b)
						pb = opt_b.irep.para_call(para, *scb)
					end
					return [pa, pb]
				elsif res == 2
					raise Mgmg::SearchCutException, "given recipes are never reversed from the start target=#{start.comma3} until #{pa.comma3}"
				end
			end
			if ea < eb
				pb = opt_b.irep.para_call(para, *scb)
				until pa < pb
					scb = b.search(para, pb+Eighth, opt: opt_b)
					pb = opt_b.irep.para_call(para, *scb)
				end
				return [pa, pb]
			end
		end
		raise UnexpectedError
	end
	
	module_function def find_lubounds(a, b, para, lower, upper, opt_a: Mgmg::Option.new, opt_b: Mgmg::Option.new)
		xl, yl = find_lowerbound(a, b, para, lower, upper, opt_a:, opt_b:)
		xu, yu = find_upperbound(a, b, para, upper, opt_a:, opt_b:)
		[xl, yl, xu, yu]
	end
	module_function def find_lubounds2(a, b, para, lower, upper, opt_a: Mgmg::Option.new, opt_b: Mgmg::Option.new)
		xl, yl, xu, yu = find_lubounds(a, b, para, lower, upper, opt_a: Mgmg::Option.new, opt_b: Mgmg::Option.new)
		if a.kind_of?(Recipe)
			opt_a = a.option.dup
			a = a.recipe
		else
			opt_a = opt_a.dup.set_default(a)
		end
		if b.kind_of?(Recipe)
			opt_b = b.option.dup
			b = b.recipe
		else
			opt_b = opt_b.dup.set_default(b)
		end
		sca, scb = a.search(para, lower, opt: opt_a), b.search(para, lower, opt: opt_b)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
		if eb < ea || ( ea == eb && pa < pb )
			a, b, opt_a, opt_b, sca, scb, ea, eb = b, a, opt_b, opt_a, scb, sca, eb, ea
		end
		sca, scb = a.search(para, xl, opt: opt_a), b.search(para, yu, opt: opt_b)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
		[sca, ea, pa, scb, eb, pb]
	end
end
