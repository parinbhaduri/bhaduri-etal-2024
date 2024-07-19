_your zenodo badge here_

# Bhaduri-etal_2024_inprep

**Paper Title**

 `Parin Bhaduri<sup>1*</sup>` , Adam B. Pollack `<sup>2</sup>`, James Yoon `<sup>3</sup>`, Pranab K. Roy Chowdhury `<sup>3</sup>`, Heng Wan `<sup>3</sup>`, David Judi `<sup>3</sup>`, Brent Daniel `<sup>3</sup>`, Vivek Srikrishnan `<sup>1</sup>`

`<sup>1</sup>` Department of Biological & Environmental Engineering, Cornell University, Ithaca, New York, USA
`<sup>2</sup>` Thayer School of Engineering, Darthmouth College, Hanover, New Hampshire, USA
`<sup>3</sup>` Pacific Northwest National Laboratory, Richland, Washington, USA

\* corresponding author:  pbb62@cornell.edu

## Abstract

_Insert your paper abstract._

## Journal reference

_Insert your paper reference. This can be a link to a preprint prior to publication. While in preparation, use a tentative author line and title._

## Code reference

## Data reference

### Input data

Input data for Baltimore used during the CHANCE-C model simulations can be found under `model_inputs/` in the following [data repository](https://github.com/parinbhaduri/baltimore-housing-data). For input data to be read in properly for simulation runs, make sure that the data repository is cloned to the same location as this repository.

### Output data

Output data can be found in the `dataframes/` folder in each experiment folder. These include CSV files for the ABM scenario realizations and the flood impact/damage estimates for both the stylized, toy model experiment (`worflow/toy_model/`), and the Baltimore experiment using CHANCE-C (`workflow/CHANCE_C`)

## Dependencies

This code is based on Julia 1.7. Relevant dependencies are in the `Project.toml` and `Manifest.toml` files (the `Manifest.jl` specifies the particular versions; this file should be kept as-is for perfect reproducibility but may need to be deleted and rebuilt with `Pkg.instantiate()` for different Julia versions).

## Contributing modeling software

We used two models to conduct our experiments:  a stylized ABM created for a synthetic environment (`flood-risk_abm`), and an existing ABM package (`CHANCE-C `) for our Baltimore Case-Study. We use the dynamic version of CHANCE-C (`dynamice_FF` branch) to incorporate repeated flood events in our ABM simulations.

| Model              | Version | Repository Link                                                | DOI                    |
| ------------------ | ------- | -------------------------------------------------------------- | ---------------------- |
| `flood-risk-abm` | -       | https://github.com/parinbhaduri/flood-risk-abm                 |                        |
| `CHANCE-C`       | 1.1.0   | https://github.com/srikrishnan-lab/CHANCE_C.jl/tree/dynamic_FF | link to DOI of release |

Running the experiments in `toy_model/` requires cloning the `flood-risk-abm` repository. To use the toy model, clone the `flood_risk-abm` repository to the same location as As long as the repository is in the correct location, the relevant workflow scripts should be able to import the necessary functions required to run the stylized experiments.

The CHANCE-C package is already listed in the `Project.toml` file and should automatically downloaded once the project environment is built. If CHANCE-C is unable to be imported or precompiled when running the Baltimore experiments, the package can be added to the project environment again using the following command:

```julia
import Pkg
Pkg.add("https://github.com/srikrishnan-lab/CHANCE_C.jl#dynamic_FF")
```

## Reproduction

This section should consist of a walkthrough of how to reproduce your experiment. This should be a complete set of steps, starting from installing any necessary models and downloading data, and including which scripts to run for each piece of the experiment. If your code was written to work on a particular HPC environment (including the queue manager), document that here. If you had to manually make any adjustments that aren't captured by your code, document them here as well.

### Requirements

1. Install the software components required to conduct the experiment from [Contributing modeling software](#contributing-modeling-software)
2. Download and install the supporting input data required to conduct the experiment from [Input data](#input-data)

### Simulation

1. After cloning the repository, install the needed packages:

   ```julia
   import Pkg
   Pkg.activate(".") #from the cloned root directory
   Pkg.instantiate()
   ```
2. Run the necessary scripts to re-simulate the example ensembles. Experiments for each example are located under `workflow/`. Note: We ran ABM scenario ensembles and flood impact summaries in parallel to speed up the data collection process. To change the number of worker processors, state the number of processors in the `addprocs()` command in the relevant parallel config file (`toy_model/src/parallel_setup.jl` or `CHANCE_C/src/config_parallel.jl`). By default, 12 worker processors are used.
3. Some experimental scripts were written to be run in the Hopper HPC environment using the SLURM Task Manager.

To re-simulate the stylized experiments (`toy_model/`):

| Script Name                | Description                                                      | How to Run                                          |
| -------------------------- | ---------------------------------------------------------------- | --------------------------------------------------- |
| `abm_ensemble.jl`        | run ABM scenario ensembles and collect evolution data            | `julia workflow/toy_model/abm_ensemble.jl`        |
| `breach_ensemble.jl`     | Flood Impact summaries for different levee breach likelihoods    | `julia workflow/toy_model/breach_ensemble.jl`     |
| `pop_growth_ensemble.jl` | Flood impact summaries for different agent pop growth rates      | `julia workflow/toy_model/pop_growth_ensemble.jl` |
| `factor_map_cluster.jl`  | Script to run Sobol Sensitivity Analysis on toy model parameters | `sbatch factor_map_cluster.sh`                    |

To re-simulate CHANCE-C experiments (`CHANCE_C`):

| Script Name                | Description                                           | How to Run                                       |
| -------------------------- | ----------------------------------------------------- | ------------------------------------------------ |
| `chance_c_ensemble.jl`   | run ABM scenario ensembles and collect evolution data | `julia workflow/CHANCE_C/chance_c_ensemble.jl` |
| `damage_ensemble.jl`     | Calculate flood damages across surge events           | `julia workflow/chance_C/damage_ensemble.jl`   |
| `damage_fixed_effect.jl` |                                                       | `sbatch damage_fixed_effect.sh`                |

## Reproduce paper figures

1. Run the relevant simulations above or use the results from the `dataframes/` folder. The necessary data inputs are automatically loaded for you in each plot script file.
2. Run the following scripts for each of the figures

| Figure         | Script name              | How to Run                                        | Output File                                                           |
| -------------- | ------------------------ | ------------------------------------------------- | --------------------------------------------------------------------- |
| Figure 2       | `model_landscape.jl`   | `julia workflow/toy_model/model_landscape.jl`   | `figures/model_landscape.png`                                       |
| Figure 3       | `plot_abm_ensemble.jl` | `julia workflow/toy_model/model_landscape.jl`   | `figures/abm_ensemble.png`                                          |
| Figure 4       | `plot_breach_shape.jl` | `julia workflow/toy_model/plot_breach_shape.jl` | `figures/risk_shifting.png`                                         |
| Figure 5       | `SA_visualize.jl`      | `julia workflow/toy_model/SA_visualize.jl`      | `figures/first_order_100.png`                                       |
| Figure 6       | `plot_pop_growth.jl`   | `julia workflow/toy_model/plot_pop_growth.jl`   | `figures/pop_growth.png`                                            |
| Figure 7       | `plot_risk_shift.jl`   | `julia workflow/CHANCE_C/plot_risk_shift.jl`    | `figures/balt_rs.png`                                               |
| Figure 8       | `tbd`                  | `tbd`                                           | `figures/`                                                          |
| Figures A1, A2 | `RA_curves.jl`         | `julia workflow/toy_model/RA_curves.jl`         | A1:`figures/log_func.png` <br />A2: `figures/log_func_scale.png` |
| Figure A3      | `breach_curves.jl`     | `julia workflow/toy_model/plot_pop_growth.jl`   | `figures/breach_func.png`                                           |
| Figure A4      | `tbd`                  | `tbd`                                           | `figures/`                                                          |
| Figure A5      | `tbd`                  | `tbd`                                           | `figures/`                                                          |
