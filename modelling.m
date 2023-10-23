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
mulConstStruct = struct;
mulStruct = struct;
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
    % Negative Log Likelihood
    objective = @(params) -mean((results .* log(multiplicative(params, ...
        [tParamVal, sParamVal]) + 1e-10)) + ((1 - results) .* ...
        log(1 - multiplicative(params, [tParamVal, sParamVal]) + 1e-10))); 
    %objective = @(params) sum((multiplicative(params, ...
        %[tParamVal, sParamVal]) - results).^2);

    % Define the constraint function
    % The constraint enforces the following order:
    % params(1) > params(2) > params(3) > params(4)
    % params(5) > params(6) > params(7) > params(8)
    constraint = @(params) [params(1) - params(2), params(2) - params(3), ...
        params(3) - params(4), params(5) - params(6), ...
        params(6) - params(7), params(7) - params(8)];

    % Combine the objective function and the constraint using a penalty method
    penalized_objective = @(params) objective(params) + ...
        sum(min(0, constraint(params)).^2);

    % t1, t2, t3, t4, s1, s2, s3, s4 
    x0 = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5];        % Starting point
    lb = [0 0 0 0 0 0 0 0];                        % Lower bounds
    ub = [1 1 1 1 1 1 1 1];                        % Upper bounds
    %plb = [0.7 0.55 0.4 0.2 0.7 0.55 0.4 0.2];    % Plausible lower bounds
    %pub = [1 0.8 0.65 0.5 1 0.8 0.65 0.5];        % Plausible upper bounds
    
    % multiplicative model
    [mul_fit, mul_fval] = bads(objective, x0, lb, ub);
    mulStruct.(subject) = [mul_fit, mul_fval];
    save(strcat(predictionsOutputPath, '/', 'mul_pred.mat'), ...
        '-struct', 'mulStruct')

    % multiplicative with constraint model
    [mulConst_fit, mulConst_fval] = bads(penalized_objective, x0, lb, ub);
    mulConstStruct.(subject) = [mulConst_fit, mulConst_fval];
    save(strcat(predictionsOutputPath, '/', 'mulConst_pred.mat'), ...
        '-struct', 'mulConstStruct');
end

% Next time, try to play with plb and pub. Also, the objective function.