%% clean env
clc
clear all
close all
%% change working directory to script directory
cd(fileparts(matlab.desktop.editor.getActiveFilename));
%% load parameters files
params
%% 
subjects = dir(strcat(preprocessedDataPath, '/Sub*'));
fittedParamsStruct = struct;
for subjectNum = 1:numel(subjects)
    subject = subjects(subjectNum).name;
    % load preprocessed data
    data = readtable(strcat(preprocessedDataPath, '/', subject, ...
        '/preprocessedPart3.csv'));
    % Extract columns from the dataset
    tParamVal = data.tParamVal;
    sParamVal = data.sParamVal;
    results = data.QuestionResult;

    % Define model
    multiplicative = @(params, x) params(x(1)) * params(x(2));

    %  Define the objective function
    objective = @(params) sum((multiplicative(params, [tParamVal, sParamVal]) - results).^2);

    % t1, t2, t3, t4, s1, s2, s3, s4
    x0 = [0 0 0 0 0 0 0 0];                     % Starting point
    lb = [0 0 0 0 0 0 0 0];                     % Lower bounds
    ub = [1 1 1 1 1 1 1 1];                     % Upper bounds
    plb = [0.5 0.4 0.3 0.1 0.5 0.4 0.3 0.1];    % Plausible lower bounds
    pub = [1 0.9 0.8 0.6 1 0.9 0.8 0.6];        % Plausible upper bounds

    params_fit = bads(objective, x0, lb, ub, plb, pub);
    fittedParamsStruct.(subject) = params_fit;
end

% Next time, try to play with plb and pub. Also, the objective function.