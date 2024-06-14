#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using ColorSchemes

#import GEV functions from toy model
include(joinpath(@__DIR__, "src/toy_ABM_functions.jl"))

#Read in ABM ensemble evolution data
adf_base = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_base.csv")))
mdf_base = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_base.csv")))

mdf_base = subset(mdf_base, :risk_averse => ByRow(isequal(0.3))) #Just grab one flood record ensemble

#Separate high RA and low RA
adf_base_high = filter(:risk_averse => isequal(0.3), adf_base)
adf_base_low = filter(:risk_averse => isequal(0.7), adf_base)

adf_levee = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_levee.csv")))
mdf_levee = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_levee.csv")))

mdf_levee = subset(mdf_levee, :risk_averse => ByRow(isequal(0.3))) #Just grab one flood record ensemble

#Separate high RA and low RA
adf_levee_high = filter(:risk_averse => isequal(0.3), adf_levee)
adf_levee_low = filter(:risk_averse => isequal(0.7), adf_levee)

#Select one model realization to highlight in plots
adf_show = filter(:seed => isequal(1005), adf_base)
mdf_show = filter(:seed => isequal(1005), mdf_base)
#Separate high RA and low RA
adf_show_high = filter(:risk_averse => isequal(0.3), adf_show)
adf_show_low = filter(:risk_averse => isequal(0.7), adf_show)

adf_show_levee = filter(:seed => isequal(1005), adf_levee)
mdf_show_levee = filter(:seed => isequal(1005), mdf_levee)
#Separate high RA and low RA
adf_show_levee_high = filter(:risk_averse => isequal(0.3), adf_show_levee)
adf_show_levee_low = filter(:risk_averse => isequal(0.7), adf_show_levee)

flood_100 = [GEV_return(1/100) for _ in 1:51]

##Plot Baseline Results
fig = Figure(size = (1000, 1000))
ga = fig[1, 1:3] = GridLayout()
gb = fig[2, 1:3] = GridLayout()

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

palette = ColorSchemes.okabe_ito
## plot flood depths
for i in eachindex(unique(mdf_base.seed))
    CairoMakie.lines!(ax1, mdf_base.step[1+(i-1)*51:i*51], mdf_base.floodepth[1+(i-1)*51:i*51], color = :lightgrey, alpha = 0.35, linewidth = 1)
end

CairoMakie.lines!(ax1, mdf_show.step, mdf_show.floodepth, color = palette[3], linewidth = 3)
#Add line showing 100- yr level 
CairoMakie.lines!(ax1, mdf_show.step,flood_100, linestyle = :dash, color = "black", linewidth = 3)
#Plots.ylabel!("Flood Depth", pointsize = 28)

#Levee
for i in eachindex(unique(mdf_levee.seed))
    CairoMakie.lines!(ax2, mdf_levee.step[1+(i-1)*51:i*51], mdf_levee.floodepth[1+(i-1)*51:i*51], color = :lightgrey, alpha = 0.35, linewidth = 1)
end

CairoMakie.lines!(ax2, mdf_show_levee.step, mdf_show_levee.floodepth, color = palette[3], linewidth = 3)
#Add line showing 100- yr level 
CairoMakie.lines!(ax2, mdf_show_levee.step,flood_100, linestyle = :dash, color = "black", linewidth = 3)
elem_lev = [LineElement(color = :black, linestyle = :dash)]
Legend(ga[1,3], [elem_lev], ["100-year"])

## plot agents in the floodplain
CairoMakie.series!(ax3, transpose(reshape(adf_base_high.count_floodplain_fam, (51,1001))), solid_color = (palette[2], 0.25), linewidth = 1, overdraw = true, transparency = true)
CairoMakie.series!(ax3, transpose(reshape(adf_base_low.count_floodplain_fam, (51,1001))), solid_color = (palette[1], 0.25), linewidth = 1, overdraw = true, transparency = true)

CairoMakie.lines!(ax3, adf_show_high.step, adf_show_high.count_floodplain_fam, color = palette[5], alpha = 1.0, linewidth = 3)
CairoMakie.lines!(ax3, adf_show_low.step, adf_show_low.count_floodplain_fam, color = palette[6], alpha = 1.0, linewidth = 3)
#Plots.ylabel!("Floodplain Pop.", pointsize = 28)
#Plots.ylims!(0,500)
#Plots.xlabel!("Year", pointsize = 28)
#Levee
CairoMakie.series!(ax4, transpose(reshape(adf_levee_high.count_floodplain_fam, (51,1001))), solid_color = (palette[2], 0.25), linewidth = 1, overdraw = true, transparency = true)
CairoMakie.series!(ax4, transpose(reshape(adf_levee_low.count_floodplain_fam, (51,1001))), solid_color = (palette[1], 0.25), linewidth = 1, overdraw = true, transparency = true)

CairoMakie.lines!(ax4, adf_show_levee_high.step, adf_show_levee_high.count_floodplain_fam, color = palette[5], linewidth = 3)
CairoMakie.lines!(ax4, adf_show_levee_low.step, adf_show_levee_low.count_floodplain_fam, color = palette[6], linewidth = 3)
#Create Legend
elem_1 = [LineElement(color = palette[5], linestyle = nothing)]

elem_2 = [LineElement(color = palette[6], linestyle = nothing)]

Legend(gb[1,3], [elem_1, elem_2] , ["High RA", "Low RA"])

rowgap!(fig.layout, 1, 5)
display(fig)



CairoMakie.save(joinpath(pwd(),"figures/abm_ensemble.png"), fig)


fig = Figure(size = (1000, 1000))
ax = Axis(fig[1,1])

CairoMakie.series!(ax, transpose(reshape(adf_levee_high.count_floodplain_fam, (51,1001))), solid_color = (palette[1], 0.35), linewidth = 1, transparency = true)
fig
transpose(reshape(adf_levee_high.count_floodplain_fam, (51,1001)))
