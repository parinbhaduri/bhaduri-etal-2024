#Compares risk shifting properties between low risk and high risk aversion populations
include("damage_realizations.jl")

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#high risk aversion
occ_high = risk_shift(Elevation, seed_range)
occ_low = risk_shift(Elevation, seed_range; risk_averse = 0.7)

#Join two dataframes and savefig
occ_high[!, "group"] .= "high"
occ_low[!, "group"] .= "low"

occ_averse = vcat(occ_high,occ_low)

#Save/open dataframe
#CSV.write("workflow/dataframes/occ_averse.csv", occ_averse)
occ_averse = DataFrame(CSV.File("workflow/dataframes/occ_averse.csv"))

#Plot results
Plots.plot(occ_averse[:, "return_period"], occ_averse.median, group = occ_averse.group, lw = 2.5, xscale = :log10, 
xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10))
Plots.plot!(occ_averse[:, "return_period"], occ_averse.LB, fillrange= occ_averse.RB, group = occ_averse.group,
 linecolor = ["blue" "orange"], fillcolor = ["blue" "orange"], fillalpha=0.35, alpha =0.35, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")