#activate project environment
using Pkg
Pkg.activate(pwd())
Pkg.instantiate()

##Graph Agent action probability
using Plots
#Create function
function move_curve(x; ra = 0.3, scale = 0, base_prob = 0.025)
    if x == 0.0
        prob = base_prob
    else
        init_prob = 1/(1+ exp(-(x - ra)/(0.1 - scale))) + base_prob
        prob = init_prob > 1 ? 1 : init_prob
    end
    return prob
end

x = range(0,1, length = 100)

y = move_curve.(x; ra = 0.5)
y1 = move_curve.(x; ra = 0.3)
y2 = move_curve.(x; ra = 0.7)

#Fixed Effect Curves
y1_scale = move_curve.(x; ra = 0.3, scale = 0.03)
y2_scale = move_curve.(x; ra = 0.3, scale = 0.05)
y3_scale = move_curve.(x; ra = 0.3, scale = 0.01)
y4_scale = move_curve.(x; ra = 0.3, scale = 0.08)

log_fig = Plots.plot(x.*10,[y1 y y2], label = ["High RA" "Medium RA" "Low RA"], lw = 3,
 legend = :outertopright)
Plots.xlabel!("Flood Events per Decade")
Plots.ylabel!("Action Probability")
savefig(log_fig, joinpath(@__DIR__,"figures/log_func.png"))

log_scale_fig = Plots.plot(x.*10,[y1 y1_scale y2_scale y3_scale y4_scale], label = ["High RA" "High RA w/ fe = 0.03" "High RA w/ fe = 0.05" "High RA w/ fe = 0.01" "High RA w/ fe = 0.08"], lw = 3,
 legend = :bottomright)
Plots.xlabel!("Flood Events per Decade")
Plots.ylabel!("Action Probability")
savefig(log_scale_fig, joinpath(@__DIR__,"figures/log_func.png"))