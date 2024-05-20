### Recreate key figures from Yoon et al., 2023 ###
import Pkg
Pkg.activate(".")
Pkg.instantiate()

using CHANCE_C 
using CSV, DataFrames


## Load input Data
#Set location of input data
data_location = "baltimore-housing-data/model_inputs"
balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))

#import functions to collect data 
include(joinpath(@__DIR__, "src/data_collect.jl"))
using Plots

## Load abm data
adf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/adf_balt.csv")))
mdf = DataFrame(CSV.File(joinpath(@__DIR__,"dataframes/mdf_balt.csv")))

#Calculate population change in floodplain and non-floodplain block groups over time
transform!(adf, [:sum_population_f_bgs, :sum_pop90_f_bgs] =>
                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :flood_pop_change)
                
transform!(adf, [:sum_population_nf_bgs, :sum_pop90_nf_bgs] =>
                ByRow((pop, pop90) -> 100 * (pop - pop90) / pop90) => :nf_pop_change)

#Subset Dataframes by scenario
adf_avoid = subset(adf, :levee => ByRow(isequal(false)), :slr => ByRow(isequal(false)), :seed => ByRow(isequal(1897)))
mdf_avoid = subset(mdf, :levee => ByRow(isequal(false)), :slr => ByRow(isequal(false)), :seed => ByRow(isequal(1897)))

adf_levee = subset(adf, :levee => ByRow(isequal(true)), :slr => ByRow(isequal(false)), :seed => ByRow(isequal(1897)))
mdf_levee = subset(mdf, :levee => ByRow(isequal(true)), :slr => ByRow(isequal(false)), :seed => ByRow(isequal(1897)))
 


#Plot results
#surge level
surge_base = Plots.plot(mdf_avoid.step[2:51], mdf_avoid.flood_record[2:51], linecolor = :black, lw = 4)
Plots.title!("Baseline")

#Cumulative remembered flood density at each time step
flood_dense = Plots.plot(mdf_avoid.step[2:51], mdf_avoid.total_fld_area[2:51], linecolor = :blue, lw = 3)
Plots.ylims!(0,50)

#Pop Change
avoid_col = cgrad(:redsblues, 2, categorical = true)

pop_avoidance = Plots.plot(adf_avoid.step, adf_avoid.nf_pop_change, group = adf_avoid.risk_averse,
 linecolor = [avoid_col[1] avoid_col[2]], ls = :solid,
  label = ["high RA" "low RA"], lw = 2.5)

Plots.plot!(adf_avoid.step, adf_avoid.flood_pop_change, group = adf_avoid.risk_averse, 
linecolor = [avoid_col[1] avoid_col[2]], ls = :dash,
 label = false, lw = 2.5)

Plots.ylims!(-10,100)
Plots.xlabel!("Model Year")
Plots.ylabel!("% Change in Population")

#create subplot
averse_results = Plots.plot(surge_base, flood_dense, pop_avoidance, layout = (3,1), dpi = 300, size = (500,600))





### For Levee Scenario ### 

#Plot results
#surge level
surge_levee = Plots.plot(mdf_levee.step[2:51], mdf_levee.flood_record[2:51], linecolor = :black, lw = 4)
flood_pop_change = 100 .* (adf_levee.sum_population_f_bgs .- adf_levee.sum_pop90_f_bgs) ./ adf_levee.sum_pop90_f_bgs
nf_pop_change = 100 .* (adf_levee.sum_population_nf_bgs .- adf_levee.sum_pop90_nf_bgs) ./ adf_levee.sum_pop90_nf_bgs
Plots.title!("Levee")

#Cumulative remembered flood density at each time step
flood_dense_levee = Plots.plot(mdf_levee.step[2:51], mdf_levee.total_fld_area[2:51], linecolor = :blue, lw = 3)
Plots.ylims!(0,50)
#Population change
avoid_col = cgrad(:redsblues, 2, categorical = true)
pop_avoid_levee = Plots.plot(adf_levee.step, nf_pop_change, group = adf_levee.risk_averse,
 linecolor = [avoid_col[1] avoid_col[2]], ls = :solid,
  label = ["High RA" "Low RA"], lw = 2.5)

Plots.plot!(adf_levee.step, flood_pop_change, group = adf_levee.risk_averse, 
linecolor = [avoid_col[1] avoid_col[2]], ls = :dash, 
label = false, lw = 2.5)

Plots.ylims!(-10,100)
Plots.xlabel!("Model Year")
Plots.ylabel!("% Change in Population")

#create subplot
levee_results = Plots.plot(surge_levee, flood_dense_levee, pop_avoid_levee, layout = (3,1), dpi = 300, size = (500,600))