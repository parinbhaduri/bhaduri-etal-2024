#Compares risk shifting properties between low risk and high risk aversion populations
include("damage_realizations.jl")

seed_range = range(1,1, step = 1)

#high risk aversion
occ_high = risk_shift(Elevation, seed_range)

#Plot results
Plots.plot(flood_rps, occ_high[1], linecolor = "orange", lw = 2.5, xscale = :log10, label = false)
Plots.plot!(flood_rps, occ_high[2][:,1], fillrange=occ_high[2][:,2], linecolor = "orange", fillcolor = "orange",
 fillalpha=0.35, alpha =0.35, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")