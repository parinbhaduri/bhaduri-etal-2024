#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using ColorSchemes

## Load abm data
adf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_balt_city.csv")))
mdf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_balt_city.csv")))

filter!(row -> !(row.step == 0), mdf)

transform!(adf, [:sum_population_f_c_bgs, :sum_pop90_f_c_bgs] =>
                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :flood_pop_change)
                
transform!(adf, [:sum_population_nf_c_bgs, :sum_pop90_nf_c_bgs] =>
                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :nf_pop_change)

#Subset dataframes by scenario
adf_base = subset(adf, :levee => ByRow(isequal(false)), :slr => ByRow(isequal(true)))
mdf_base = subset(mdf, :levee => ByRow(isequal(false)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))

adf_base_high = subset(adf_base, :risk_averse => ByRow(isequal(0.3)))
adf_base_low = subset(adf_base,  :risk_averse => ByRow(isequal(0.7)))


adf_levee = subset(adf, :levee => ByRow(isequal(true)), :slr => ByRow(isequal(true)))
mdf_levee = subset(mdf, :levee => ByRow(isequal(true)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))

adf_levee_high = subset(adf_levee, :risk_averse => ByRow(isequal(0.3)))
adf_levee_low = subset(adf_levee, :risk_averse => ByRow(isequal(0.7)))


##Plot Baseline Results
fig = Figure(size = (1000, 1000))
ga = fig[1, 1] = GridLayout()
gb = fig[1, 2] = GridLayout()

"""
ax1 = Axis(ga[1, 1], ylabel = "Flood Depth (feet)", title = "Baseline",
limits = ((0,50), (0,40)))
hidespines!(ax1, :t, :r)

ax2 = Axis(ga[1, 2], title = "Levee", limits = ((0,50), (0,40)))
hidespines!(ax2, :t, :r)
"""
ax3 = Axis(ga[1, 1], title = "Baseline", ylabel = "Floodplain Population (%)", xlabel = "Model Timestep (year)", 
limits = ((0,50), nothing))
hidespines!(ax3, :t, :r)

ax4 = Axis(gb[1, 1], title = "Levee", xlabel = "Model Timestep (year)", limits = ((0,50), nothing))
hidespines!(ax4, :t, :r)

#linkyaxes!(ax1, ax2)
linkyaxes!(ax3, ax4)

palette = ColorSchemes.okabe_ito

"""
## plot flood depths
for i in eachindex(unique(mdf_base.seed))
    CairoMakie.lines!(ax1, mdf_base.step[1+(i-1)*50:i*50], mdf_base.total_fld_area[1+(i-1)*50:i*50], color = palette[7], alpha = 0.35, linewidth = 1)
end


#Levee
for i in eachindex(unique(mdf_levee.seed))
    CairoMakie.lines!(ax2, mdf_levee.step[1+(i-1)*50:i*50], mdf_levee.total_fld_area[1+(i-1)*50:i*50], color = palette[7], alpha = 0.35, linewidth = 1)
end
"""

## plot agents in the floodplain
for i in eachindex(unique(adf_base_high.seed))
    CairoMakie.lines!(ax3, adf_base_high.step[1+(i-1)*51:i*51], adf_base_high.flood_pop_change[1+(i-1)*51:i*51], 
    color = (palette[2], 0.35), linewidth = 1, transparency = true, label = "High Risk Aversion")
    CairoMakie.lines!(ax3, adf_base_low.step[1+(i-1)*51:i*51], adf_base_low.flood_pop_change[1+(i-1)*51:i*51], 
    color = (palette[1], 0.35), linewidth = 1, transparency = true, label = "Low Risk Aversion")
end

axislegend(ax3, merge = true, unique = false, position = :lt)

#CairoMakie.lines!(ax3, adf_show_high.step, adf_show_high.count_floodplain_fam, color = palette[1], linewidth = 3)
#CairoMakie.lines!(ax3, adf_show_low.step, adf_show_low.count_floodplain_fam, color = palette[2], linewidth = 3)
#Plots.ylabel!("Floodplain Pop.", pointsize = 28)
#Plots.ylims!(0,500)
#Plots.xlabel!("Year", pointsize = 28)
#Levee 
for i in eachindex(unique(adf_levee_high.seed))
    CairoMakie.lines!(ax4, adf_levee_high.step[1+(i-1)*51:i*51], adf_levee_high.flood_pop_change[1+(i-1)*51:i*51],
     color = (palette[2], 0.35), linewidth = 1, transparency = true, label = "High Risk Aversion")
    CairoMakie.lines!(ax4, adf_levee_low.step[1+(i-1)*51:i*51], adf_levee_low.flood_pop_change[1+(i-1)*51:i*51],
     color = (palette[1], 0.35), linewidth = 1, transparency = true, label = "Low Risk Aversion")
end
axislegend(ax4, merge = true, unique = false, position = :lt)
#CairoMakie.lines!(ax4, adf_show_levee_high.step, adf_show_levee_high.count_floodplain_fam, color = palette[1], linewidth = 3)
#CairoMakie.lines!(ax4, adf_show_levee_low.step, adf_show_levee_low.count_floodplain_fam, color = palette[2], linewidth = 3)
#Create Legend
#elem_1 = [LineElement(color = palette[1], linestyle = nothing)]

#elem_2 = [LineElement(color = palette[2], linestyle = nothing)]

#Legend(fig[2,1:2], [elem_1, elem_2] , ["High RA", "Low RA"])

#rowgap!(fig.layout, 1, 2)
display(fig)


CairoMakie.save(joinpath(pwd(),"figures/chance_c_ensemble_city.png"), fig)

