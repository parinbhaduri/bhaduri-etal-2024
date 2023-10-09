#Compares risk shifting properties among variations in levee breach curve shape
include("../damage_realizations.jl")

#For parallel
include("../parallel_setup.jl")

seed_range = range(1000, 2000, step = 1)
flood_rps = range(10,1000, step = 10)
#Low
occ_low = risk_shift(Elevation, seed_range; breach = false, parallel = true, showprogress = true)
#medium
occ_med = risk_shift(Elevation, seed_range; breach_null = 0.3, parallel = true, showprogress = true)
#high
occ_high = risk_shift(Elevation, seed_range; breach_null = 0.5, parallel = true, showprogress = true)

#Join two dataframes and savefig
occ_low[!, "group"] .= "no breach"
occ_med[!, "group"] .= "stable"
occ_high[!, "group"] .= "vulnerable"


occ_breach = vcat(occ_low,occ_med,occ_high)

#Save/open dataframe
CSV.write("workflow/dataframes/occ_breach.csv", occ_breach)
#occ_breach = DataFrame(CSV.File("workflow/dataframes/occ_breach.csv"))


threshold = zeros(length(flood_rps))
#Plot results
breach_low = Plots.plot(flood_rps, occ_low.median, linecolor = colorant"#005F73", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10),  label = false)
Plots.plot!(flood_rps, occ_low.LB, fillrange=occ_low.RB, linecolor = colorant"#005F73", fillcolor = colorant"#005F73",
 fillalpha=0.35, alpha =0.35, label=false)
Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.title!("No Breaching")
#Plots.xlabel!("Return Period")
#Plots.ylabel!("Difference in Occupied-Exposure")

breach_med = Plots.plot(flood_rps, occ_med.median, linecolor = colorant"#CA6702", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10), label = false)
Plots.plot!(flood_rps, occ_med.LB, fillrange=occ_med.RB, linecolor = colorant"#CA6702", fillcolor = colorant"#CA6702",
 fillalpha=0.35, alpha =0.35, label=false)
 Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
#Plots.xlabel!("Return Period")
#Plots.ylabel!("Difference in Occupied-Exposure", fontsize = 45)
Plots.title!("Stable (Low Likelihood of Breaching)")

breach_high = Plots.plot(flood_rps, occ_high.median, linecolor = colorant"#9B2226", lw = 2.5, xscale = :log10,
 xticks = ([10,100,1000], string.([10,100,1000])), ytickfont = font(10), xtickfont = font(10), label = false)
Plots.plot!(flood_rps, occ_high.LB, fillrange=occ_high.RB, linecolor = colorant"#9B2226", fillcolor = colorant"#9B2226",
 fillalpha=0.35, alpha =0.35, label=false)
 Plots.plot!(flood_rps, threshold, line = :dash, linecolor = "black", lw = 2, label=false)
Plots.xlabel!("Return Period (Years)")
#Plots.ylabel!("Difference in Occupied-Exposure")
Plots.title!("Vulnerable (High Likelihood of Breaching)")


#Combined Plot
using Plots.PlotMeasures
breach_shape = Plots.plot(breach_low, breach_med, breach_high, layout = (1,3), top_margin = 10mm,  dpi = 300, size = (1500,250))

savefig(breach_shape, "figures/breach_shape_hor.svg")

#savefig(breach_med, "figures/breach_med.svg")