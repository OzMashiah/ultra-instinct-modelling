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

nullStruct = struct; % null model.
mulStruct = struct; % multiplicative model.
mulConstStruct = struct; % multiplicative model with a constraint.
minStruct = struct; % minimum model.
minConstStruct = struct; % minimum model with a constraint.
meanStruct = struct; % mean model.
meanConstStruct = struct; % mean model with a constraint.
tOnlyStruct = struct; % temporal-only model.
tOnlyConstStruct = struct; % temporal-only model with a constraint.
sOnlyStruct = struct; % spatial-only model.
sOnlyConstStruct = struct; % spatial-only model with a constraint.

for subjectNum = 1:numel(subjects)
    subject = subjects(subjectNum).name;
    disp(subject);
    % load preprocessed data
    data = readtable(strcat(preprocessedDataPath, '/', subject, ...
        '/preprocessedPart3.csv'));
    % extract dataset columns to variables
    tParamVal = data.tParamVal;
    sParamVal = data.sParamVal;
    results = data.QuestionResult;

    % Define model
    null = @(params, x) mean(results);
    multiplicative = @(params, x) (params(x(:,1)) .* params(x(:,2)))';
    minimum = @(params, x) (min(params(x(:,1)), params(x(:,2))))';
    meanimum = @(params, x) ((params(x(:, 1)) + params(x(:, 2))) / 2)';
    unimodal = @(params, x) (params(x(:,1)))';

    %  Define the objective function
    % Negative Log Likelihood
    objective_null = @(params) -sum((results .* log(null(params, ...
        [tParamVal, sParamVal]) + 1e-10)) + ((1 - results) .* ...
        log(1 - null(params, [tParamVal, sParamVal]) + 1e-10)));
    objective_mul = @(params) -sum((results .* log(multiplicative(params, ...
        [tParamVal, sParamVal]) + 1e-10)) + ((1 - results) .* ...
        log(1 - multiplicative(params, [tParamVal, sParamVal]) + 1e-10)));
    objective_min = @(params) -sum((results .* log(minimum(params, ...
        [tParamVal, sParamVal]) + 1e-10)) + ((1 - results) .* ...
        log(1 - minimum(params, [tParamVal, sParamVal]) + 1e-10)));
    objective_mean = @(params) -sum((results .* log(meanimum(params, ...
        [tParamVal, sParamVal]) + 1e-10)) + ((1 - results) .* ...
        log(1 - meanimum(params, [tParamVal, sParamVal]) + 1e-10)));
    objective_t_only = @(params) -sum((results .* log(unimodal(params, ...
        tParamVal) + 1e-10)) + ((1 - results) .* log(1 - unimodal(params, ...
        tParamVal) + 1e-10)));
    objective_s_only = @(params) -sum((results .* log(unimodal(params, ...
        sParamVal - 4) + 1e-10)) + ((1 - results) .* log(1 - unimodal(params, ...
        sParamVal - 4) + 1e-10)));

    % non-bound constraint for BADS NONBCON arguement
    % for models that fit 8 parameters
    % The constraint forces the following order:
    % params(1) >= params(2) >= params(3) >= params(4)
    % params(5) >= params(6) >= params(7) >= params(8)
    nonbcon_8 = @(params) (params(:, 1) < params(:, 2)) | ...
        (params(:, 2) < params(:, 3)) | (params(:, 3) < params(:, 4)) | ...
        (params(:, 5) < params(:, 6)) | (params(:, 6) < params(:, 7)) | ...
        (params(:, 7) < params(:, 8));
    % for models that fit 4 parameters
    % The constraint forces the following order:
    % params(1) >= params(2) >= params(3) >= params(4)
    nonbcon_4 = @(params) (params(:, 1) < params(:, 2)) | ...
        (params(:, 2) < params(:, 3)) | (params(:, 3) < params(:, 4));


    % t1, t2, t3, t4, s1, s2, s3, s4 
    % This is the setup for models that fit 8 parameters.
    x0_8 = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5];      % Starting point
    lb_8 = [0 0 0 0 0 0 0 0];                      % Lower bounds
    ub_8 = [1 1 1 1 1 1 1 1];                      % Upper bounds

    % t1/s1, t2/s2, t3/s3, t4/s4 
    % This is the setup for models that fit 4 parameters.
    x0_4 = [0.5 0.5 0.5 0.5];                      % Starting point
    lb_4 = [0 0 0 0];                              % Lower bounds
    ub_4 = [1 1 1 1];                              % Upper bounds

    % null model
    [null_fit, null_fval] = bads(objective_null, x0_8, lb_8, ub_8);
    nullStruct.(subject) = [mean(results), null_fval];

    % multiplicative model
    [mul_fit, mul_fval] = bads(objective_mul, x0_8, lb_8, ub_8);
    mulStruct.(subject) = [mul_fit, mul_fval];

    % multiplicative with constraint model
    [mulConst_fit, mulConst_fval] = bads(objective_mul, x0_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    mulConstStruct.(subject) = [mulConst_fit, mulConst_fval];
    
    % minimum model
    [min_fit, min_fval] = bads(objective_min, x0_8, lb_8, ub_8);
    minStruct.(subject) = [min_fit, min_fval];

    % minimum with constraint model
    [minConst_fit, minConst_fval] = bads(objective_min, x0_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    minConstStruct.(subject) = [minConst_fit, minConst_fval];

    % meanimum model
    [mean_fit, mean_fval] = bads(objective_mean, x0_8, lb_8, ub_8);
    meanStruct.(subject) = [mean_fit, mean_fval];

    % meanimum with constraint model
    [meanConst_fit, meanConst_fval] = bads(objective_mean, x0_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    meanConstStruct.(subject) = [meanConst_fit, meanConst_fval];

    % temporal-only model
    [tOnly_fit, tOnly_fval] = bads(objective_t_only, x0_4, lb_4, ub_4);
    tOnlyStruct.(subject) = [tOnly_fit, tOnly_fval];

    % temporal-only with constraint model
    [tOnlyConst_fit, tOnlyConst_fval] = bads(objective_t_only, x0_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    tOnlyConstStruct.(subject) = [tOnlyConst_fit, tOnlyConst_fval];
    
    % spatial-only model
    [sOnly_fit, sOnly_fval] = bads(objective_s_only, x0_4, lb_4, ub_4);
    sOnlyStruct.(subject) = [sOnly_fit, sOnly_fval];
    
    % spatial-only with constraint model
    [sOnlyConst_fit, sOnlyConst_fval] = bads(objective_s_only, x0_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    sOnlyConstStruct.(subject) = [sOnlyConst_fit, sOnlyConst_fval];
end

save(strcat(predictionsOutputPath, '/', 'null_pred.mat'), ...
        '-struct', 'nullStruct')
save(strcat(predictionsOutputPath, '/', 'mul_pred.mat'), ...
        '-struct', 'mulStruct')
save(strcat(predictionsOutputPath, '/', 'mulConst_pred.mat'), ...
        '-struct', 'mulConstStruct');
save(strcat(predictionsOutputPath, '/', 'min_pred.mat'), ...
        '-struct', 'minStruct')
save(strcat(predictionsOutputPath, '/', 'minConst_pred.mat'), ...
        '-struct', 'minConstStruct');
save(strcat(predictionsOutputPath, '/', 'mean_pred.mat'), ...
        '-struct', 'meanStruct')
save(strcat(predictionsOutputPath, '/', 'meanConst_pred.mat'), ...
        '-struct', 'meanConstStruct');
save(strcat(predictionsOutputPath, '/', 'tOnly_pred.mat'), ...
        '-struct', 'tOnlyStruct')
save(strcat(predictionsOutputPath, '/', 'tOnlyConst_pred.mat'), ...
        '-struct', 'tOnlyConstStruct');
save(strcat(predictionsOutputPath, '/', 'sOnly_pred.mat'), ...
        '-struct', 'sOnlyStruct')
save(strcat(predictionsOutputPath, '/', 'sOnlyConst_pred.mat'), ...
        '-struct', 'sOnlyConstStruct');
