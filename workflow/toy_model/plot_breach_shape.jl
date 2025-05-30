### Compares risk shifting properties among variations in levee breach curve shape in Idealized Experiment

#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using ColorSchemes
using FileIO

## Read in dataframes
occ_low = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/breach_none.csv")))
occ_med = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/breach_base.csv")))
occ_high = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/breach_high.csv")))

ret_per = range(10, 1000, length=100)
threshold = zeros(length(ret_per))

## Plot results
#Create backdrop
fig = Figure(size = (900,600), fontsize = 18, pt_per_unit = 1, figure_padding = 18)

ax1 = Axis(fig[1, 1:2], ylabel = "Difference in Occupied Exposure", xlabel = "Return Period (years)", xscale = log10,
 xticks = ([10,100,1000], string.([10,100,1000])), limits = ((10,1000), nothing), xgridvisible = false, titlealign = :center, title = "Comparing Flood Impact between Levee and No Levee Scenario")

ax2 = Axis(fig[2, 1], ylabel = "Difference in Occupied Exposure", xlabel = "Return Period (years)", xscale = log10,
 xticks = ([10,100,1000], string.([10,100,1000])), limits = ((10,1000), nothing), xgridvisible = false, titlealign = :center, title = "No Levee Breach Failure")

ax3 = Axis(fig[2, 2], xlabel = "Return Period (years)", xscale = log10,
 xticks = ([10,100,1000], string.([10,100,1000])), limits = ((10,1000), nothing), xgridvisible = false, titlealign = :center, title = "High Levee Breach Likelihood")

linkyaxes!(ax1, ax3)
#Create grid layout
#ga = f[1:2,1] = GridLayout()
#gbc = f[1:2,2] = GridLayout()
#gb = gbc[1,1] = GridLayout()
#gc = gbc[1,1] = GridLayout()

Palette = ColorSchemes.okabe_ito
#Panel A
CairoMakie.lines!(ax1, ret_per, occ_med.median, color = Palette[1], linewidth = 2.5)
#, label = false)

CairoMakie.band!(ax1, ret_per, occ_med.LB, occ_med.RB, color = (Palette[1], 0.35))

CairoMakie.lines!(ax1, ret_per, threshold, linestyle = :dash, color = "black", linewidth = 2)

#Plots.title!("Stable (Low likelihood of breaching) ")

#Panel B 
CairoMakie.lines!(ax2, ret_per, occ_low.median, color = Palette[3], linewidth = 2.5,)# xscale = :log10,

CairoMakie.band!(ax2, ret_per, occ_low.LB, occ_low.RB, color = (Palette[3], 0.35))

CairoMakie.lines!(ax2, ret_per, threshold, linestyle = :dash, color = "black", linewidth = 2)
#Plots.title!("No Breaching")


#Panel C
CairoMakie.lines!(ax3, ret_per, occ_high.median, color = Palette[6], linewidth = 2.5)

CairoMakie.band!(ax3, ret_per, occ_high.LB, occ_high.RB, color = (Palette[6], 0.35))

CairoMakie.lines!(ax3, ret_per, threshold, linestyle = :dash, color = "black", linewidth = 2)

#Plots.title!("vulnerable (High Likelihood of breaching)")

display(fig)

CairoMakie.save(joinpath(pwd(),"figures/risk_shift_breach.png"), fig)


##Additional Analysis 
RSI_low = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/breach_none_RSI.csv")))
println("For Overtopping Only :\n Minimum RSI -> $(minimum(RSI_low.RSI)),\n Maximum RSI -> $(maximum(RSI_low.RSI)),\n Median RSI -> $(median(RSI_low.RSI))")

RSI_base = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/breach_base_RSI.csv")))
println("For Base Breach:\n Minimum RSI -> $(minimum(RSI_base.RSI)),\n Maximum RSI -> $(maximum(RSI_base.RSI)),\n Median RSI -> $(median(RSI_base.RSI))")

RSI_high = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/breach_high_RSI.csv")))
println("For High Breach:\n Minimum RSI -> $(minimum(RSI_high.RSI)),\n Maximum RSI -> $(maximum(RSI_high.RSI)),\n Median RSI -> $(median(RSI_high.RSI))")