
#For parallel
include("../parallel_setup.jl")


#For serial
#include("../damage_realizations.jl")

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)

##Compares risk shifting properties between low risk and high risk aversion populations
#high risk aversion
occ_high = risk_shift(Elevation, seed_range; parallel = true, showprogress = true)
#low risk aversion
occ_low = risk_shift(Elevation, seed_range; risk_averse = 0.7, parallel = true, showprogress = true)

#Join two dataframes and savefig
occ_high[!, "group"] .= "high"
occ_low[!, "group"] .= "low"

occ_averse = vcat(occ_high,occ_low)

#Save/open dataframe
#CSV.write("workflow/dataframes/occ_averse.csv", occ_averse)
occ_averse = DataFrame(CSV.File("workflow/dataframes/occ_averse.csv"))


threshold = zeros(length(flood_rps))
#Plot results
breach_averse = Plots.plot(occ_averse[:, "return_period"], occ_averse.median, group = occ_averse.group, lw = 2.5, xscale = :log10, 
xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(occ_averse[:, "return_period"], occ_averse.LB, fillrange= occ_averse.RB, group = occ_averse.group,
 linecolor = ["blue" "orange"], fillcolor = ["blue" "orange"], fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")

savefig(breach_averse, "figures/breach_averse.svg")


## Calculate integral of risk shifting curves
occ_high_sum = risk_shift(Elevation, seed_range; metric = "integral")
occ_low_sum = risk_shift(Elevation, seed_range; risk_averse = 0.7, metric = "integral")



#Plot sums
using StatsPlots

Plots.boxplot([repeat(["high"],1001) repeat(["low"],1001)], [occ_high_sum' occ_low_sum'], legend = false)
Plots.ylims!(0.5,2.5)



