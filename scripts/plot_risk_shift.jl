#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CHANCE_C
using StatsBase
using Statistics
using CairoMakie
using ColorSchemes
using FileIO

## Read in dataframes for Idealized Experiment
occ_med = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/dataframes/breach_base.csv")))
occ_med_RA_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/toy_model/dataframes/breach_base_RA_low.csv")))


## Read in dataframes for Baltimore Experiment. Calculate Risk Shifting 
base_dam = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/levee_event_damage.csv")))

base_dam_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/base_event_low_RA.csv")))
levee_dam_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"workflow/CHANCE_C/dataframes/levee_event_low_RA.csv")))


#Calculate Median and 95% Uncertainty Interval
diff_dam = Matrix(levee_dam) .- Matrix(base_dam) 

diff_med = vec(mapslices(x -> median(x), diff_dam, dims=2))

diff_UI = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam, dims=2)
diff_LB = diff_UI[:,1]
diff_UB = diff_UI[:,2]

#Calculate Median and 95% Uncertainty Interval for low RA Scenario
diff_dam_low = Matrix(levee_dam_low) .- Matrix(base_dam_low) 

diff_med_low = vec(mapslices(x -> median(x), diff_dam_low, dims=2))

diff_UI_low = mapslices(x -> quantile(x, [0.025, 0.975]), diff_dam_low, dims=2)
diff_LB_low = diff_UI_low[:,1]
diff_UB_low = diff_UI_low[:,2]




#Idealized
ret_per = range(10, 1000, length=100)
thresh_ideal = zeros(length(ret_per))
#Baltimore
event_size = collect(range(0.75, 4.0, step = 0.25))
thresh_balt = zeros(length(event_size))


## Plot results
#Create backdrop
fig = Figure(size = (700,800), fontsize = 16, pt_per_unit = 1, figure_padding = 18)

ax1 = Axis(fig[1, 1:2], ylabel = rich("Difference in\n Occupied Exposure";font=:bold), xlabel = rich("Return Period (years)";font=:bold), xscale = log10,
titlesize = 18, xticks = ([10,100,1000], string.([10,100,1000])), limits = ((10,1000), nothing), xgridvisible = false, titlealign = :left, title = "a. Idealized Experiment")

ax2 = Axis(fig[2, 1:2], ylabel = rich("Difference in Loss\n (\$ Thousands)";font=:bold),
 xlabel = rich("Surge Event (m)";font=:bold), titlesize = 18, yticks = ([-2e4, 0, 2e4, 4e4], ["-20","0","20","40"]), limits = ((0.75,4), nothing),
 xgridvisible = false, titlealign = :left, title = "b. Baltimore Experiment")


Palette = ColorSchemes.okabe_ito
##Panel A
CairoMakie.lines!(ax1, ret_per, occ_med.median, color = Palette[1], linewidth = 3.5)
#, label = false)
CairoMakie.band!(ax1, ret_per, occ_med.LB, occ_med.RB, color = (Palette[1], 0.35))

CairoMakie.lines!(ax1, ret_per, occ_med_RA_low.median, color = Palette[2], linewidth = 3.5)
#, label = false)
CairoMakie.band!(ax1, ret_per, occ_med_RA_low.LB, occ_med_RA_low.RB, color = (Palette[2], 0.35))

CairoMakie.lines!(ax1, ret_per, thresh_ideal, linestyle = :dash, color = "black", linewidth = 2)
#Add Floodwall Height
CairoMakie.vlines!(ax1, 100, color = Palette[3], linewidth = 2.5)


##Panel B
CairoMakie.lines!(ax2, event_size, diff_med_low, color = Palette[2], linewidth = 3.5)
 #, label = false)
CairoMakie.band!(ax2, event_size, diff_LB_low, diff_UB_low, color = (Palette[2], 0.35))


CairoMakie.lines!(ax2, event_size, diff_med, color = Palette[1], linewidth = 3.5)
 #, label = false)
CairoMakie.band!(ax2, event_size, diff_LB, diff_UB, color = (Palette[1], 0.35))
 
CairoMakie.lines!(ax2, event_size, thresh_balt, linestyle = :dash, color = "black", linewidth = 2)


#Add 100-year event and Floodwall height
CairoMakie.vlines!(ax2, 2.804, color = Palette[3], linewidth = 2.5) # 100-yr event = 1.98 m

#Create Legend
elem_1 = [LineElement(color = Palette[1], linestyle = :solid, linewidth = 5), PolyElement(color = (Palette[1], 0.35))]

elem_2 = [LineElement(color = Palette[2], linestyle = :solid, linewidth = 5), PolyElement(color = (Palette[2], 0.35))]

elem_3 = [LineElement(color = Palette[3], linestyle = :solid)]

#elem_4 = [LineElement(color = Palette[7], linestyle = :solid)]

Legend(fig[3, 1:2], [elem_1, elem_2, elem_3] , ["High Risk Aversion", "Low Risk Aversion", "Levee Height"],
orientation = :horizontal, framevisible = false, labelsize = 16) #position = :lt,

rowgap!(fig.layout, 2, 25)
display(fig)

CairoMakie.save(joinpath(pwd(),"figures/risk_transference.png"), fig)


### Additional Analysis
#Number of realizations with no risk transference
no_rt_high = findall(<(0),diff_dam[14,:])
println("Percent of High RA Realizations with No Risk Transference (CHANCE-C): $((length(no_rt_high)/1000) * 100)%")

no_rt_low = findall(<(0),diff_dam_low[14,:])
println("Percent of Low RA Realizations with No Risk Transference (CHANCE-C): $((length(no_rt_low)/1000) * 100)%")


#Calculate Risk Shifting integral
#Define Function to calculate return period from return level
surge_event = collect(range(0.75,4.0, step=0.25))
function GEV_rp(z_p, mu = μ, sig = σ, xi = ξ)
    y_p = 1 + (xi * ((z_p - mu)/sig))
    rp = -exp(-y_p^(-1/xi)) + 1
    rp = round(rp, digits = 3)
    return 1/rp
end

#Extract params from GEV distribution calibrated to Baltimore
mu, sig, xi =  StatsBase.params(CHANCE_C.default_gev)

#Calculate prob of occurrence of surge events from GEV distribution
surge_rp = 1 ./ GEV_rp.(surge_event, Ref(mu), Ref(sig), Ref(xi))


RSI_high = log.(sum(Matrix(levee_dam) .* surge_rp, dims = 1) ./ sum(Matrix(base_dam) .* surge_rp, dims = 1))
println("For High RA:\n Minimum RSI -> $(minimum(RSI_high)),\n Maximum RSI -> $(maximum(RSI_high)),\n Median RSI -> $(median(RSI_high))")

RSI_low = log.(sum(Matrix(levee_dam_low) .* surge_rp, dims = 1) ./ sum(Matrix(base_dam_low) .* surge_rp, dims = 1))
println("For Low RA:\n Minimum RSI -> $(minimum(RSI_low)),\n Maximum RSI -> $(maximum(RSI_low)),\n Median RSI -> $(median(RSI_low))")