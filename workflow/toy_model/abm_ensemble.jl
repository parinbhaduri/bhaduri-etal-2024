#activate project environment
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()

##Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/parallel_setup.jl"))

##Evolve models over different parameter combinations for baseline scenario
params = Dict(
    :Elev => Elevation,
    :risk_averse => [0.3, 0.7],
    :levee => 0.0,
    :breach => false,
    :b_n => 0.45,
    :N => 1200,
    :mem => 10,
    :fe => 0.0,
    :prob_move => 0.025,  
    :pop_growth => 0.0,
    :seed => collect(range(1000,2000)), 
)

adf, mdf = paramscan(params, flood_ABM; parallel = true, showprogress = true, adata, mdata, agent_step! = dummystep, model_step! = combine_step!, n = 50)
CSV.write(joinpath(@__DIR__,"dataframes/adf_base.csv"), adf)
CSV.write(joinpath(@__DIR__,"dataframes/mdf_base.csv"), mdf)

###Repeat for Levee Scenario 
##Evolve models over different parameter combinations
params_levee = Dict(
    :Elev => Elevation,
    :risk_averse => [0.3, 0.7],
    :levee => 1/100,
    :breach => true,
    :b_n => 0.45,
    :N => 1200,
    :mem => 10,
    :fe => 0.0,
    :prob_move => 0.025,  
    :pop_growth => 0.0,
    :seed => collect(range(1000,2000)), 
)
##Evolve models over different parameter combinations
adf_levee, mdf_levee = paramscan(params_levee, flood_ABM; parallel = true, showprogress = true, adata, mdata, agent_step! = dummystep, model_step! = combine_step!, n = 50)
CSV.write(joinpath(@__DIR__,"dataframes/adf_levee.csv"), adf_levee)
CSV.write(joinpath(@__DIR__,"dataframes/mdf_levee.csv"), mdf_levee)

#remove parallel processors
rmprocs(workers())