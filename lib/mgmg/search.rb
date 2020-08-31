class String
	def smith_search(para, target, comp, smith_min=nil, smith_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false)
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
		if target <= build(smith_min, comp, left_associative: left_associative).para_call(para)
			return smith_min
		elsif build(smith_max, comp, left_associative: left_associative).para_call(para) < target
			raise Mgmg::SearchCutException
		end
		while 1 < smith_max - smith_min do
			smith = (smith_max - smith_min).div(2) + smith_min
			if build(smith, comp, left_associative: left_associative).para_call(para) < target
				smith_min = smith
			else
				smith_max = smith
			end
		end
		smith_max
	end
	def comp_search(para, target, smith, comp_min=nil, comp_max=10000, left_associative: true)
		comp_min = min_comp(left_associative: left_associative)
		if comp_max < comp_min
			raise ArgumentError, "comp_min <= comp_max is needed, (comp_min, comp_max) = (#{comp_min}, #{comp_max}) are given"
		end
		if target <= build(smith, comp_min, left_associative: left_associative).para_call(para)
			return comp_min
		elsif build(smith, comp_max, left_associative: left_associative).para_call(para) < target
			raise Mgmg::SearchCutException
		end
		while 1 < comp_max - comp_min do
			comp = (comp_max - comp_min).div(2) + comp_min
			if build(smith, comp, left_associative: left_associative).para_call(para) < target
				comp_min = comp
			else
				comp_max = comp
			end
		end
		comp_max
	end
	def search(para, target, smith_min=nil, comp_min=nil, smith_max=10000, comp_max=10000, left_associative: true, step: 1, cut_exp: Float::INFINITY, min_smith: false)
		if smith_min.nil?
			if min_smith
				smith_min = self.min_smith
			else
				smith_min = build(-1, -1, left_associative: left_associative).min_level
			end
		end
		comp_min = min_comp(left_associative: left_associative) if comp_min.nil?
		comp_min = comp_search(para, target, smith_max, comp_min, comp_max, left_associative: left_associative)
		smith_max = smith_search(para, target, comp_min, smith_min, smith_max, left_associative: left_associative)
		smith_min = smith_search(para, target, comp_max, smith_min, smith_max, left_associative: left_associative)
		raise Mgmg::SearchCutException if cut_exp < Mgmg.exp(smith_min, comp_min)
		comp_max = comp_search(para, target, smith_min, comp_min, comp_max, left_associative: left_associative)
		minex, ret = Mgmg.exp(smith_min, comp_max), [smith_min, comp_max]
		exp = Mgmg.exp(smith_max, comp_min)
		minex, ret = exp, [smith_max, comp_min] if exp < minex
		(comp_min+step).step(comp_max-1, step) do |comp|
			break if minex < Mgmg.exp(smith_min, comp)
			smith = smith_search(para, target, comp, smith_min, smith_max, left_associative: left_associative, cut_exp: [minex, cut_exp].min)
			exp = Mgmg.exp(smith, comp)
			minex, ret = exp, [smith, comp] if exp < minex
		rescue Mgmg::SearchCutException
		end
		raise Mgmg::SearchCutException, "the result exceeds given cut_exp=#{cut_exp}" if cut_exp < minex
		ret
	end
