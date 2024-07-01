### Create Tables of damage estimates for each levee scenario across surge event_damages
#activate project environment
using Pkg
Pkg.activate(".")
Pkg.instantiate()

using CSV, DataFrames
using PrettyTables

data_location = "baltimore-data/model_inputs"
balt_ddf = DataFrame(CSV.File(joinpath(dirname(pwd()), data_location, "ddfs", "ens_agg_bg.csv")))

surge_event = collect(range(0.75,4.0, step=0.25))
base_loss = sum(Matrix(select(balt_ddf, r"naccs_loss_Base")), dims = 1)
levee_loss = sum(Matrix(select(balt_ddf, r"naccs_loss_Levee")), dims = 1)
loss_diff = vec(levee_loss) .- vec(base_loss)

data = hcat(surge_event, vec(levee_loss) ./ 1e6, vec(base_loss) ./ 1e6, loss_diff)

header = (
    ["Surge Event", "Levee Flood Loss", "Baseline Flood Loss", "Difference in Loss"],
    ["(m)", "(\$ Millions)", "(\$ Millions)", "(\$)"]
)

pretty_table(data; header = header)