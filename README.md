
# Bhaduri-etal_inprep

**Uncertainty in Household Behavior Drives Large Variation in the Size of the Levee Effect**

 Parin Bhaduri<sup>1*</sup>, Adam B. Pollack<sup>2</sup>, James Yoon<sup>3</sup>, Pranab K. Roy Chowdhury<sup>3</sup>, Heng Wan<sup>3</sup>, David Judi<sup>3</sup>, Brent Daniel<sup>3</sup>, Vivek Srikrishnan<sup>1</sup>

<sup>1</sup> Department of Biological & Environmental Engineering, Cornell University, Ithaca, New York, USA

<sup>2</sup> Thayer School of Engineering, Darthmouth College, Hanover, New Hampshire, USA

<sup>3</sup> Pacific Northwest National Laboratory, Richland, Washington, USA

\* corresponding author:  pbb62@cornell.edu

## Abstract

Coastal cities face increasing flood hazards due to climate change. Physical infrastructure, such as levees, are commonly used to reduce flood hazards. To effectively manage flood risks, it is important to understand the degree to which physical infrastructure changes both hazard and exposure. For example, many studies suggest that levee construction causes an overall increase in risk because levees promote exposure growth to a greater degree than they reduce flood hazards. Although this so-called “levee effect” is widely studied, there are knowledge gaps surrounding how uncertainties related to levee construction and flood risk translate into the occurrence and strength of the levee effect in coastal communities. Here, we use agent-based modeling to simulate the dynamics surrounding the levee effect, first under idealized conditions and finally within a real-world coastal environment. We find that the size of the levee effect is highly sensitive to household behavior (e.g., risk aversion), economic factors (e.g., population growth), and engineering (e.g., levee failure). We also observe circumstances where the levee effect does not occur at all under certain model parameterizations. Overall, our findings emphasize the importance of providing reliable flood risk information to promote sustainable development in coastal communities.

## Acknowledgements

This research is supported by the Multisector Dynamics (MSD) program areas of the U.S. Department of Energy, Office of Science as part of the multi-program, collaborative Integrated Coastal Modeling (ICoM) project.

## Journal reference

