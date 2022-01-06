class String
	def smith_search(para, target, comp, smith_min=nil, smith_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false, irep: nil)
		irep = ir(left_associative: left_associative) if irep.nil?
		if smith_min.nil?
			if min_smith
				smith_min = self.min_smith.min_smith
			else
				smith_min = build(-1, -1, left_associative: left_associative).min_level
			end
		end
		if smith_max < smith_min
			raise ArgumentError, "smith_min <= smith_max is needed, (smith_min, smith_max) = (#{smith_min}, #{smith_max}) are given"
		elsif cut_exp < Float::INFINITY
			begin
				smith_max = [smith_max, Mgmg.invexp2(cut_exp, comp)].min
			rescue
				raise Mgmg::SearchCutException
			end
		end
		if target <= irep.para_call(para, smith_min, comp)
			return smith_min
		elsif irep.para_call(para, smith_max, comp) < target
			raise Mgmg::SearchCutException
		end
		while 1 < smith_max - smith_min do
			smith = (smith_max - smith_min).div(2) + smith_min
			if irep.para_call(para, smith, comp) < target
				smith_min = smith
			else
				smith_max = smith
			end
		end
		smith_max
	end
	def comp_search(para, target, smith, comp_min=nil, comp_max=10000, left_associative: true, irep: nil)
		irep = ir(left_associative: left_associative) if irep.nil?
		comp_min = min_comp(left_associative: left_associative)
		if comp_max < comp_min
			raise ArgumentError, "comp_min <= comp_max is needed, (comp_min, comp_max) = (#{comp_min}, #{comp_max}) are given"
		end
		if target <= irep.para_call(para, smith, comp_min)
			return comp_min
		elsif irep.para_call(para, smith, comp_max) < target
			raise Mgmg::SearchCutException
		end
		while 1 < comp_max - comp_min do
			comp = (comp_max - comp_min).div(2) + comp_min
			if irep.para_call(para, smith, comp) < target
				comp_min = comp
			else
				comp_max = comp
			end
		end
		comp_max
	end
	def search(para, target, smith_min=nil, comp_min=nil, smith_max=10000, comp_max=10000, left_associative: true, step: 1, cut_exp: Float::INFINITY, min_smith: false, irep: nil)
		irep = ir(left_associative: left_associative) if irep.nil?
		if smith_min.nil?
			if min_smith
				smith_min = self.min_smith
			else
				smith_min = build(-1, -1, left_associative: left_associative).min_level
			end
		end
		comp_min = min_comp(left_associative: left_associative) if comp_min.nil?
		comp_min = comp_search(para, target, smith_max, comp_min, comp_max, left_associative: left_associative, irep: irep)
		smith_max = smith_search(para, target, comp_min, smith_min, smith_max, left_associative: left_associative, irep: irep)
		smith_min = smith_search(para, target, comp_max, smith_min, smith_max, left_associative: left_associative, irep: irep)
		raise Mgmg::SearchCutException if cut_exp < Mgmg.exp(smith_min, comp_min)
		comp_max = comp_search(para, target, smith_min, comp_min, comp_max, left_associative: left_associative, irep: irep)
		minex, ret = Mgmg.exp(smith_min, comp_max), [smith_min, comp_max]
		exp = Mgmg.exp(smith_max, comp_min)
		minex, ret = exp, [smith_max, comp_min] if exp < minex
		(comp_min+step).step(comp_max-1, step) do |comp|
			break if minex < Mgmg.exp(smith_min, comp)
			smith = smith_search(para, target, comp, smith_min, smith_max, left_associative: left_associative, cut_exp: [minex, cut_exp].min)
			exp = Mgmg.exp(smith, comp)
			if exp < minex
				minex, ret = exp, [smith, comp]
			elsif exp == minex
				if irep.para_call(para, *ret) < irep.para_call(para, smith, comp)
					ret = [smith, comp]
				end
			end
		rescue Mgmg::SearchCutException
		end
		raise Mgmg::SearchCutException, "the result exceeds given cut_exp=#{cut_exp}" if cut_exp < minex
		ret
	end
