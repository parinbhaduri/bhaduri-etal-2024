#Compares risk shifting properties among variations in levee breach curve shape
include("damage_realizations.jl")

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#Low
occ_low = risk_shift(Elevation, seed_range; breach_null = 0.3)
#medium
occ_med = risk_shift(Elevation, seed_range)
#high
occ_high = risk_shift(Elevation, seed_range; breach_null = 0.5)

threshold = zeros(length(flood_rps))
#Plot results
breach_low = Plots.plot(flood_rps, occ_low[1], linecolor = "blue", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10),  label = false)
Plots.plot!(flood_rps, occ_low[2][:,1], fillrange=occ_low[2][:,2], linecolor = "blue", fillcolor = "blue",
 fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
#Plots.xlabel!("Return Period")
#Plots.ylabel!("Difference in Occupied-Exposure")

breach_med = Plots.plot(flood_rps, occ_med[1], linecolor = "orange", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10), label = false)
Plots.plot!(flood_rps, occ_med[2][:,1], fillrange=occ_med[2][:,2], linecolor = "orange", fillcolor = "orange",
 fillalpha=0.35, alpha =0.35, label=false)
 Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
#Plots.xlabel!("Return Period")
Plots.ylabel!("Difference in Occupied-Exposure", fontsize = 45)

breach_high = Plots.plot(flood_rps, occ_high[1], linecolor = "green", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10), label = false)
Plots.plot!(flood_rps, occ_high[2][:,1], fillrange=occ_high[2][:,2], linecolor = "green", fillcolor = "green",
 fillalpha=0.35, alpha =0.35, label=false)
 Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period (Years)")
#Plots.ylabel!("Difference in Occupied-Exposure")


#Combined Plot
using Plots.PlotMeasures
breach_shape = Plots.plot(breach_low, breach_med, breach_high, layout = (3,1), left_margin = 10mm,  dpi = 300, size = (700,800))

savefig(breach_shape, "figures/breach_shape.svg")

#savefig(breach_med, "figures/breach_med.svg")