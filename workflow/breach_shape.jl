#Compares risk shifting properties among variations in levee breach curve shape
include("damage_realizations.jl")

seed_range = range(1,1, step = 1)
flood_rps = range(10,1000, step = 10)
#Low
occ_low = risk_shift(Elevation, seed_range; breach_null = 0.3)
#medium
occ_med = risk_shift(Elevation, seed_range)
#high
occ_high = risk_shift(Elevation, seed_range; breach_null = 0.5)

#Plot results
breach_low = Plots.plot(flood_rps, occ_low[1], linecolor = "blue", lw = 2.5, xscale = :log10, label = false)
Plots.plot!(flood_rps, occ_low[2][:,1], fillrange=occ_low[2][:,2], linecolor = "blue", fillcolor = "blue",
 fillalpha=0.35, alpha =0.35, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")

breach_med = Plots.plot(flood_rps, occ_med[1], linecolor = "orange", lw = 2.5, xscale = :log10, label = false)
Plots.plot!(flood_rps, occ_med[2][:,1], fillrange=occ_med[2][:,2], linecolor = "orange", fillcolor = "orange",
 fillalpha=0.35, alpha =0.35, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")

breach_high = Plots.plot(flood_rps, occ_high[1], linecolor = "green", lw = 2.5, xscale = :log10, label = false)
Plots.plot!(flood_rps, occ_high[2][:,1], fillrange=occ_high[2][:,2], linecolor = "green", fillcolor = "green",
 fillalpha=0.35, alpha =0.35, label=false)
Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure")

#Combined Plot