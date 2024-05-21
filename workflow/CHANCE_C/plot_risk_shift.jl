#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using CairoMakie
using FileIO

## Read in dataframes
occ_low = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/base_event_damage.csv")))
occ_med = DataFrame(CSV.File(joinpath(dirname(@__DIR__),"dataframes/levee_event_damage.csv")))

event_size = range(0.75, 4.0, step = 0.25)
threshold = zeros(length(event_size))