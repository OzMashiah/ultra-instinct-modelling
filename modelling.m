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

    % for multiple random start points (x0):
    % nvars = numel(PLB);
    % X0 = PLB + rand(1,nvars) .* (PUB - PLB);
    
    % t1, t2, t3, t4, s1, s2, s3, s4 
    % This is the setup for models that fit 8 parameters.
    lb_8 = [0 0 0 0 0 0 0 0];                      % Lower bounds
    ub_8 = [1 1 1 1 1 1 1 1];                      % Upper bounds
    x0_8 = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5];      % Starting point #1
    x1_8 = [0.8 0.6 0.4 0.2 0.8 0.6 0.4 0.2];      % Starting point #2
    x2_8 = [1 1 1 1 1 1 1 1];                      % Starting point #3
    x3_8 = [0 0 0 0 0 0 0 0];                      % Starting point #4

    % t1/s1, t2/s2, t3/s3, t4/s4 
    % This is the setup for models that fit 4 parameters.
    lb_4 = [0 0 0 0];                              % Lower bounds
    ub_4 = [1 1 1 1];                              % Upper bounds
    x0_4 = [0.5 0.5 0.5 0.5];                      % Starting point #1
    x1_4 = [0.8 0.6 0.4 0.2];                      % Starting point #2
    x2_4 = [1 1 1 1];                              % Starting point #3
    x3_4 = [0 0 0 0];                              % Starting point #4
    
    % null model
    [null_fit, null_fval] = bads(objective_null, x0_8, lb_8, ub_8);
    nullStruct.(subject) = [mean(results), null_fval];

    % multiplicative model for each starting point
    [mul_fit_0, mul_fval_0] = bads(objective_mul, x0_8, lb_8, ub_8);
    [mul_fit_1, mul_fval_1] = bads(objective_mul, x1_8, lb_8, ub_8);
    [mul_fit_2, mul_fval_2] = bads(objective_mul, x2_8, lb_8, ub_8);
    [mul_fit_3, mul_fval_3] = bads(objective_mul, x3_8, lb_8, ub_8);
    best_fit_fval = lowestFVAL([mul_fit_0, mul_fval_0], ...
        [mul_fit_1, mul_fval_1], [mul_fit_2, mul_fval_2], ...
        [mul_fit_3, mul_fval_3]);
    mulStruct.(subject) = best_fit_fval;

    % multiplicative with constraint model for each starting point
    [mulConst_fit_0, mulConst_fval_0] = bads(objective_mul, x0_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [mulConst_fit_1, mulConst_fval_1] = bads(objective_mul, x1_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [mulConst_fit_2, mulConst_fval_2] = bads(objective_mul, x2_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [mulConst_fit_3, mulConst_fval_3] = bads(objective_mul, x3_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    best_fit_fval = lowestFVAL([mulConst_fit_0, mulConst_fval_0], ...
        [mulConst_fit_1, mulConst_fval_1], ...
        [mulConst_fit_2, mulConst_fval_2], ...
        [mulConst_fit_3, mulConst_fval_3]);
    mulConstStruct.(subject) = best_fit_fval;
    
    % minimum model for each starting point
    [min_fit_0, min_fval_0] = bads(objective_min, x0_8, lb_8, ub_8);
    [min_fit_1, min_fval_1] = bads(objective_min, x1_8, lb_8, ub_8);
    [min_fit_2, min_fval_2] = bads(objective_min, x2_8, lb_8, ub_8);
    [min_fit_3, min_fval_3] = bads(objective_min, x3_8, lb_8, ub_8);
    best_fit_fval = lowestFVAL([min_fit_0, min_fval_0], ...
        [min_fit_1, min_fval_1], [min_fit_2, min_fval_2], ...
        [min_fit_3, min_fval_3]);
    minStruct.(subject) = best_fit_fval;

    % minimum with constraint model for each starting point
    [minConst_fit_0, minConst_fval_0] = bads(objective_min, x0_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [minConst_fit_1, minConst_fval_1] = bads(objective_min, x1_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [minConst_fit_2, minConst_fval_2] = bads(objective_min, x2_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [minConst_fit_3, minConst_fval_3] = bads(objective_min, x3_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    best_fit_fval = lowestFVAL([minConst_fit_0, minConst_fval_0], ...
        [minConst_fit_1, minConst_fval_1], ...
        [minConst_fit_2, minConst_fval_2], ...
        [minConst_fit_3, minConst_fval_3]);
    minConstStruct.(subject) = best_fit_fval;

    % meanimum model for each starting point
    [mean_fit_0, mean_fval_0] = bads(objective_mean, x0_8, lb_8, ub_8);
    [mean_fit_1, mean_fval_1] = bads(objective_mean, x1_8, lb_8, ub_8);
    [mean_fit_2, mean_fval_2] = bads(objective_mean, x2_8, lb_8, ub_8);
    [mean_fit_3, mean_fval_3] = bads(objective_mean, x3_8, lb_8, ub_8);
    best_fit_fval = lowestFVAL([mean_fit_0, mean_fval_0], ...
        [mean_fit_1, mean_fval_1], [mean_fit_2, mean_fval_2], ...
        [mean_fit_3, mean_fval_3]);
    meanStruct.(subject) = best_fit_fval;

    % meanimum with constraint model for each starting point
    [meanConst_fit_0, meanConst_fval_0] = bads(objective_mean, x0_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [meanConst_fit_1, meanConst_fval_1] = bads(objective_mean, x1_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [meanConst_fit_2, meanConst_fval_2] = bads(objective_mean, x2_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    [meanConst_fit_3, meanConst_fval_3] = bads(objective_mean, x3_8, lb_8, ...
        ub_8, [], [], nonbcon_8);
    best_fit_fval = lowestFVAL([meanConst_fit_0, meanConst_fval_0], ...
        [meanConst_fit_1, meanConst_fval_1], ...
        [meanConst_fit_2, meanConst_fval_2], ...
        [meanConst_fit_3, meanConst_fval_3]);
    meanConstStruct.(subject) = best_fit_fval;

    % temporal-only model for each starting point
    [tOnly_fit_0, tOnly_fval_0] = bads(objective_t_only, x0_4, lb_4, ub_4);
    [tOnly_fit_1, tOnly_fval_1] = bads(objective_t_only, x1_4, lb_4, ub_4);
    [tOnly_fit_2, tOnly_fval_2] = bads(objective_t_only, x2_4, lb_4, ub_4);
    [tOnly_fit_3, tOnly_fval_3] = bads(objective_t_only, x3_4, lb_4, ub_4);
    best_fit_fval = lowestFVAL([tOnly_fit_0, tOnly_fval_0], ...
        [tOnly_fit_1, tOnly_fval_1], [tOnly_fit_2, tOnly_fval_2], ...
        [tOnly_fit_3, tOnly_fval_3]);
    tOnlyStruct.(subject) = best_fit_fval;

    % temporal-only with constraint model for each starting point
    [tOnlyConst_fit_0, tOnlyConst_fval_0] = bads(objective_t_only, x0_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    [tOnlyConst_fit_1, tOnlyConst_fval_1] = bads(objective_t_only, x1_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    [tOnlyConst_fit_2, tOnlyConst_fval_2] = bads(objective_t_only, x2_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    [tOnlyConst_fit_3, tOnlyConst_fval_3] = bads(objective_t_only, x3_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    best_fit_fval = lowestFVAL([tOnlyConst_fit_0, tOnlyConst_fval_0], ...
        [tOnlyConst_fit_1, tOnlyConst_fval_1], ...
        [tOnlyConst_fit_2, tOnlyConst_fval_2], ...
        [tOnlyConst_fit_3, tOnlyConst_fval_3]);
    tOnlyConstStruct.(subject) = best_fit_fval;
    
    % spatial-only model for each starting point
    [sOnly_fit_0, sOnly_fval_0] = bads(objective_s_only, x0_4, lb_4, ub_4);
    [sOnly_fit_1, sOnly_fval_1] = bads(objective_s_only, x1_4, lb_4, ub_4);
    [sOnly_fit_2, sOnly_fval_2] = bads(objective_s_only, x2_4, lb_4, ub_4);
    [sOnly_fit_3, sOnly_fval_3] = bads(objective_s_only, x3_4, lb_4, ub_4);
    best_fit_fval = lowestFVAL([sOnly_fit_0, sOnly_fval_0], ...
        [sOnly_fit_1, sOnly_fval_1], [sOnly_fit_2, sOnly_fval_2], ...
        [sOnly_fit_3, sOnly_fval_3]);
    sOnlyStruct.(subject) = best_fit_fval;
    
    % spatial-only with constraint model for each starting point
    [sOnlyConst_fit_0, sOnlyConst_fval_0] = bads(objective_s_only, x0_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    [sOnlyConst_fit_1, sOnlyConst_fval_1] = bads(objective_s_only, x1_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    [sOnlyConst_fit_2, sOnlyConst_fval_2] = bads(objective_s_only, x2_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    [sOnlyConst_fit_3, sOnlyConst_fval_3] = bads(objective_s_only, x3_4, lb_4, ...
        ub_4, [], [], nonbcon_4);
    best_fit_fval = lowestFVAL([sOnlyConst_fit_0, sOnlyConst_fval_0], ...
        [sOnlyConst_fit_1, sOnlyConst_fval_1], ...
        [sOnlyConst_fit_2, sOnlyConst_fval_2], ...
        [sOnlyConst_fit_3, sOnlyConst_fval_3]);
    sOnlyConstStruct.(subject) = best_fit_fval;
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

%% Weighted Product Model Attemp
subjects = dir(strcat(preprocessedDataPath, '/Sub*'));
weightStruct = struct; % weighted product model.
weightConstStruct = struct; % weighted product model with a constraint.

for subjectNum = 1:numel(subjects)
    subject = subjects(subjectNum).name;
    % load preprocessed data
    data = readtable(strcat(preprocessedDataPath, '/', subject, ...
        '/preprocessedPart3.csv'));
    % extract dataset columns to variables
    tParamVal = data.tParamVal;
    sParamVal = data.sParamVal;
    results = data.QuestionResult;

    % define model
    weightedProduct = @(params, x) (params(9).*(params(x(:,1))) .* ...
        (params(10) .* params(x(:,2))))';
    % define objective function
    objective_weight = @(params) -sum((results .* log(weightedProduct(params, ...
            [tParamVal, sParamVal]) + 1e-10)) + ((1 - results) .* ...
            log(1 - weightedProduct(params, [tParamVal, sParamVal]) + 1e-10)));
    % non-bound constraint the same as mentioned above
    nonbcon_8 = @(params) (params(:, 1) < params(:, 2)) | ...
            (params(:, 2) < params(:, 3)) | (params(:, 3) < params(:, 4)) | ...
            (params(:, 5) < params(:, 6)) | (params(:, 6) < params(:, 7)) | ...
            (params(:, 7) < params(:, 8));

    % BADS init variables
    % t1, t2, t3, t4, s1, s2, s3, s4, wTemporal, wSpatial 
    lb_10 = [0 0 0 0 0 0 0 0 0 0];                      % Lower bounds
    ub_10 = [1 1 1 1 1 1 1 1 1 1];                      % Upper bounds
    x0_10 = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5 0.5];  % Starting point #1 
    x1_10 = [0.8 0.6 0.4 0.2 0.8 0.6 0.4 0.2 0.9 0.9];  % Starting point #2
    x2_10 = [1 1 1 1 1 1 1 1 1 1];                      % Starting point #3
    x3_10 = [0 0 0 0 0 0 0 0 0 0];                      % Starting point #4

    % weighted product model for each starting point
    [weight_fit_0, weight_fval_0] = bads(objective_weight, x0_10, lb_10, ub_10);
    [weight_fit_1, weight_fval_1] = bads(objective_weight, x1_10, lb_10, ub_10);
    [weight_fit_2, weight_fval_2] = bads(objective_weight, x2_10, lb_10, ub_10);
    [weight_fit_3, weight_fval_3] = bads(objective_weight, x3_10, lb_10, ub_10);
    est_fit_fval = lowestFVAL([weight_fit_0, weight_fval_0], ...
        [weight_fit_1, weight_fval_1], [weight_fit_2, weight_fval_2], ...
        [weight_fit_3, weight_fval_3]);
    weightStruct.(subject) = best_fit_fval;

    % weighted product with constraint model for each starting point
    [weightConst_fit_0, weightConst_fval_0] = bads(objective_weight, x0_10, ...
        lb_10, ub_10, [], [], nonbcon_8);
    [weightConst_fit_1, weightConst_fval_1] = bads(objective_weight, x1_10, ...
        lb_10, ub_10, [], [], nonbcon_8);
    [weightConst_fit_2, weightConst_fval_2] = bads(objective_weight, x2_10, ...
        lb_10, ub_10, [], [], nonbcon_8);
    [weightConst_fit_3, weightConst_fval_3] = bads(objective_weight, x3_10, ...
        lb_10, ub_10, [], [], nonbcon_8);
    best_fit_fval = lowestFVAL([weightConst_fit_0, weightConst_fval_0], ...
        [weightConst_fit_1, weightConst_fval_1], ...
        [weightConst_fit_2, weightConst_fval_2], ...
        [weightConst_fit_3, weightConst_fval_3]);
    weightConstStruct.(subject) = best_fit_fval;
end
save(strcat(predictionsOutputPath, '/', 'weight_pred.mat'), ...
        '-struct', 'weightStruct')
save(strcat(predictionsOutputPath, '/', 'weightConst_pred.mat'), ...
        '-struct', 'weightConstStruct');
%% functions

function bestScore = lowestFVAL(arr1, arr2, arr3, arr4)
    % Find the minimum value among the last elements of the four arrays
    minLast = min([arr1(end), arr2(end), arr3(end), arr4(end)]);
    
    % Determine which array has the minimum value in its last position
    if minLast == arr1(end)
        bestScore = arr1;
    elseif minLast == arr2(end)
        bestScore = arr2;
    elseif minLast == arr3(end)
        bestScore = arr3;
    else
        bestScore = arr4;
    end
end