end
module Enumerable
	def smith_search(para, target, armor, comp, smith_min=nil, smith_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false, irep: nil)
		irep = ir(left_associative: left_associative) if irep.nil?
		if smith_min.nil?
			if min_smith
				smith_min = self.min_smith[0]
			else
				smith_min = build(-1, -1, -1, left_associative: left_associative).min_level[0]
			end
		end
		if smith_max < smith_min
			raise ArgumentError, "smith_min <= smith_max is needed, (smith_min, smith_max) = (#{smith_min}, #{smith_max}) are given"
		elsif cut_exp < Float::INFINITY
			begin
				smith_max = [smith_max, Mgmg.invexp3(cut_exp, armor, comp)].min
			rescue
				raise Mgmg::SearchCutException
			end
		end
		if irep.para_call(para, smith_max, armor, comp) < target
			raise Mgmg::SearchCutException
		elsif target <= irep.para_call(para, smith_min, armor, comp)
			return smith_min
		end
		while 1 < smith_max - smith_min do
			smith = (smith_max - smith_min).div(2) + smith_min
			if irep.para_call(para, smith, armor, comp) < target
				smith_min = smith
			else
				smith_max = smith
			end
		end
		smith_max
	end
	def armor_search(para, target, smith, comp, armor_min=nil, armor_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false, irep: nil)
		irep = ir(left_associative: left_associative) if irep.nil?
		if armor_min.nil?
			if min_smith
				armor_min = self.min_smith[1]
			else
				armor_min = build(-1, -1, -1, left_associative: left_associative).min_level[1]
			end
		end
		if armor_max < armor_min
			raise ArgumentError, "armor_min <= armor_max is needed, (armor_min, armor_max) = (#{armor_min}, #{armor_max}) are given"
		elsif cut_exp < Float::INFINITY
			begin
				armor_max = [armor_max, Mgmg.invexp3(cut_exp, smith, comp)].min
			rescue
				raise Mgmg::SearchCutException
			end
		end
		if irep.para_call(para, smith, armor_max, comp) < target
			raise Mgmg::SearchCutException
		elsif target <= irep.para_call(para, smith, armor_min, comp)
			return armor_min
		end
		while 1 < armor_max - armor_min do
			armor = (armor_max - armor_min).div(2) + armor_min
			if irep.para_call(para, smith, armor, comp) < target
				armor_min = armor
			else
				armor_max = armor
			end
		end
		armor_max
	end
	def sa_search(para, target, comp, smith_min=nil, armor_min=nil, smith_max=10000, armor_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false, irep: nil)
		irep = ir(left_associative: left_associative) if irep.nil?
		if min_smith
			s, a = self.min_smith
		else
			s, a = build(-1, -1, -1, left_associative: left_associative).min_level
		end
		smith_min = s if smith_min.nil?
		armor_min = a if armor_min.nil?
		smith_min = smith_search(para, target, armor_max, comp, smith_min, smith_max, left_associative: true, irep: irep)
		armor_min = armor_search(para, target, smith_max, comp, armor_min, armor_max, left_associative: true, irep: irep)
		raise Mgmg::SearchCutException if cut_exp < Mgmg.exp(smith_min, armor_min, comp)
		smith_max = smith_search(para, target, armor_min, comp, smith_min, smith_max, left_associative: true, irep: irep)
		armor_max = armor_search(para, target, smith_min, comp, armor_min, armor_max, left_associative: true, irep: irep)
		minex, ret = Mgmg.exp(smith_min, armor_max, comp), [smith_min, armor_max]
		exp = Mgmg.exp(smith_max, armor_min, comp)
		if exp < minex
			minex, ret = exp, [smith_max, armor_min]
			(armor_min+1).upto(armor_max-1) do |armor|
				break if minex < Mgmg.exp(smith_min, armor, comp)
				smith = smith_search(para, target, armor, comp, smith_min, smith_max, left_associative: left_associative, cut_exp: [minex, cut_exp].min, irep: irep)
				exp = Mgmg.exp(smith, armor, comp)
				if exp < minex
					minex, ret = exp, [smith, armor]
				elsif exp == minex
					if irep.para_call(para, *ret, comp) < irep.para_call(para, smith, armor, comp)
						ret = [smith, armor]
					end
				end
			rescue Mgmg::SearchCutException
			end
		else
			(smith_min+1).upto(smith_max-1) do |smith|
				break if minex < Mgmg.exp(smith, armor_min, comp)
				armor = armor_search(para, target, smith, comp, armor_min, armor_max, left_associative: left_associative, cut_exp: [minex, cut_exp].min, irep: irep)
				exp = Mgmg.exp(smith, armor, comp)
				if exp < minex
					minex, ret = exp, [smith, armor]
				elsif exp == minex
					if irep.para_call(para, *ret, comp) < irep.para_call(para, smith, armor, comp)
						ret = [smith, armor]
					end
				end
			rescue Mgmg::SearchCutException
			end
		end
		raise Mgmg::SearchCutException if cut_exp < minex
		ret
	end
	def comp_search(para, target, smith, armor, comp_min=nil, comp_max=10000, left_associative: true, irep: nil)
		irep = ir(left_associative: left_associative) if irep.nil?
		comp_min = min_comp(left_associative: left_associative)
		if comp_max < comp_min
			raise ArgumentError, "comp_min <= comp_max is needed, (comp_min, comp_max) = (#{comp_min}, #{comp_max}) are given"
		end
		if target <= irep.para_call(para, smith, armor, comp_min)
			return comp_min
		elsif irep.para_call(para, smith, armor, comp_max) < target
			raise ArgumentError, "given comp_max=#{comp_max} does not satisfies the target"
		end
		while 1 < comp_max - comp_min do
			comp = (comp_max - comp_min).div(2) + comp_min
			if irep.para_call(para, smith, armor, comp) < target
				comp_min = comp
			else
				comp_max = comp
			end
		end
		comp_max
	end
	def search(para, target, smith_min=nil, armor_min=nil, comp_min=nil, smith_max=10000, armor_max=10000, comp_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false, irep: nil)
		irep = ir(left_associative: left_associative) if irep.nil?
		if min_smith
			s, a = self.min_smith
		else
			s, a = build(-1, -1, -1, left_associative: left_associative).min_level
		end
		smith_min = s if smith_min.nil?
		armor_min = a if armor_min.nil?
		comp_min = min_comp(left_associative: left_associative) if comp_min.nil?
		comp_min = comp_search(para, target, smith_max, armor_max, comp_min, comp_max, left_associative: left_associative, irep: irep)
		smith_max, armor_max = sa_search(para, target, comp_min, smith_min, armor_min, smith_max, armor_max, left_associative: left_associative, irep: irep)
		smith_min, armor_min = sa_search(para, target, comp_max, smith_min, armor_min, smith_max, armor_max, left_associative: left_associative, irep: irep)
		raise Mgmg::SearchCutException if cut_exp < Mgmg.exp(smith_min, armor_min, comp_min)
		comp_max = comp_search(para, target, smith_min, armor_min, comp_min, comp_max, left_associative: left_associative, irep: irep)
		minex, ret = Mgmg.exp(smith_min, armor_min, comp_max), [smith_min, armor_min, comp_max]
		exp = Mgmg.exp(smith_max, armor_max, comp_min)
		minex, ret = exp, [smith_max, armor_max, comp_min] if exp < minex
		(comp_min+1).upto(comp_max-1) do |comp|
			break if minex < Mgmg.exp(smith_min, armor_min, comp)
			smith, armor = sa_search(para, target, comp, smith_min, armor_min, smith_max, armor_max, left_associative: left_associative, cut_exp: [minex, cut_exp].min, irep: irep)
			exp = Mgmg.exp(smith, armor, comp)
			if exp < minex
				minex, ret = exp, [smith, armor, comp]
			elsif exp == minex
				if irep.para_call(para, *ret) < irep.para_call(para, smith, armor, comp)
					ret = [smith, armor, comp]
				end
			end
		rescue Mgmg::SearchCutException
		end
		raise Mgmg::SearchCutException, "the result exceeds given cut_exp=#{cut_exp}" if cut_exp < minex
		ret
	end