Link to preprint: [https://doi.org/10.31219/osf.io/9ejn8](https://doi.org/10.31219/osf.io/9ejn8) 

## Data reference

### Input data

Input data for Baltimore used during the CHANCE-C model simulations can be found under `model_inputs/` in the following [data repository](https://github.com/parinbhaduri/baltimore-data). For input data to be read in properly for simulation runs, make sure that the data repository is cloned to the same location as this repository.

### Output data

Output data can be found in the `dataframes/` folder in each experiment folder (`workflow/[MODEL]/dataframes`). These include CSV files for the ABM scenario realizations and the flood impact/damage estimates for both the idealized, toy model experiment (`worflow/toy_model/`), and the Baltimore experiment using CHANCE-C (`workflow/CHANCE_C`).

## Dependencies

This code is based on Julia 1.7. Relevant dependencies are in the `Project.toml` and `Manifest.toml` files (the `Manifest.jl` specifies the particular versions; this file should be kept as-is for perfect reproducibility but may need to be deleted and rebuilt with `Pkg.instantiate()` for different Julia versions).

## Contributing modeling software

We used two models to conduct our experiments:  a stylized ABM created for a synthetic environment (`flood-risk_abm`), and an existing ABM package (`CHANCE-C `) for our Baltimore Case-Study. We use the dynamic version of CHANCE-C (`dynamice_FF` branch) to incorporate repeated flood events in our ABM simulations.

| Model              | Version | Repository Link                                                |
| ------------------ | ------- | -------------------------------------------------------------- |
| `flood-risk-abm` | -       | https://github.com/parinbhaduri/flood-risk-abm                 |
| `CHANCE-C`       | 1.1.0   | https://github.com/srikrishnan-lab/CHANCE_C.jl/tree/dynamic_FF |

Running the experiments in `toy_model/` requires cloning the `flood-risk-abm` repository. To use the toy model, clone the `flood_risk-abm` repository to the same location as this repository. As long as the repository is in the correct location, the relevant workflow scripts should be able to import the necessary functions required to run the idealized experiments.

The CHANCE-C package is already listed in the `Project.toml` file and should automatically downloaded once the project environment is built. If CHANCE-C is unable to be imported or precompiled when running the Baltimore experiments, the package can be added to the project environment again using the following command:

```julia
import Pkg
Pkg.add("https://github.com/srikrishnan-lab/CHANCE_C.jl#dynamic_FF")
```

We construct and execute both models using Agents.jl [v5.14](https://juliadynamics.github.io/Agents.jl/v5.14/). These models are incompatible with Agents.jl v6.0 or later.

## Reproduction

This section consists of a walkthrough of how to reproduce the analysis conducted in both the Idealized and Baltimore Experiment.

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
3. Two scripts in the working directory (`SA_cluster.sh` and `scenario_discovery.sh`) were written to be run in the Hopper HPC environment using the SLURM Task Manager.

To re-simulate the Idealized experiments (`toy_model/`):

| Script Name                | Description                                                                                                         | How to Run                                          |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------- |
| `abm_ensemble.jl`        | run ABM scenario ensembles and collect evolution data                                                               | `julia workflow/toy_model/abm_ensemble.jl`        |
| `breach_ensemble.jl`     | Flood Impact summaries for different levee breach likelihoods                                                       | `julia workflow/toy_model/breach_ensemble.jl`     |
| `pop_growth_ensemble.jl` | Flood impact summaries for different agent pop growth rates                                                         | `julia workflow/toy_model/pop_growth_ensemble.jl` |
| `SA_cluster.sh`          | Script to construct the exploratory model ensemble for the<br />Sobol Sensitivity Analysis on toy model parameters | `sbatch factor_map_cluster.sh`                    |

To re-simulate CHANCE-C experiments (`CHANCE_C`):

| Script Name               | Description                                                                                                          | How to Run                                       |
| ------------------------- | -------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| `chance_c_ensemble.jl`  | run ABM scenario ensembles and collect evolution data                                                                | `julia workflow/CHANCE_C/chance_c_ensemble.jl` |
| `damage_ensemble.jl`    | Calculate flood damages across surge events                                                                          | `julia workflow/CHANCE_C/damage_ensemble.jl`   |
| `scenario_discovery.sh` | Script to construct the exploratory model ensemble for the<br /> Scenario Discovery Analysis on CHANCE-C parameters | `sbatch scenario_discovery.sh`                 |

## Reproduce paper figures

1. Run the relevant simulations above or use the results from the `dataframes/` folder. The necessary data inputs are automatically loaded for you in each plot script file.
2. Run the following scripts for each of the figures:

| Figure         | Script name               | How to Run                                                  | Output File                                                               |
| -------------- | ------------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------- |
| Figure 2       | `plot_abm_evolution.jl` | `julia scripts/plot_abm_evolution.jl`                     | `figures/abm_response.png`                                              |
| Figure 3       | `plot_risk_shift.jl`    | `julia scripts/plot_abm_evolution.jl `                    | `figures/risk_transference.png`                                         |
| Figure 4       | `SA_visualize.jl`       | `julia scripts/SA_visualize.jl`                           | `figures/SA_visualize.png`                                              |
| Figures A1, A2 | `RA_curves.jl`          | `julia workflow/toy_model/RA_curves.jl`                   | A1:`figures/log_func.png` <br />A2: `figures/log_func_scale.png`     |
| Figure A3      | `breach_curves.jl`      | `julia workflow/toy_model/plot_pop_growth.jl`             | `figures/breach_func.png`                                               |
| Figure A4      | `model_landscape.jl`    | `julia workflow/toy_model/model_landscape.jl`             | `figures/model_landscape.png`                                           |
| Figure A5      | `plot_breach_shape.jl`  | `julia workflow/toy_model/plot_breach_shape.jl`           | `figures/risk_shift_breach.ppng`                                        |
| Figure A6      | `plot_pop_growth.jl`    | `julia workflow/toy_model/plot_pop_growth.jl`             | `figures/pop_growth.png`                                                |
| Figure A7, A8  | `surge_properties.jl`   | `julia workflow/CHANCE_C/surge_properties.jl`             | A7:`figures/ret_level_plt.png`<br />A8:`figures/surge_interval.png`   |
| Figure A9*     | `flood_visual.ipynb`    | `baltimore-data/pre_processing/python/flood-visual.ipynb` | `baltimore-data/figures/`                                               |
| Figure A10     | `plot_ensemble.jl`      | `julia workflow/CHANCE_C/plot_ensemble.jl`                | `figures/chance_c_ensemble_city.png`                                    |
| Figure A11     | `plot_pop_density.jl`   | `julia workflow/CHANCE_C/plot_pop_density.jl`             | `figures/final_pop_dens.png`                                            |
| Figure A12*    | `CART_visual.jl`        | `julia scripts/CART_visual.jl`                            | `figures/dec_tree_notransfer.png`<br />`figures/dec_tree_extreme.png` |

* Figure A9 was constructed within the data repository. For details on how to reconstruct this figure, please refer to the [data repository](https://github.com/parinbhaduri/baltimore-data).
* Figure 5 and Figure A12 are based on the classification trees constructed in `CART_visual.jl.`These raw outputs were then used to create more presentable and interpretable figures. The original outputs are found in the `figures/` folder.
