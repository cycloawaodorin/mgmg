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
			raise Mgmg::SearchCutException, "given comp_max=#{opt.comp_max} does not satisfies the target"
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
	private def eval_comp(para, target, comp, opt, eo)
		return [nil, Float::INFINITY] if (comp < opt.comp_min or opt.comp_max < comp)
		comp -= 1 if ( opt.comp_min<comp  and eo & (2**(comp&1)) == 0 )
		smith = smith_search(para, target, comp, opt:)
		exp = Mgmg.exp(smith, comp)
		[[smith, comp], exp]
	rescue Mgmg::SearchCutException
		[nil, Float::INFINITY]
	end
	private def fine(exp_best, ret, para, target, comp, opt, eo)
		return [exp_best, ret] if eo & (2**(comp&1)) == 0
		smith = smith_search(para, target, comp, opt:)
		exp = Mgmg.exp(smith, comp)
		if exp < exp_best
			exp_best, ret = exp, [smith, comp]
		elsif exp == exp_best
			if ret.nil? or opt.irep.para_call(para, *ret) < opt.irep.para_call(para, smith, comp) then
				ret = [smith, comp]
			end
		end
		[exp_best, ret]
	end
	def search(para, target, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		opt_nocut = opt.dup; opt_nocut.cut_exp = Float::INFINITY
		begin
			opt.comp_min = comp_search(para, target, opt.smith_max, opt:)
		rescue Mgmg::SearchCutException
			foo = opt.irep.para_call(para, opt.smith_max, opt.comp_max)
			raise Mgmg::SearchCutException, "#{self} could not reach target=#{target} until (smith_max, comp_max)=(#{opt.smith_max}, #{opt.comp_max}), which yields #{foo.comma3}"
		end
		opt.smith_max = smith_search(para, target, opt.comp_min, opt: opt_nocut)
		opt.smith_min = smith_search(para, target, opt.comp_max, opt: opt_nocut)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.comp_min)
		opt.comp_max = comp_search(para, target, opt.smith_min, opt:)
		ret = nil
		exp = Mgmg.exp(opt.smith_min, opt.comp_max)
		opt.cut_exp, ret = exp, [opt.smith_min, opt.comp_max] if exp <= opt.cut_exp
		exp = Mgmg.exp(opt.smith_max, opt.comp_min)
		opt.cut_exp, ret = exp, [opt.smith_max, opt.comp_min] if ( exp < opt.cut_exp || (ret.nil? && exp==opt.cut_exp) )
		eo = opt.irep.eo_para(para)
		comps = Mgmg.fib_init(opt.comp_min, opt.comp_max)
		values = comps.map do |comp|
			r, e = eval_comp(para, target, comp, opt_nocut, eo)
			opt.cut_exp, ret = e, r if e < opt.cut_exp
			e
		end
		while 3 < comps[3]-comps[0]
			if values[1] <= values[2]
				comp = comps[0] + comps[2]-comps[1]
				comps = [comps[0], comp, comps[1], comps[2]]
				r, e = eval_comp(para, target, comp, opt_nocut, eo)
				opt.cut_exp, ret = e, r if e < opt.cut_exp
				values = [values[0], e, values[1], values[2]]
			else
				comp = comps[1] + comps[3]-comps[2]
				comps = [comps[1], comps[2], comp, comps[3]]
				r, e = eval_comp(para, target, comp, opt_nocut, eo)
				opt.cut_exp, ret = e, r if e < opt.cut_exp
				values = [values[1], values[2], e, values[3]]
			end
		end
		exp_best = opt.cut_exp
		diff = values.max-values.min
		if 0 < diff
			opt.cut_exp = exp_best + diff*opt.fib_ext[0]
			(comps[0]-1).downto(opt.comp_min) do |comp|
				exp_best, ret = fine(exp_best, ret, para, target, comp, opt, eo)
			rescue Mgmg::SearchCutException
				break
			end
			(comps[3]+1).upto(opt.comp_max) do |comp|
				exp_best, ret = fine(exp_best, ret, para, target, comp, opt, eo)
			rescue Mgmg::SearchCutException
				break
			end
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
	private def eval_comp_fm(para, comp, eo, opt, max, max_exp)
		return [-Float::INFINITY, Float::INFINITY] if (comp < opt.comp_min or opt.comp_max < comp)
		comp -= 1 if ( opt.comp_min<comp and ( eo & (2**(comp&1)) == 0 ) )
		smith = Mgmg.invexp2(max_exp, comp)
		cur = opt.irep.para_call(para, smith, comp)
		smith = minimize_smith(para, smith, comp, cur, opt) if max <= cur
		[cur, smith]
	end
	def find_max(para, max_exp, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		exp = Mgmg.exp(opt.smith_min, opt.comp_min)
		raise Mgmg::SearchCutException, "the recipe requires #{exp.comma3} experiment points, which exceeds given max_exp=#{max_exp.comma3}" if max_exp < exp
		ret = [Mgmg.invexp2(max_exp, opt.comp_min), opt.comp_min]
		max = opt.irep.para_call(para, *ret)
		eo = opt.irep.eo_para(para)
		opt.comp_max = Mgmg.invexp2c(max_exp, opt.smith_min)
		comps = Mgmg.fib_init(opt.comp_min+1, opt.comp_max)
		values = comps.map do |comp|
			cur, smith = eval_comp_fm(para, comp, eo, opt, max, max_exp)
			ret, max = [smith, comp], cur if ( max < cur || ( max == cur && Mgmg.exp(smith, comp) < Mgmg.exp(*ret) ) )
			cur
		end
		while 3 < comps[3]-comps[0]
			if values[2] <= values[1]
				comp = comps[0] + comps[2]-comps[1]
				comps = [comps[0], comp, comps[1], comps[2]]
				cur, smith = eval_comp_fm(para, comp, eo, opt, max, max_exp)
				ret, max = [smith, comp], cur if ( max < cur || ( max == cur && Mgmg.exp(smith, comp) < Mgmg.exp(*ret) ) )
				values = [values[0], cur, values[1], values[2]]
			else
				comp = comps[1] + comps[3]-comps[2]
				comps = [comps[1], comps[2], comp, comps[3]]
				cur, smith = eval_comp_fm(para, comp, eo, opt, max, max_exp)
				ret, max = [smith, comp], cur if ( max < cur || ( max == cur && Mgmg.exp(smith, comp) < Mgmg.exp(*ret) ) )
				values = [values[1], values[2], cur, values[3]]
			end
		end
		diff = values.max-values.min
		if 0 < diff
			th = max - diff*opt.fib_ext[1]
			(comps[0]-1).downto(opt.comp_min) do |comp|
				next if ( eo & (2**(comp&1)) == 0 )
				cur, smith = eval_comp_fm(para, comp, eo, opt, max, max_exp)
				ret, max = [smith, comp], cur if ( max < cur || ( max == cur && Mgmg.exp(smith, comp) < Mgmg.exp(*ret) ) )
				break if cur < th
			end
			(comps[3]+1).upto(opt.comp_max) do |comp|
				next if ( eo & (2**(comp&1)) == 0 )
				cur, smith = eval_comp_fm(para, comp, eo, opt, max, max_exp)
				ret, max = [smith, comp], cur if ( max < cur || ( max == cur && Mgmg.exp(smith, comp) < Mgmg.exp(*ret) ) )
				break if cur < th
			end
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
			raise Mgmg::SearchCutException, "given comp_max=#{opt.comp_max} does not satisfies the target"
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
	private def eval_comp_sa(para, target, comp, opt, eo)
		return [nil, Float::INFINITY] if (comp < opt.comp_min or opt.comp_max < comp)
		comp -= 1 if ( opt.comp_min<comp  and eo & (2**(comp&1)) == 0 )
		sa = sa_search(para, target, comp, opt:)
		exp = Mgmg.exp(*sa, comp)
		[[*sa, comp], exp]
	rescue Mgmg::SearchCutException
		[nil, Float::INFINITY]
	end
	private def fine_sa(exp_best, ret, para, target, comp, opt, eo)
		return [exp_best, ret] if eo & (2**(comp&1)) == 0
		sa = sa_search(para, target, comp, opt:)
		exp = Mgmg.exp(*sa, comp)
		if exp < exp_best
			exp_best, ret = exp, [*sa, comp]
		elsif exp == exp_best
			if ret.nil? or opt.irep.para_call(para, *ret) < opt.irep.para_call(para, *sa, comp) then
				ret = [*sa, comp]
			end
		end
		[exp_best, ret]
	end
	def search(para, target, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		begin
			opt.comp_min = comp_search(para, target, opt.smith_max, opt.armor_max, opt:)
		rescue Mgmg::SearchCutException
			foo = opt.irep.para_call(para, opt.smith_max, opt.armor_max, opt.comp_max)
			raise Mgmg::SearchCutException, "#{self} could not reach target=#{target} until (smith_max, armor_max, comp_max)=(#{opt.smith_max}, #{opt.armor_max}, #{opt.comp_max}), which yields #{foo.comma3}"
		end
		opt_nocut = opt.dup; opt_nocut.cut_exp = Float::INFINITY
		opt.smith_max = ( smith_search(para, target, opt.armor_min, opt.comp_min, opt: opt_nocut) rescue opt.smith_max )
		opt.armor_max = ( armor_search(para, target, opt.smith_min, opt.comp_min, opt: opt_nocut) rescue opt.armor_max )
		opt.smith_min = smith_search(para, target, opt.armor_max, opt.comp_max, opt: opt_nocut)
		opt.armor_min = armor_search(para, target, opt.smith_max, opt.comp_max, opt: opt_nocut)
		raise Mgmg::SearchCutException if opt.cut_exp < Mgmg.exp(opt.smith_min, opt.armor_min, opt.comp_min)
		opt.comp_max = ( comp_search(para, target, opt.smith_min, opt.armor_min, opt:) rescue opt.comp_max )
		exp = Mgmg.exp(opt.smith_min, opt.armor_min, opt.comp_max)
		opt.cut_exp, ret = exp, [opt.smith_min, opt.armor_min,opt. comp_max] if exp <= opt.cut_exp
		eo = opt.irep.eo_para(para)
		comps = Mgmg.fib_init(opt.comp_min, opt.comp_max)
		values = comps.map do |comp|
			r, e = eval_comp_sa(para, target, comp, opt_nocut, eo)
			opt.cut_exp, ret = e, r if e < opt.cut_exp
			e
		end
		while 3 < comps[3]-comps[0]
			if values[1] <= values[2]
				comp = comps[0] + comps[2]-comps[1]
				comps = [comps[0], comp, comps[1], comps[2]]
				r, e = eval_comp_sa(para, target, comp, opt_nocut, eo)
				opt.cut_exp, ret = e, r if e < opt.cut_exp
				values = [values[0], e, values[1], values[2]]
			else
				comp = comps[1] + comps[3]-comps[2]
				comps = [comps[1], comps[2], comp, comps[3]]
				r, e = eval_comp_sa(para, target, comp, opt_nocut, eo)
				opt.cut_exp, ret = e, r if e < opt.cut_exp
				values = [values[1], values[2], e, values[3]]
			end
		end
		exp_best = opt.cut_exp
		diff = values.max-values.min
		if 0 < diff
			opt.cut_exp = exp_best + diff*opt.fib_ext[0]
			(comps[0]-1).downto(opt.comp_min) do |comp|
				exp_best, ret = fine_sa(exp_best, ret, para, target, comp, opt, eo)
			rescue Mgmg::SearchCutException
				break
			end
			(comps[3]+1).upto(opt.comp_max) do |comp|
				exp_best, ret = fine_sa(exp_best, ret, para, target, comp, opt, eo)
			rescue Mgmg::SearchCutException
				break
			end
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
	private def eval_arm(para, armor, comp, eo, opt, ret, max, max_exp)
		smith = Mgmg.invexp3(max_exp, armor, comp)
		exp = Mgmg.exp(smith, armor, comp)
		return [-Float::INFINITY, ret, max] if max_exp < exp
		cur = opt.irep.para_call(para, smith, armor, comp)
		smith = minimize_smith(para, smith, armor, comp, cur, opt) if max <= cur
		ret, max = [smith, armor, comp], cur if ( max < cur || ( max == cur && exp < Mgmg.exp(*ret) ) )
		[cur, ret, max]
	end
	private def eval_comp_fm(para, comp, eo, opt, ret, max, max_exp)
		return [-Float::INFINITY, ret, max] if (comp < opt.comp_min or opt.comp_max < comp)
		comp -= 1 if ( opt.comp_min<comp and ( eo & (2**(comp&1)) == 0 ) )
		cur = -Float::INFINITY
		a_max = [opt.armor_max, Mgmg.invexp3(max_exp, opt.smith_min, comp)].min
		arms = Mgmg.fib_init(opt.armor_min, a_max)
		a_vals = arms.map do |armor|
			cur_i, ret, max = eval_arm(para, armor, comp, eo, opt, ret, max, max_exp)
			cur_i
		end
		while 3 < arms[3]-arms[0]
			if a_vals[2] <= a_vals[1]
				armor = arms[0] + arms[2]-arms[1]
				arms = [arms[0], armor, arms[1], arms[2]]
				cur_i, ret, max = eval_arm(para, armor, comp, eo, opt, ret, max, max_exp)
				a_vals = [a_vals[0], cur_i, a_vals[1], a_vals[2]]
				cur = cur_i if cur < cur_i
			else
				armor = arms[1] + arms[3]-arms[2]
				arms = [arms[1], arms[2], armor, arms[3]]
				cur_i, ret, max = eval_arm(para, armor, comp, eo, opt, ret, max, max_exp)
				a_vals = [a_vals[1], a_vals[2], cur_i, a_vals[3]]
				cur = cur_i if cur < cur_i
			end
		end
		diff = a_vals.max-a_vals.min
		if 0 < diff
			th = max - diff*opt.fib_ext[1]
			(arms[0]-1).downto(opt.armor_min) do |armor|
				cur_i, ret, max = eval_arm(para, armor, comp, eo, opt, ret, max, max_exp)
				break if cur_i < th
				cur = cur_i if cur < cur_i
			end
			(arms[3]+1).upto(a_max) do |armor|
				cur_i, ret, max = eval_arm(para, armor, comp, eo, opt, ret, max, max_exp)
				break if cur_i < th
				cur = cur_i if cur < cur_i
			end
		end
		[cur, ret, max]
	end
	def find_max(para, max_exp, opt: Mgmg::Option.new)
		opt = opt.dup.set_default(self)
		exp = Mgmg.exp(opt.smith_min, opt.armor_min, opt.comp_min)
		raise Mgmg::SearchCutException, "the recipe requires #{exp.comma3} experiment points, which exceeds given max_exp=#{max_exp.comma3}" if max_exp < exp
		ret = [Mgmg.invexp3(max_exp, opt.armor_min, opt.comp_min), opt.armor_min, opt.comp_min]
		max = opt.irep.para_call(para, *ret)
		eo = opt.irep.eo_para(para)
		opt.comp_max = [opt.comp_max, Mgmg.invexp3c(max_exp, opt.smith_min, opt.armor_min)].min
		comps = Mgmg.fib_init(opt.comp_min, opt.comp_max)
		values = comps.map do |comp|
			cur, ret, max = eval_comp_fm(para, comp, eo, opt, ret, max, max_exp)
			cur
		end
		while 3 < comps[3]-comps[0]
			if values[2] <= values[1]
				comp = comps[0] + comps[2]-comps[1]
				comps = [comps[0], comp, comps[1], comps[2]]
				cur, ret, max = eval_comp_fm(para, comp, eo, opt, ret, max, max_exp)
				values = [values[0], cur, values[1], values[2]]
			else
				comp = comps[1] + comps[3]-comps[2]
				comps = [comps[1], comps[2], comp, comps[3]]
				cur, ret, max = eval_comp_fm(para, comp, eo, opt, ret, max, max_exp)
				values = [values[1], values[2], cur, values[3]]
			end
		end
		diff = values.max-values.min
		if 0 < diff
			th = max - diff*opt.fib_ext[1]
			(comps[0]-1).downto(opt.comp_min) do |comp|
				next if ( eo & (2**(comp&1)) == 0 )
				cur, ret, max = eval_comp_fm(para, comp, eo, opt, ret, max, max_exp)
				break if cur < th
			end
			(comps[3]+1).upto(opt.comp_max) do |comp|
				next if ( eo & (2**(comp&1)) == 0 )
				cur, ret, max = eval_comp_fm(para, comp, eo, opt, ret, max, max_exp)
				break if cur < th
			end
		end
		ret
	end
end

class << Mgmg
	def fib_init(min, max)
		z = min-1
		a, b = 2, 3
		while z + b < max do
			a, b = b, a+b
		end
		[z, z+b-a, z+a, z+b]
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
		elsif eb == ea && pa == pb
			raise Mgmg::SearchCutException, "given recipes are equivalent at start target=#{start.comma3}"
		end
		scat, scbt = a.search(para, term, opt: opt_a), b.search(para, term, opt: opt_b)
		eat, ebt = Mgmg.exp(*scat), Mgmg.exp(*scbt)
		if eat < ebt || ( eat == ebt && opt_b.irep.para_call(para, *scbt) <= opt_a.irep.para_call(para, *scat) )
			raise Mgmg::SearchCutException, "given recipes will never be reversed from start target=#{start.comma3} until term target=#{term.comma3}"
		end
		
		loop do
			loop do
				foo = a.find_max(para, eb, opt: opt_a)
				break if sca == foo
				bar = opt_a.irep.para_call(para, *foo)
				break if bar < pa
				sca, pa = foo, bar
				scb = b.search(para, pa, opt: opt_b)
				foo = Mgmg.exp(*scb)
				break if eb == foo
				eb = foo
			end
			ea = Mgmg.exp(*sca)
			if (eb <= ea and pa <= pb and (eb+pa)!=(ea+pb)) or (eb < ea and sca == a.search(para, pb, opt: opt_a)) then
				until ea < eb || ( ea == eb && pb < pa )
					sca = a.find_max(para, ea-1, opt: opt_a)
					ea, pa = Mgmg.exp(*sca), opt_a.irep.para_call(para, *sca)
				end
				return [pa, pb]
			end
			tag = pa + Eighth
			raise Mgmg::SearchCutException, "given recipes are never reversed from start target=#{start.comma3} until term target=#{term.comma3}" if term < tag
			sca, scb = a.search(para, tag, opt: opt_a), b.search(para, tag, opt: opt_b)
			ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
			pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
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
		elsif eb == ea && pa == pb
			raise Mgmg::SearchCutException, "given recipes are equivalent at start target=#{start.comma3}"
		end
		
		loop do
			loop do
				foo = a.find_max(para, eb, opt: opt_a)
				break if sca == foo
				bar = opt_a.irep.para_call(para, *foo)
				break if pa < bar
				sca, pa = foo, bar
				scb = b.search(para, pa, opt: opt_b)
				foo = Mgmg.exp(*scb)
				break if eb == foo
				eb = foo
			end
			ea = Mgmg.exp(*sca)
			pb = opt_b.irep.para_call(para, *scb)
			if ea <= eb and pb <= pa and (ea+pb)!=(eb+pa) then
				until pa < pb
					scb = b.search(para, pb+Eighth, opt: opt_b)
					pb = opt_b.irep.para_call(para, *scb)
				end
				return [pa, pb]
			elsif ea < eb
				return [pa, pb] if scb == b.search(para, pa, opt: opt_b)
			end
			tag = [ea, eb].min - 1
			begin
				scb = b.find_max(para, tag, opt: opt_b)
			rescue Mgmg::SearchCutException
				eb, pb = Mgmg.exp(*scb), opt_b.irep.para_call(para, *scb)
				begin
					sca = a.find_max(para, eb, opt: opt_a)
					ea, pa = Mgmg.exp(*sca), opt_a.irep.para_call(para, *sca)
					while eb <= ea
						sca = a.find_max(para, ea-1, opt: opt_a)
						ea, pa = Mgmg.exp(*sca), opt_a.irep.para_call(para, *sca)
					end
				rescue Mgmg::SearchCutException
					raise Mgmg::SearchCutException, "given recipes are never reversed from the start target=#{start.comma3} until #{pa.comma3}"
				end
				return [pa, pb]
			end
			begin
				sca = a.find_max(para, tag, opt: opt_a)
			rescue Mgmg::SearchCutException
				raise Mgmg::SearchCutException, "given recipes are never reversed from the start target=#{start.comma3} until #{opt_a.irep.para_call(para, *sca).comma3}"
			end
			ea, eb = Mgmg.exp(*sca), Mgmg.exp(*scb)
			pa, pb = opt_a.irep.para_call(para, *sca), opt_b.irep.para_call(para, *scb)
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
	
	class ELItem
		def initialize(recipe=nil, sc=nil)
			if recipe.nil?
				@para = -Float::INFINITY
				@exp = Float::INFINITY
			else
				@recipe = recipe
				if sc.size == 3
					@smith, @armor, @comp = *sc
				else
					if recipe.option.irep.kind < 8
						@smith, @comp = *sc
						@armor = -1
					else
						@armor, @comp = *sc
						@smith = -1
					end
				end
				@para = recipe.para_call(*sc)
				@exp = Mgmg.exp(*sc)
				@name = recipe.name
			end
		end
		attr_reader :recipe, :smith, :armor, :comp, :para, :exp, :name
		%i|attack phydef magdef hp mp str dex speed magic atkstr atk_sd dex_as mag_das magic2 magmag pmdef hs|.each do |sym|
			define_method(sym) do
				@recipe.para_call(@smith, @armor, @comp, para: sym)
			end
		end
		def weight
			@recipe.build(@smith, @armor, @comp).weight
		end
	end
	private_module_function def _el_sub(f, recipes, start, term, params, header, separator)
		tag, ret = start, []
		f.puts params.join(separator) if header && !f.nil?
		while tag < term
			best = ELItem.new()
			recipes.each do |r|
				cur = ELItem.new(r, r.search(tag))
				if cur.exp < best.exp
					best = cur
				elsif cur.exp == best.exp
					if best.para < cur.para
						best = cur
					elsif best.para == cur.para
						if block_given?
							best = cur if yield(best, cur)
						end
					end
				end
			end
			f.puts( params.map do |sym|
				best.method(sym).call
			end.join(separator) ) unless f.nil?
			ret << best.recipe unless ret.include?(best.recipe)
			tag = best.para+Eighth
		end
		ret
	end
	module_function def efficient_list(recipes, start, term, out=nil, params=[:defaults], separator: ',', header: true, **kw)
		i = params.index(:defaults)
		if i
			params[i] = [:smith, :armor, :comp, :exp, :para, :name]
			params.flatten!
		end
		ret = nil
		if out.kind_of?(String)
			File.open(out, 'w', **kw) do |f|
				ret = _el_sub(f, recipes, start, term, params, header, separator)
			end
		else
			ret = _el_sub(nil, recipes, start, term, params, header, separator)
		end
		ret
	end
end
