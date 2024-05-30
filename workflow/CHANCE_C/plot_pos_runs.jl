### Assess the evolution of model realizations where risk transference is observed.
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using ColorSchemes

##load damage data
## Read in dataframes
base_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/base_event_damage.csv")))
levee_dam = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/levee_event_damage.csv")))

event_size = collect(range(0.75, 4.0, step = 0.25))
seed_range = collect(range(1000,1999, step = 1))

#Calculate scenario difference and determine seeds that show risk trensference
diff_dam = Matrix(levee_dam) .- Matrix(base_dam) 
pos_seeds = seed_range[findall(i ->(i>0), diff_dam[end,:])]

## Load abm data
adf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_balt_city.csv")))
mdf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_balt_city.csv")))

filter!(row -> !(row.step == 0), mdf)
filter!(row -> (row.step == 50), adf)

#Select model realization to highlight in plots
adf_pos = filter(:seed => in(pos_seeds), adf)
mdf_pos = filter(:seed => in(pos_seeds), mdf)

adf_neg = filter(:seed => !in(pos_seeds), adf)
mdf_neg = filter(:seed => !in(pos_seeds), mdf)



#transform!(adf, [:sum_population_f_c_bgs, :sum_pop90_f_c_bgs] =>
#                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :flood_pop_change)
                
#transform!(adf, [:sum_population_nf_c_bgs, :sum_pop90_nf_c_bgs] =>
#                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :nf_pop_change)

#Subset dataframes by scenario
adf_base_pos = subset(adf_pos, :levee => ByRow(isequal(false)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))
mdf_base_pos = subset(mdf_pos, :levee => ByRow(isequal(false)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))

adf_levee_pos = subset(adf_pos, :levee => ByRow(isequal(true)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))
mdf_levee_pos = subset(mdf_pos, :levee => ByRow(isequal(true)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))

adf_base_neg = subset(adf_neg, :levee => ByRow(isequal(false)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))
mdf_base_neg = subset(mdf_neg, :levee => ByRow(isequal(false)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))

adf_levee_neg = subset(adf_neg, :levee => ByRow(isequal(true)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))
mdf_levee_neg = subset(mdf_neg, :levee => ByRow(isequal(true)), :slr => ByRow(isequal(true)), :risk_averse => ByRow(isequal(0.3)))



## Plot evolution of selected seeds
fig = Figure(size = (1000, 1000))
ga = fig[1, :] = GridLayout()
gb = fig[2, :] = GridLayout()


ax1 = Axis(ga[1, 1], xlabel = "Total Flood Area", ylabel = "Count", title = "Baseline")
hidespines!(ax1, :t, :r)

ax2 = Axis(ga[1, 2], title = "Levee", xlabel = "Total Flood Area")
hidespines!(ax2, :t, :r)

ax3 = Axis(gb[1, 1], ylabel = "Floodplain Population (%)", xlabel = "Model Timestep (year)", 
limits = ((0,50), nothing))
hidespines!(ax3, :t, :r)

ax4 = Axis(gb[1, 2], xlabel = "Model Timestep (year)", limits = ((0,50), nothing))
hidespines!(ax4, :t, :r)

#linkyaxes!(ax1, ax2)
linkyaxes!(ax3, ax4)

palette = ColorSchemes.okabe_ito


## plot flood depths
CairoMakie.hist!(ax1, mdf_base.total_fld_area, color = palette[2], strokewidth=1)
#for i in eachindex(unique(mdf_base.seed))
#    CairoMakie.lines!(ax1, mdf_base.step[1+(i-1)*50:i*50], mdf_base.total_fld_area[1+(i-1)*50:i*50], color = palette[7], alpha = 0.35, linewidth = 1)
#end


#Levee
CairoMakie.hist!(ax2, mdf_levee.total_fld_area, color = palette[3], strokewidth=1)
#for i in eachindex(unique(mdf_levee.seed))
#    CairoMakie.lines!(ax2, mdf_levee.step[1+(i-1)*50:i*50], mdf_levee.total_fld_area[1+(i-1)*50:i*50], color = palette[7], alpha = 0.35, linewidth = 1)
#end


## plot agents in the floodplain
pop_diff_pos
#for i in eachindex(unique(adf_base.seed))
#    CairoMakie.lines!(ax3, adf_base.step[1+(i-1)*51:i*51], adf_base.flood_pop_change[1+(i-1)*51:i*51], 
#    color = (palette[2], 0.5), linewidth = 2, transparency = true)
#end

#axislegend(ax3, merge = true, unique = false, position = :lt)

#Levee 
#for i in eachindex(unique(adf_levee.seed))
#    CairoMakie.lines!(ax4, adf_levee.step[1+(i-1)*51:i*51], adf_levee.flood_pop_change[1+(i-1)*51:i*51],
#     color = (palette[3], 0.5), linewidth = 2, transparency = true)
#end
#axislegend(ax4, merge = true, unique = false, position = :lt)
#CairoMakie.lines!(ax4, adf_show_levee_high.step, adf_show_levee_high.count_floodplain_fam, color = palette[1], linewidth = 3)
#CairoMakie.lines!(ax4, adf_show_levee_low.step, adf_show_levee_low.count_floodplain_fam, color = palette[2], linewidth = 3)
#Create Legend
#elem_1 = [LineElement(color = palette[1], linestyle = nothing)]

#elem_2 = [LineElement(color = palette[2], linestyle = nothing)]

#Legend(fig[2,1:2], [elem_1, elem_2] , ["High RA", "Low RA"])

#rowgap!(fig.layout, 1, 2)
display(fig)


CairoMakie.save(joinpath(pwd(),"figures/pos_runs.png"), fig)