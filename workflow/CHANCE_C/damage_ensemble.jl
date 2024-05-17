### Calculate expected flood losses at the BG level in the baseline and levee scenarios ### 

#activate project environment
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()

using CSV, Tables, DataFrames
using Parquet2
using Parquet2: Dataset
using CHANCE_C
#Set up parallell processors; Include necessary functions from other scripts
include(joinpath(@__DIR__, "src/config_parallel.jl"))

#import input data 
data_location = "baltimore-housing-data/model_inputs"
balt_base = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_base.csv")))
balt_levee = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "surge_area_baltimore_levee.csv")))



