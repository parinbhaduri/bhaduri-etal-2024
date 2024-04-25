"""Code for plot attributes when visualizing spatial plots"""
#Collect Flood events from House Agents
function flood_color(model::ABM)
    #create space equivalent to model
    space_size = size(model.space)
    flood_event_space = zeros(space_size[1],space_size[2])
    #Collect all Houses
    model_houses = [n for n in allagents(model) if n isa House]
    #Assign flood mem to matrix space
    for i in model_houses
        flood_event_space[i.pos[1], i.pos[2]] = Int64(i.flood_mem+1)
    end
    return flood_event_space
end

Floodcolor(agent::Family) = :black 
const housecolor = cgrad(:dense, 11, categorical = true)
Floodcolor(agent::House) = housecolor[Int64(agent.flood_mem+1)]

Floodshape(agent::Family) = '⌂'
Floodsize(agent::Family) = 30
Floodshape(agent::House) = '■'
Floodsize(agent::House) = 1,1

plotsched = Schedulers.ByType((House, Family), false)

color_kwargs = (;
colormap = housecolor)

plotkwargs = (;
ac = Floodcolor, 
as =Floodsize, 
am = Floodshape,
scheduler = plotsched, 
heatarray = flood_color, 
add_colorbar = true,
heatkwargs = color_kwargs,
)
#scatterkwargs = (strokewidth = 1.0,)