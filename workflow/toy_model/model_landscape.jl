#activate project environment and import packages
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CairoMakie
using ColorSchemes
#using InteractiveDynamics
#import breach functions from toy model
include(joinpath(dirname(@__DIR__), "src/toy_ABM_functions.jl"))

test_abm = flood_ABM(;)
length_x, length_y = size(test_abm.Elevation)

model_fig = Figure(size = (500,900), fontsize = 16, pt_per_unit = 1, figure_padding = 10)


ax1 = Axis(model_fig[1,1], aspect = 1, titlealign = :left, title = "a. Flood Return Periods (Years)")
hidedecorations!(ax1)

ax2 = Axis(model_fig[1,3], aspect = 1, titlealign = :left, title = "b. Structural Utility Values (\$ thousands)")
hidedecorations!(ax2)

##Create heatmap for Flood level GEV_return
function flood_rps(model::ABM)
    #Calculate flood returns
    flood_10 = GEV_return(1/10)
    flood_100 = GEV_return(1/100)
    flood_500 = GEV_return(1/500)
    flood_1000 = GEV_return(1/1000)
    #Create matrix 
    flood_return = zeros(size(model.Elevation))
    #return_labels = ["$i-yr" for i in [10,100,500,1000]]
    flood_return[model.Elevation .<= flood_10] .= 1
    flood_return[model.Elevation .> flood_10 .&& model.Elevation .<= flood_100 ] .= 2
    flood_return[model.Elevation .> flood_100 .&& model.Elevation .<= flood_500 ] .= 3
    flood_return[model.Elevation .> flood_500 .&& model.Elevation .<= flood_1000 ] .= 4
    return flood_return
end

flood_mat = flood_rps(test_abm)

fm = CairoMakie.heatmap!(ax1, 1:length_x, 1:length_y, flood_mat, colormap = reverse(cgrad(:Blues_4, 4, categorical = true)), tellheight = true)
fm.colorrange = (0.5,4.5)
f_col = Colorbar(model_fig[1, 2], fm, ticks = ([1,2,3,4], ["10","100","500", "1000"]))#, vertical = false)
#f_col.ticks = 1:4
#f_col.tellheight = true

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

um = CairoMakie.heatmap!(ax2, 1:length_x, 1:length_y, util_mat, colormap = cgrad(:bam, [0.3,0.5]), tellheight = true)
Colorbar(model_fig[1, 4], um, ticks = ([3e5,4e5,5e5,6e5], ["300","400","500", "600"]))

rowsize!(model_fig.layout, 1, Aspect(1, 1))
model_fig


CairoMakie.save(joinpath(pwd(),"figures/model_landcape.png"), model_fig)

""" 
#savefig(figure_utility, "src/Parameter_visual/fig_utility.png")

include(joinpath(dirname(@__DIR__),"src/visual_attrs.jl"))

#step through ABM
step!(test_abm, dummystep, combine_step!, 5)
abmplot!(ax1,test_abm; plotkwargs...)

model_fig
"""