# Ultra Instinct Modelling

## Introduction
Ultra Instinct is a project from Salomon Lab in the University Of Haifa, Israel.
The project aims to investigate the effects of combinations of various levels of different modalities (temporal alteration, and spatial alteration) on the subjective Sense of Agency.
The Ultra Instinct Modelling repository defines a couple of numerical models to help understand the interplay between the two modalities.
The modeling is done in the MATLAB programming language with the BADS optimizer using negative log-likelihood objective function. 

## Prerequisites
Installation of the BADS optimizer: https://github.com/acerbilab/bads

## Repository Structure
### params.m
Parameter file of paths to be used by the preprocess.m and modelling.m scripts. Includes "dataPath", "preprocessedDataPath", and "predictionsOutputPath" which should point to the folder where the raw data is stored, the folder where we want the preprocessed output, and the folder where we want the predictions output, respectively.

### preprocess.m
This script takes the raw data from "dataPath", preprocess it, and output the preprocessed data to "preprocessedDataPath". Running this file is necessary before continuating to the modelling.m script. This script is using the params.m parameter file.

### modelling.m
This script takes the preprocessed data from "preprocessedDataPath", defines the wanted models and fit the models parameters for each subjects. The output of the models parameters and negative log-likelihood is stored to "predictionsOutputPath". This script is using the params.m parameter file.

## Instructions
When running for the first time:
1) Create the data folder and put the raw data with the same convention it was saved in the Lab drive where each subject has a folder.
2) Go over the params.m parameter file and make sure the values are as wanted.
3) Run preprocess.m to preprocess the raw data.
4) Run modelling.m.

> [!NOTE]
> The process of fitting ~10 models to ~16 subjects can take a few hours on a regular laptop. :+1:

