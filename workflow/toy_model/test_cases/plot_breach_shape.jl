### Compares risk shifting properties among variations in levee breach curve shape

## Read in dataframes
occ_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/breach_none.csv")))
occ_med = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/breach_base.csv")))
occ_high = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/breach_high.csv")))

threshold = zeros(length(flood_rps))
#Plot results
breach_low = Plots.plot(flood_rps, occ_low.median, linecolor = "blue", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10),  label = false)
Plots.plot!(flood_rps, occ_low.LB, fillrange=occ_low.RB, linecolor = "blue", fillcolor = "blue",
 fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.title!("No Breaching")
#Plots.xlabel!("Return Period")
#Plots.ylabel!("Difference in Occupied-Exposure")

breach_med = Plots.plot(flood_rps, occ_med.median, linecolor = "orange", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10), label = false)
Plots.plot!(flood_rps, occ_med.LB, fillrange=occ_med.RB, linecolor = "orange", fillcolor = "orange",
 fillalpha=0.35, alpha =0.35, label=false)
 Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
#Plots.xlabel!("Return Period")
#Plots.ylabel!("Difference in Occupied-Exposure", fontsize = 45)
Plots.title!("Stable (Low likelihood of breaching) ")

breach_high = Plots.plot(flood_rps, occ_high.median, linecolor = "green", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10), label = false)
Plots.plot!(flood_rps, occ_high.LB, fillrange=occ_high.RB, linecolor = "green", fillcolor = "green",
 fillalpha=0.35, alpha =0.35, label=false)
 Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
#Plots.xlabel!("Return Period (Years)")
#Plots.ylabel!("Difference in Occupied-Exposure")
Plots.title!("vulnerable (High Likelihood of breaching)")


#Combined Plot
using Plots.PlotMeasures
breach_shape = Plots.plot(breach_low, breach_med, breach_high, layout = (3,1), left_margin = 10mm,  dpi = 300, size = (700,800))

savefig(breach_shape, "figures/breach_shape.svg")

#savefig(breach_med, "figures/breach_med.svg")