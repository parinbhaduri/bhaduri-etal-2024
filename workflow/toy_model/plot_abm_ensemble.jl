#activate project environment
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using ColorSchemes

#import GEV functions from toy model
include(joinpath(@__DIR__, "src/toy_ABM_functions.jl"))

#Read in ABM ensemble evolution data
adf_base = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_base.csv")))
mdf_base = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_base.csv")))
#Separate high RA and low RA
adf_base_high = filter(:risk_averse => isequal(0.3), adf_base)
adf_base_low = filter(:risk_averse => isequal(0.7), adf_base)

adf_levee = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_levee.csv")))
mdf_levee = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_levee.csv")))
#Separate high RA and low RA
adf_levee_high = filter(:risk_averse => isequal(0.3), adf_levee)
adf_levee_low = filter(:risk_averse => isequal(0.7), adf_levee)

#Select one model realization to highlight in plots
adf_show = filter(:seed => isequal(1897), adf_base)
mdf_show = filter(:seed => isequal(1897), mdf_base)
#Separate high RA and low RA
adf_show_high = filter(:risk_averse => isequal(0.3), adf_show)
adf_show_low = filter(:risk_averse => isequal(0.7), adf_show)

adf_show_levee = filter(:seed => isequal(1897), adf_levee)
mdf_show_levee = filter(:seed => isequal(1897), mdf_levee)
#Separate high RA and low RA
adf_show_levee_high = filter(:risk_averse => isequal(0.3), adf_show_levee)
adf_show_levee_low = filter(:risk_averse => isequal(0.7), adf_show_levee)

flood_100 = [GEV_return(1/100) for _ in 1:51]

##Plot Baseline Results
fig = Figure(size = (1000, 1000))
ga = fig[1, 1:2] = GridLayout()
gb = fig[2, 1:2] = GridLayout()

ax1 = Axis(ga[1, 1], ylabel = "Flood Depth (feet)", title = "Baseline",
limits = ((0,50), (0,40)))
hidespines!(ax1, :t, :r)

ax2 = Axis(ga[1, 2], title = "Levee", limits = ((0,50), (0,40)))
hidespines!(ax2, :t, :r)

ax3 = Axis(gb[1, 1], ylabel = "Floodplain Population (count)", xlabel = "Model Timestep (year)", 
limits = ((0,50), nothing))
hidespines!(ax3, :t, :r)

ax4 = Axis(gb[1, 2], xlabel = "Model Timestep (year)", limits = ((0,50), nothing))
hidespines!(ax4, :t, :r)

linkyaxes!(ax1, ax2)
linkyaxes!(ax3, ax4)

palette = ColorSchemes.tol_bright
## plot flood depths
CairoMakie.lines!(ax1, mdf_base.step[1:51051], mdf_base.floodepth[1:51051], color = palette[7], alpha = 0.35, linewidth = 1)
CairoMakie.lines!(ax1, mdf_show.step[1:51], mdf_show.floodepth[1:51], color = palette[3], linewidth = 3)
#Add line showing 100- yr level 
CairoMakie.lines!(ax1, mdf_show.step[1:51],flood_100, linestyle = :dash, color = "black", linewidth = 3)
#Plots.ylabel!("Flood Depth", pointsize = 28)

#Levee
CairoMakie.lines!(ax2, mdf_levee.step[1:51051], mdf_levee.floodepth[1:51051], color = palette[7], alpha = 0.35, linewidth = 1)
CairoMakie.lines!(ax2, mdf_show_levee.step[1:51], mdf_show_levee.floodepth[1:51], color = palette[3], linewidth = 3)
#Add line showing 100- yr level 
CairoMakie.lines!(ax2, mdf_show_levee.step[1:51],flood_100, linestyle = :dash, color = "black", linewidth = 3)
elem_lev = [LineElement(color = :black, linestyle = :dash)]
Legend(ga[1,3], [elem_lev], ["100-year"])

## plot agents in the floodplain
CairoMakie.lines!(ax3, adf_base_high.step, adf_base_high.count_floodplain_fam, color = (palette[1], 0.35), linewidth = 1, transparency = true)
CairoMakie.lines!(ax3, adf_base_low.step, adf_base_low.count_floodplain_fam, color = (palette[2], 0.35), linewidth = 1, transparency = true)

CairoMakie.lines!(ax3, adf_show_high.step, adf_show_high.count_floodplain_fam, color = palette[1], linewidth = 3)
CairoMakie.lines!(ax3, adf_show_low.step, adf_show_low.count_floodplain_fam, color = palette[2], linewidth = 3)
#Plots.ylabel!("Floodplain Pop.", pointsize = 28)
#Plots.ylims!(0,500)
#Plots.xlabel!("Year", pointsize = 28)
#Levee 
CairoMakie.lines!(ax4, adf_levee_high.step, adf_levee_high.count_floodplain_fam, color = (palette[1], 0.35), linewidth = 1, transparency = true)
CairoMakie.lines!(ax4, adf_levee_low.step, adf_levee_low.count_floodplain_fam, color = (palette[2], 0.35), linewidth = 1, transparency = true)

CairoMakie.lines!(ax4, adf_show_levee_high.step, adf_show_levee_high.count_floodplain_fam, color = palette[1], linewidth = 3)
CairoMakie.lines!(ax4, adf_show_levee_low.step, adf_show_levee_low.count_floodplain_fam, color = palette[2], linewidth = 3)
#Create Legend
elem_1 = [LineElement(color = palette[1], linestyle = nothing)]

elem_2 = [LineElement(color = palette[2], linestyle = nothing)]

Legend(gb[1,3], [elem_1, elem_2] , ["High RA", "Low RA"])

rowgap!(fig.layout, 1, 5)
fig




CairoMakie.save(joinpath(pwd(),"figures/abm_ensemble.png"), fig)


