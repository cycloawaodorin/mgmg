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
		opt.comp_min = comp_search(para, target, opt.smith_max, opt: opt)
		opt.smith_max = smith_search(para, target, opt.comp_min, opt: opt_nocut)
		opt.smith_min = smith_search(para, target, opt.comp_max, opt: opt_nocut)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.comp_min)
		opt.comp_max = comp_search(para, target, opt.smith_min, opt: opt)
		ret = nil
		exp = Mgmg.exp(opt.smith_min, opt.comp_max)
		opt.cut_exp, ret = exp, [opt.smith_min, opt.comp_max] if exp < opt.cut_exp
		exp = Mgmg.exp(opt.smith_max, opt.comp_min)
		opt.cut_exp, ret = exp, [opt.smith_max, opt.comp_min] if exp < opt.cut_exp
		(opt.comp_min+opt.step).step(opt.comp_max-1, opt.step) do |comp|
			break if opt.cut_exp < Mgmg.exp(opt.smith_min, comp)
			smith = smith_search(para, target, comp, opt: opt)
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
		raise Mgmg::SearchCutException, "the result exceeds given cut_exp=#{opt.cut_exp}" if ret.nil?
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
		opt.cut_exp, ret = exp, [opt.smith_min, opt.armor_max] if exp < opt.cut_exp
		exp2 = Mgmg.exp(opt.smith_max, opt.armor_min, comp)
		if exp2 < exp
			opt.cut_exp, ret = exp2, [opt.smith_max, opt.armor_min] if exp2 < opt.cut_exp
			(opt.armor_min+1).upto(opt.armor_max-1) do |armor|
				break if opt.cut_exp < Mgmg.exp(opt.smith_min, armor, comp)
				smith = smith_search(para, target, armor, comp, opt: opt)
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
				armor = armor_search(para, target, smith, comp, opt: opt)
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
	def search(para, target, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		opt.comp_min = comp_search(para, target, opt.smith_max, opt.armor_max, opt: opt)
		opt.smith_max, opt.armor_max = sa_search(para, target, opt.comp_min, opt: opt)
		opt.smith_min, opt.armor_min = sa_search(para, target, opt.comp_max, opt: opt)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.armor_min, opt.comp_min)
		opt.comp_max = comp_search(para, target, opt.smith_min, opt.armor_min, opt: opt)
		ret = nil
		exp = Mgmg.exp(opt.smith_min, opt.armor_min, opt.comp_max)
		opt.cut_exp, ret = exp, [opt.smith_min, opt.armor_min,opt. comp_max] if exp < opt.cut_exp
		exp = Mgmg.exp(opt.smith_max, opt.armor_max, opt.comp_min)
		opt.cut_exp, ret = exp, [opt.smith_max, opt.armor_max, opt.comp_min] if exp < opt.cut_exp
		(opt.comp_min+1).upto(opt.comp_max-1) do |comp|
			break if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.armor_min, comp)
			smith, armor = sa_search(para, target, comp, opt: opt)
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
		raise Mgmg::SearchCutException, "the result exceeds given cut_exp=#{opt.cut_exp}" if ret.nil?
		ret
	end
end

module Mgmg
	module_function def find_lowerbound(a, b, para, start, term, opt_a: Option.new, opt_b: Option.new)
		if term <= start
			raise ArgumentError, "start < term is needed, (start, term) = (#{start}, #{term}) are given"
		end
		opt_a, opt_b = opt_a.dup.set_default(a), opt_b.dup.set_default(b)
		sca, scb = a.search(para, start, opt: opt_a), b.search(para, start, opt: opt_b)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		if eb < ea || ( ea == eb && opt_a.irep.para_call(para, *sca) < opt_b.irep.para_call(para, *scb) )
			a, b, opt_a, opt_b, sca, scb, ea, eb = b, a, opt_b, opt_a, scb, sca, eb, ea
		end
		tag = opt_a.irep.para_call(para, *sca) + 1
		sca, scb = a.search(para, term, opt: opt_a), b.search(para, term, opt: opt_b)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		if ea < eb || ( ea == eb && opt_b.irep.para_call(para, *scb) < opt_a.irep.para_call(para, *sca) )
			raise Mgmg::SearchCutException
		end
		while tag < term
			sca, scb = a.search(para, tag, opt: opt_a), b.search(para, tag, opt: opt_b)
			ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
			pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
			if eb < ea
				return [tag-1, pb]
			elsif ea == eb
				if pa < pb
					return [tag-1, pa]
				else
					tag = pb + 1
				end
			else
				tag = pa + 1
			end
		end
		raise UnexpectedError
	end
	
	module_function def find_upperbound(a, b, para, start, term, opt_a: Option.new, opt_b: Option.new)
		if start <= term
			raise ArgumentError, "term < start is needed, (start, term) = (#{start}, #{term}) are given"
		end
		opt_a, opt_b = opt_a.dup.set_default(a), opt_b.dup.set_default(b)
		sca, scb = a.search(para, start, opt: opt_a), b.search(para, start, opt: opt_b)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		if ea < eb || ( ea == eb && opt_b.irep.para_call(para, *scb) < opt_a.irep.para_call(para, *sca) )
			a, b, opt_a, opt_b, sca, scb, ea, eb = b, a, opt_b, opt_a, scb, sca, eb, ea
		end
		tagu = opt_a.irep.para_call(para, *sca)
		sca[-1] -= 2
		tagl = opt_a.irep.para_call(para, *sca)
		sca, scb = a.search(para, term, opt: opt_a), b.search(para, term, opt: opt_b)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		if eb < ea || ( ea == eb && opt_a.irep.para_call(para, *sca) < opt_b.irep.para_call(para, *scb) )
			raise Mgmg::SearchCutException
		end
		while term < tagu
			ret = nil
			sca = a.search(para, tagl, opt: opt_a)
			next_tagu, next_sca = tagl, sca
			scb = b.search(para, tagl, opt: opt_b)
			while tagl < tagu
				ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
				pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
				if ea < eb
					ret = tagl
					sca = a.search(para, pa + 1, opt: opt_a)
					tagl = opt_a.irep.para_call(para, *sca)
					scb = b.search(para, tagl, opt: opt_b)
				elsif ea == eb
					if pb < pa
						ret = tagl
						sca = a.search(para, pa + 1, opt: opt_a)
						tagl = opt_a.irep.para_call(para, *sca)
						scb = b.search(para, tagl, opt: opt_b)
					else
						scb = b.search(para, pb + 1, opt: opt_b)
						tagl = opt_b.irep.para_call(para, *scb)
						sca = a.search(para, tagl, opt: opt_a)
					end
				else
					sca = a.search(para, pa + 1, opt: opt_a)
					tagl = opt_a.irep.para_call(para, *sca)
					scb = b.search(para, tagl, opt: opt_b)
				end
			end
			if ret.nil?
				tagu = next_tagu
				next_sca[-1] -= 2
				tagl = opt_a.irep.para_call(para, *next_sca)
				if tagl == tagu
					tagl = term
				end
			else
				pa = opt_a.irep.para_call(para, *a.search(para, ret+1, opt: opt_a))
				pb = opt_b.irep.para_call(para, *b.search(para, ret+1, opt: opt_b))
				return [ret, [pa, pb].min]
			end
		end
		raise UnexpectedError
	end
end