end
module Enumerable
	def smith_search(para, target, armor, comp, smith_min=nil, smith_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false)
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
		if build(smith_max, armor, comp, left_associative: left_associative).para_call(para) < target
			raise Mgmg::SearchCutException
		elsif target <= build(smith_min, armor, comp, left_associative: left_associative).para_call(para)
			return smith_min
		end
		while 1 < smith_max - smith_min do
			smith = (smith_max - smith_min).div(2) + smith_min
			if build(smith, armor, comp, left_associative: left_associative).para_call(para) < target
				smith_min = smith
			else
				smith_max = smith
			end
		end
		smith_max
	end
	def armor_search(para, target, smith, comp, armor_min=nil, armor_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false)
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
		if build(smith, armor_max, comp, left_associative: left_associative).para_call(para) < target
			raise Mgmg::SearchCutException
		elsif target <= build(smith, armor_min, comp, left_associative: left_associative).para_call(para)
			return armor_min
		end
		while 1 < armor_max - armor_min do
			armor = (armor_max - armor_min).div(2) + armor_min
			if build(smith, armor, comp, left_associative: left_associative).para_call(para) < target
				armor_min = armor
			else
				armor_max = armor
			end
		end
		armor_max
	end
	def sa_search(para, target, comp, smith_min=nil, armor_min=nil, smith_max=10000, armor_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false)
		if min_smith
			s, a = self.min_smith
		else
			s, a = build(-1, -1, -1, left_associative: left_associative).min_level
		end
		smith_min = s if smith_min.nil?
		armor_min = a if armor_min.nil?
		smith_min = smith_search(para, target, armor_max, comp, smith_min, smith_max, left_associative: true)
		armor_min = armor_search(para, target, smith_max, comp, armor_min, armor_max, left_associative: true)
		raise Mgmg::SearchCutException if cut_exp < Mgmg.exp(smith_min, armor_min, comp)
		smith_max = smith_search(para, target, armor_min, comp, smith_min, smith_max, left_associative: true)
		armor_max = armor_search(para, target, smith_min, comp, armor_min, armor_max, left_associative: true)
		minex, ret = Mgmg.exp(smith_min, armor_max, comp), [smith_min, armor_max]
		exp = Mgmg.exp(smith_max, armor_min, comp)
		if exp < minex
			minex, ret = exp, [smith_max, armor_min]
			(armor_min+1).upto(armor_max-1) do |armor|
				break if minex < Mgmg.exp(smith_min, armor, comp)
				smith = smith_search(para, target, armor, comp, smith_min, smith_max, left_associative: left_associative, cut_exp: [minex, cut_exp].min)
				exp = Mgmg.exp(smith, armor, comp)
				minex, ret = exp, [smith, armor] if exp < minex
			rescue Mgmg::SearchCutException
			end
		else
			(smith_min+1).upto(smith_max-1) do |smith|
				break if minex < Mgmg.exp(smith, armor_min, comp)
				armor = armor_search(para, target, smith, comp, armor_min, armor_max, left_associative: left_associative, cut_exp: [minex, cut_exp].min)
				exp = Mgmg.exp(smith, armor, comp)
				minex, ret = exp, [smith, armor] if exp < minex
			rescue Mgmg::SearchCutException
			end
		end
		raise Mgmg::SearchCutException if cut_exp < minex
		ret
	end
	def comp_search(para, target, smith, armor, comp_min=nil, comp_max=10000, left_associative: true)
		comp_min = min_comp(left_associative: left_associative)
		if comp_max < comp_min
			raise ArgumentError, "comp_min <= comp_max is needed, (comp_min, comp_max) = (#{comp_min}, #{comp_max}) are given"
		end
		if target <= build(smith, armor, comp_min, left_associative: left_associative).para_call(para)
			return comp_min
		elsif build(smith, comp_max, left_associative: left_associative).para_call(para) < target
			raise ArgumentError, "given comp_max=#{comp_max} does not satisfies the target"
		end
		while 1 < comp_max - comp_min do
			comp = (comp_max - comp_min).div(2) + comp_min
			if build(smith, armor, comp, left_associative: left_associative).para_call(para) < target
				comp_min = comp
			else
				comp_max = comp
			end
		end
		comp_max
	end
	def search(para, target, smith_min=nil, armor_min=nil, comp_min=nil, smith_max=10000, armor_max=10000, comp_max=10000, left_associative: true, cut_exp: Float::INFINITY, min_smith: false)
		if min_smith
			s, a = self.min_smith
		else
			s, a = build(-1, -1, -1, left_associative: left_associative).min_level
		end
		smith_min = s if smith_min.nil?
		armor_min = a if armor_min.nil?
		comp_min = min_comp(left_associative: left_associative) if comp_min.nil?
		comp_min = comp_search(para, target, smith_max, armor_max, comp_min, comp_max, left_associative: left_associative)
		smith_max, armor_max = sa_search(para, target, comp_min, smith_min, armor_min, smith_max, armor_max, left_associative: left_associative)
		smith_min, armor_min = sa_search(para, target, comp_max, smith_min, armor_min, smith_max, armor_max, left_associative: left_associative)
		raise Mgmg::SearchCutException if cut_exp < Mgmg.exp(smith_min, armor_min, comp_min)
		comp_max = comp_search(para, target, smith_min, armor_min, comp_min, comp_max, left_associative: left_associative)
		minex, ret = Mgmg.exp(smith_min, armor_min, comp_max), [smith_min, armor_min, comp_max]
		exp = Mgmg.exp(smith_max, armor_max, comp_min)
		minex, ret = exp, [smith_max, armor_max, comp_min] if exp < minex
		(comp_min+1).upto(comp_max-1) do |comp|
			break if minex < Mgmg.exp(smith_min, armor_min, comp)
			smith, armor = sa_search(para, target, comp, smith_min, armor_min, smith_max, armor_max, left_associative: left_associative, cut_exp: [minex, cut_exp].min)
			exp = Mgmg.exp(smith, armor, comp)
			minex, ret = exp, [smith, armor, comp] if exp < minex
		rescue Mgmg::SearchCutException
		end
		raise Mgmg::SearchCutException, "the result exceeds given cut_exp=#{cut_exp}" if cut_exp < minex
		ret
	end
end