end

module Mgmg
	module_function def find_lowerbound(a, b, para, start, term, smith_min_a: nil, smith_min_b: nil, armor_min_a: nil, armor_min_b: nil, min_smith: false)
		if term <= start
			raise ArgumentError, "start < term is needed, (start, term) = (#{start}, #{term}) are given"
		end
		ira, irb = a.ir, b.ir
		sca, scb = a.search(para, start, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira), b.search(para, start, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		if eb < ea || ( ea == eb && ira.para_call(para, *sca) < irb.para_call(para, *scb) )
			a, b, ira, irb, sca, scb, ea, eb = b, a, irb, ira, scb, sca, eb, ea
			smith_min_a, smith_min_b, armor_min_a, armor_min_b = smith_min_b, smith_min_a, armor_min_b, armor_min_a
		end
		tag = ira.para_call(para, *sca) + 1
		sca, scb = a.search(para, term, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira), b.search(para, term, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		if ea < eb || ( ea == eb && irb.para_call(para, *scb) < ira.para_call(para, *sca) )
			raise Mgmg::SearchCutException
		end
		while tag < term
			sca, scb = a.search(para, tag, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira), b.search(para, tag, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
			ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
			pa, pb = ira.para_call(para, *sca), irb.para_call(para, *scb)
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
	
	module_function def find_upperbound(a, b, para, start, term, smith_min_a: nil, smith_min_b: nil, armor_min_a: nil, armor_min_b: nil, min_smith: false)
		if start <= term
			raise ArgumentError, "term < start is needed, (start, term) = (#{start}, #{term}) are given"
		end
		ira, irb = a.ir, b.ir
		sca, scb = a.search(para, start, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira), b.search(para, start, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		if ea < eb || ( ea == eb && irb.para_call(para, *scb) < ira.para_call(para, *sca) )
			a, b, ira, irb, sca, scb, ea, eb = b, a, irb, ira, scb, sca, eb, ea
			smith_min_a, smith_min_b, armor_min_a, armor_min_b = smith_min_b, smith_min_a, armor_min_b, armor_min_a
		end
		tagu = ira.para_call(para, *sca)
		sca[-1] -= 2
		tagl = ira.para_call(para, *sca)
		sca, scb = a.search(para, term, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira), b.search(para, term, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
		ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
		if eb < ea || ( ea == eb && ira.para_call(para, *sca) < irb.para_call(para, *scb) )
			raise Mgmg::SearchCutException
		end
		while term < tagu
			ret = nil
			sca = a.search(para, tagl, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira)
			next_tagu, next_sca = tagl, sca
			scb = b.search(para, tagl, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
			while tagl < tagu
				ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
				pa, pb = ira.para_call(para, *sca), irb.para_call(para, *scb)
				if ea < eb
					ret = tagl
					sca = a.search(para, pa + 1, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira)
					tagl = ira.para_call(para, *sca)
					scb = b.search(para, tagl, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
				elsif ea == eb
					if pb < pa
						ret = tagl
						sca = a.search(para, pa + 1, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira)
						tagl = ira.para_call(para, *sca)
						scb = b.search(para, tagl, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
					else
						scb = b.search(para, pb + 1, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
						tagl = irb.para_call(para, *scb)
						sca = a.search(para, tagl, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira)
					end
				else
					sca = a.search(para, pa + 1, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira)
					tagl = ira.para_call(para, *sca)
					scb = b.search(para, tagl, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb)
				end
			end
			if ret.nil?
				tagu = next_tagu
				next_sca[-1] -= 2
				tagl = ira.para_call(para, *next_sca)
				if tagl == tagu
					tagl = term
				end
			else
				pa = ira.para_call(para, *a.search(para, ret+1, smith_min_a, armor_min_a, min_smith: min_smith, irep: ira))
				pb = irb.para_call(para, *b.search(para, ret+1, smith_min_b, armor_min_b, min_smith: min_smith, irep: irb))
				return [ret, [pa, pb].min]
			end
		end
		raise UnexpectedError
	end
end
