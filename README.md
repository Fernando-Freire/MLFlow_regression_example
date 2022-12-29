# MLflow Recipes Examples
This repository contains example projects for the
[MLflow Recipes](https://mlflow.org/docs/latest/recipes.html) (previously known as MLflow Pipelines).
To learn about specific recipe,
follow the [installation instructions](#installation-instructions) below to install all necessary packages,
then checkout the relevant example projects listed [here](#example-projects).

**Note**: This example repo is intended for first-time MLflow Recipes users to learn
its fundamental concepts and workflows.
For users already familiar with MLflow Recipes, find a template repository
to solve a specific ML problem. For example, for regression problem, use
[recipes-regression-template](https://github.com/mlflow/recipes-regression-template) instead.

**Note**: [MLflow Recipes](https://mlflow.org/docs/latest/recipes.html)
is an experimental feature in [MLflow](https://mlflow.org).
If you observe any issues,
please report them [here](https://github.com/mlflow/mlflow/issues).
For suggestions on improvements,
please file a discussion topic [here](https://github.com/mlflow/mlflow/discussions).
Your contribution to MLflow Recipes is greatly appreciated by the community!

## Example Projects
- [**Regression**: NYC taxi fare prediction](regression/README.md)

## Installation instructions
To use MLflow Recipes in this example repository,
simply install the packages listed in the `requirements.txt` file. Note that `Python 3.8` or above is required.
```
pip install -r requirements.txt
```

You may need to install additional libraries for extra features:
- [Hyperopt](https://pypi.org/project/hyperopt/)  is required for hyperparameter tuning.
- [PySpark](https://pypi.org/project/pyspark/)  is required for distributed training or to ingest Spark tables.
- [Delta](https://pypi.org/project/delta-spark/) is required to ingest Delta tables.
These libraries are available natively in the [Databricks Runtime for Machine Learning](https://docs.databricks.com/runtime/mlruntime.html).

## Log to the designated MLflow Experiment
To log recipe runs to a particular MLflow experiment:
1. Open `profiles/databricks.yaml` or `profiles/local.yaml`, depending on your environment.
2. Edit (and uncomment, if necessary) the `experiment` section, specifying the name of the
   desired experiment for logging.


### Accessing MLflow recipe Runs
You can find MLflow Experiments and MLflow Runs created by the recipe on the
[Databricks ML Experiments page](https://docs.databricks.com/applications/machine-learning/experiments-page.html#experiments).

## Development Environment -- Local machine
### Jupyter

1. Launch the Jupyter Notebook environment via the `jupyter notebook` command.
2. Open and run the `notebooks/jupyter.ipynb` notebook in the Jupyter environment.

**Note**: data profiles display in step cards are not visually compatible with dark theme.
Please avoid using the dark theme if possible.

### Command-Line Interface (CLI)

First, enter the corresponding example root directory and set the profile via environment variable.
For example, for the regression example project,
```
cd regression
```
```
export MLFLOW_RECIPES_PROFILE=local
```

Then, try running the
following [MLflow Recipes CLI](https://mlflow.org/docs/latest/cli.html#mlflow-recipes)
commands to get started.
Note that the `--step` argument is optional.
Recipe commands without a `--step` specified act on the entire recipe instead.

Available step names are: `ingest`, `split`, `transform`, `train`, `evaluate` and `register`.

- Display the help message:
```
mlflow recipes --help
```

- Run a recipe step or the entire recipe:
```
mlflow recipes run --step step_name
```

- Inspect a step card or the recipe dependency graph:
```
mlflow recipes inspect --step step_name
```

- Clean a step cache or all step caches:
```
mlflow recipes clean --step step_name
```

### Accessing MLflow Recipe Runs
To view MLflow Experiments and MLflow Runs created by the recipe:

1. Enter the example root directory, for example: `cd regression`

2. Start the MLflow UI

```sh
mlflow ui \
   --backend-store-uri sqlite:///metadata/mlflow/mlruns.db \
   --default-artifact-root ./metadata/mlflow/mlartifacts \
   --host localhost
```


# Predict the NYC taxi fare with an ML regressor
This is the root directory for an example project for the
[MLflow Regression Recipe](https://mlflow.org/docs/latest/recipes.html#regression-recipe).
Follow the instructions [here](../README.md) to set up your environment first,
then use this directory to create a linear regressor and evaluate its performance,
all out of box!

In this example, we demonstrate how to use MLflow Recipes
to predict the fare amount for a taxi ride in New York City,
given the pickup and dropoff locations, trip duration and distance etc.
The original data was published by the [NYC gov](https://www1.nyc.gov/site/tlc/about/tlc-trip-record-data.page).

In this [notebook](notebooks/jupyter.ipynb) ([the Databricks version](notebooks/databricks.py)),
we show how to build and evaluate a very simple linear regressor step by step,
following the best practices of machine learning engineering.
By the end of this example,
you will learn how to use MLflow Recipes to
- Ingest the raw source data.
- Splits the dataset into training/validation/test.
- Create a feature transformer and transform the dataset.
- Train a linear model (regressor) to predict the taxi fare.
- Evaluate the trained model, and improve it by iterating through the `transform` and `train` steps.
- Register the model for production inference.

All of these can be done with Jupyter notebook or on the Databricks environment.
Finally, challenge yourself to build a better model. Try the following:
- Find a better data source with more training data and more raw feature columns.
- Clean the dataset to make it less noisy.
- Find better feature transformations.
- Fine tune the hyperparameters of the model.