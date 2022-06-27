module Mgmg
	module Optimize; end
	class << Optimize
		InvList = [%w|帽子 フード サンダル|.freeze, %w|宝1 骨1 木1 木2 骨2|.freeze, %w|宝1 骨1 木1|.freeze].freeze
		def phydef_optimize(str, smith, comp=smith, opt: Option.new)
			best = if smith.nil? then
				[str, str.poly(:phydef, opt:), str.poly(:magdef, opt:), str.poly(:cost, opt:)]
			else
				[str, str.build(smith, comp, opt:)]
			end
			str = Mgmg.check_string(str)
			ai = 0
			while str.sub!(/(帽子|フード|サンダル)\([宝木骨][12][宝木骨]1\)/){
				ai += 1
				"<A#{ai}>"
			}; end
			bi = 0
			while str.sub!(/[宝木骨]1\)/){
				bi += 1
				"<B#{bi}>)"
			}; end
			skin = false
			m = /([^\+]*\([^\(]+[綿皮]1\))\]*\Z/.match(str)
			if m
				if smith
					if m[1].sub(/綿1\)/, '皮1)').build(smith, opt:).weight == m[1].sub(/皮1\)/, '綿1)').build(smith, opt:).weight
						skin = true
					end
				else
					skin = true
				end
				str = str.sub(/皮(1\)\]*)\Z/) do
					"綿#{$1}"
				end
			end
			a = Array.new(ai){ [0, 0, 0] }
			b0 = Array.new(bi){ 0 }
			while a
				b = b0
				while b
					r = pd_apply_idx(str, a, b)
					best = if smith.nil? then
						pd_better(best, [r, r.poly(:phydef, opt:), r.poly(:magdef, opt:), r.poly(:cost, opt:)], opt.magdef_maximize)
					else
						pd_better(best, [r, r.build(smith, comp, opt:)], opt.magdef_maximize)
					end
					b = pd_next_b(b)
				end
				a = pd_next_a(a)
			end
			if skin
				str = str.sub(/綿(1\)\]*)\Z/) do
					"皮#{$1}"
				end
				a = Array.new(ai){ [0, 0, 0] }
				while a
					b = b0
					while b
						r = pd_apply_idx(str, a, b)
						best = if smith.nil? then
							pd_better(best, [r, r.poly(:phydef, opt:), r.poly(:magdef, opt:), r.poly(:cost, opt:)], opt.magdef_maximize)
						else
							pd_better(best, [r, r.build(smith, comp, opt:)], opt.magdef_maximize)
						end
						b = pd_next_b(b)
					end
					a = pd_next_a(a)
				end
			end
			best[0]
		end
		private def pd_better(pre, cur, mag)
			case pre.size
			when 2
				if pre[1].phydef < cur[1].phydef
					return cur
				elsif pre[1].phydef == cur[1].phydef
					if mag
						if pre[1].magdef < cur[1].magdef
							return cur
						elsif pre[1].magdef == cur[1].magdef
							if cur[1].total_cost.sum < pre[1].total_cost.sum
								return cur
							end
						end
					else
						if cur[1].comp_cost < pre[1].comp_cost
							return cur
						elsif cur[1].comp_cost == pre[1].comp_cost
							if cur[1].total_cost.sum < pre[1].total_cost.sum
								return cur
							end
						end
					end
				end
				return pre
			when 4
				if pre[1] < cur[1]
					return cur
				elsif pre[1] == cur[1]
					if mag
						if pre[2] < cur[2]
							return cur
						elsif pre[2] == cur[2]
							if cur[3] < pre[3]
								return cur
							end
						end
					else
						if cur[3] < pre[3]
							return cur
						end
					end
				end
				return pre
			else
				raise UnexpectedError
			end
		end
		private def pd_apply_idx(str, a, b)
			a.each.with_index do |aa, i|
				str = str.sub("<A#{i+1}>", "#{InvList[0][aa[0]]}(#{InvList[1][aa[1]]}#{InvList[2][aa[2]]})")
			end
			b.each.with_index do |bb, i|
				str = str.sub("<B#{i+1}>", InvList[2][bb])
			end
			str
		end
		private def pd_next_b_full(b)
			0.upto(b.length-1) do |i|
				b[i] += 1
				if b[i] == InvList[2].size
					b[i] = 0
				else
					return b
				end
			end
			nil
		end
		private def pd_next_b(b)
			if b[0] == 0
				return Array.new(b.length, 1)
			end
			nil
		end
		private def pd_next_a(a)
			0.upto(a.length-1) do |i|
				0.upto(2) do |j|
					a[i][j] += 1
					if a[i][j] == InvList[j].size
						a[i][j] = 0
					else
						return a
					end
				end
			end
			nil
		end
		
		MwList = %w|綿 皮 骨 木 水|.freeze
		def buster_optimize(str, smith, comp=smith, opt: Option.new)
			best = ( smith.nil? ? [str, str.poly(:mag_das, opt:)] : [str, str.build(smith, comp, opt:)] )
			str = Mgmg.check_string(str)
			ai = -1
			org = nil
			while str.sub!(/弓\(([骨水綿皮木][12][骨水綿皮木]1)\)/){
				ai += 1
				if ai == 0
					org = $1.dup
				end
				"弓(<A#{ai}>)"
			}; end
			str = str.sub(/<A0>/, org)
			a = Array.new(ai){ [0, 0, 0] }
			while a
				r = bus_apply_idx(str, a)
				best = bus_better(best, ( smith.nil? ? [r, r.poly(:mag_das, opt:)] : [r, r.build(smith, comp, opt:)] ))
				a = bus_next_a(a)
			end
			best[0]
		end
		private def bus_apply_idx(str, a)
			a.each.with_index do |aa, i|
				str = str.sub("<A#{i+1}>", "#{MwList[aa[0]]}#{aa[1]+1}#{MwList[aa[2]]}1")
			end
			str
		end
		private def bus_better(pre, cur)
			if pre[1].kind_of?(Mgmg::Equip)
				if pre[1].mag_das < cur[1].mag_das
					return cur
				elsif pre[1].mag_das == cur[1].mag_das
					if cur[1].total_cost.sum < pre[1].total_cost.sum
						return cur
					end
				end
				return pre
			else
				if pre[1] < cur[1]
					return cur
				end
				return pre
			end
		end
		private def bus_next_a(a)
			0.upto(a.length-1) do |i|
				[0, 2].each do |j|
					a[i][j] += 1
					if a[i][j] == 5
						a[i][j] = 0
					else
						return a
					end
				end
				a[i][1] += 1
				if a[i][1] == 2
					a[i][1] = 0
				else
					return a
				end
			end
			nil
		end
	end
end
