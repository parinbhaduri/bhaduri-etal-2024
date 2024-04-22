#activate project environment and import packages
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()

using GLMakie 

#import breach functions from toy model
include(joinpath(dirname(@__DIR__), "src/toy_ABM_functions.jl"))

test_abm = flood_ABM(;)
##Create heatmap for Flood level GEV_return
figure = (; resolution=(600, 400), dpi = 300, font="CMU Serif")
#Import Elevation
include("../data/Elevation.jl")
function flood_rps(model::ABM)
    #Calculate flood returns
    flood_10 = GEV_return(1/10)
    flood_100 = GEV_return(1/100)
    flood_500 = GEV_return(1/500)
    flood_1000 = GEV_return(1/1000)
    #Create matrix 
    flood_return = zeros(30,30)
    #return_labels = ["$i-yr" for i in [10,100,500,1000]]
    flood_return[model.Elevation .<= flood_10] .= 1
    flood_return[model.Elevation .> flood_10 .&& model.Elevation .<= flood_100 ] .= 2
    flood_return[model.Elevation .> flood_100 .&& model.Elevation .<= flood_500 ] .= 3
    flood_return[model.Elevation .> flood_500 .&& model.Elevation .<= flood_1000 ] .= 4
    return flood_return
end

flood_mat = flood_rps(test_abm)

figure_flo_ret = Plots.heatmap(1:30,1:30, transpose(flood_mat), levels = 4,
    seriescolor=reverse(palette(:Blues_4)), figure = figure)

savefig(figure_flo_ret, joinpath(@__DIR__,"figures/fig_elev.png"))




###Create heatmap for Utility
function utility_map(model::ABM)
    #Create utility matrix
    util_mat = zeros(size(model.Elevation))
    model_houses = [n for n in allagents(model) if n isa House]
    c1 = 294707 #SqFeet coef
    c2 = 130553 #Age coef
    c3 = 128990 #Stories coef
    c4 = 154887 #Baths coef
    for house in model_houses
        house_price = c1 * house.SqFeet + c2 * house.Age + c3 * house.Stories + c4 * house.Baths
        util_mat[house.pos[1], house.pos[2]] = house_price
    end
    return util_mat
end

util_mat = utility_map(test_abm)

figure = (; resolution=(600, 400), dpi = 300, font="CMU Serif")
figure_utility = Plots.heatmap(1:size(util_mat)[1],1:size(util_mat)[2], transpose(util_mat),
    seriescolor=reverse(cgrad([colorant"#005F73", colorant"#0A9396", colorant"#E9D8A6", colorant"#EE9B00",colorant"#BB3E03"], [0.6,0.8])), colorbar_tickfontsize = 20, Figure = figure)

savefig(figure_utility, "src/Parameter_visual/fig_utility.png")