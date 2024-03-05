#For parallel
include("../parallel_setup.jl")

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#Low
occ_short = risk_shift(Elevation, seed_range; levee = 1/50, breach = false, parallel = true, showprogress = true)
#medium
occ_base = risk_shift(Elevation, seed_range; levee = 1/100, breach = false, parallel = true, showprogress = true)
#high
occ_tall = risk_shift(Elevation, seed_range; levee = 1/500, breach = false, parallel = true, showprogress = true)

#Join two dataframes and savefig
occ_short[!, "group"] .= "1/50"
occ_base[!, "group"] .= "1/100"
occ_tall[!, "group"] .= "1/500"


occ_height = vcat(occ_short,occ_base,occ_tall)

#Save/open dataframe
CSV.write("workflow/dataframes/occ_height.csv", occ_height)
#occ_breach = DataFrame(CSV.File("workflow/dataframes/occ_breach.csv"))


threshold = zeros(length(flood_rps))
#Plot results
breach_short = Plots.plot(flood_rps, occ_short.median, linecolor = "blue", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10),  label = false)
Plots.plot!(flood_rps, occ_short.LB, fillrange=occ_short.RB, linecolor = "blue", fillcolor = "blue",
 fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.title!("50 Yr Levee")
#Plots.xlabel!("Return Period")
#Plots.ylabel!("Difference in Occupied-Exposure")

breach_base = Plots.plot(flood_rps, occ_base.median, linecolor = "orange", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10), label = false)
Plots.plot!(flood_rps, occ_base.LB, fillrange=occ_base.RB, linecolor = "orange", fillcolor = "orange",
 fillalpha=0.35, alpha =0.35, label=false)
 Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
#Plots.xlabel!("Return Period")
#Plots.ylabel!("Difference in Occupied-Exposure", fontsize = 45)
Plots.title!("100 Yr Levee")

breach_tall = Plots.plot(flood_rps, occ_tall.median, linecolor = "green", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10), label = false)
Plots.plot!(flood_rps, occ_tall.LB, fillrange=occ_tall.RB, linecolor = "green", fillcolor = "green",
 fillalpha=0.35, alpha =0.35, label=false)
 Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
#Plots.xlabel!("Return Period (Years)")
#Plots.ylabel!("Difference in Occupied-Exposure")
Plots.title!("500 Yr Levee")


#Combined Plot
using Plots.PlotMeasures
breach_height = Plots.plot(breach_short, breach_base, breach_tall, layout = (3,1), left_margin = 10mm,  dpi = 300, size = (700,800))

savefig(breach_height, "figures/levee_height.svg")