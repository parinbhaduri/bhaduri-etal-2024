
### Import functions to run toy model from toy model repo
include(joinpath(dirname(pwd()),"flood-risk-abm/src/base_model.jl"))

###Define data collection
include(joinpath(dirname(pwd()),"flood-risk-abm/src/data_collect.jl"))

