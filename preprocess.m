%% clean env
clc
clear all
close all
%% change working directory to script directory
cd(fileparts(matlab.desktop.editor.getActiveFilename));
%% load parameters files
params
%% folder creation 
% create the folder for preprocessed data if does not exist.
if ~exist(preprocessedDataPath, 'dir')
    mkdir(preprocessedDataPath)
end

% create the folder for each subject's preprocessed data if does not exist.
subjects = dir(strcat(dataPath, '/Sub*'));
for subjectNum = 1:numel(subjects)
    subject = subjects(subjectNum).name;
    if ~exist(strcat(preprocessedDataPath, '/', subject), 'dir')
        mkdir(strcat(preprocessedDataPath, '/', subject))
    end 
end 
%% read, merge, extract, save 
subjects = dir(strcat(dataPath, '/Sub*'));
for subjectNum = 1:numel(subjects)
    subject = subjects(subjectNum).name;
    subjectsDataPath = strcat(dataPath, '/', subject, '/Part3/');
    subjectsDataPath = strcat(subjectsDataPath, ...
        dir(strcat(subjectsDataPath, 'Sub*')).name, '/');
    
    % read subject's answers file
    answersFilePath = strcat(subjectsDataPath, ...
        dir(strcat(subjectsDataPath, '/Answers*')).name);
    answers = readtable(answersFilePath);
    
    % read subject's trials file
    trialsFilePath = strcat(subjectsDataPath, 'UsedPlan/', ...
        dir(strcat(subjectsDataPath, 'UsedPlan/Trials*')).name);
    trials = readtable(trialsFilePath);
    
    % merge answers and trials files
    trials = renamevars(trials, 'x_trialNumber', 'TrialNumber');
    trials = trials(trials.TrialNumber > 0, :);
    answers = answers(answers.TrialNumber > 0, :);
    mergedTable = innerjoin(trials, answers, 'Keys', 'TrialNumber');
    
    % extract necessary columns for modeling
    cleanMergedTable = mergedTable(:, {'TrialNumber', 'SensoMotoricDelay', ...
        'angleChange', 'QuestionResult'});
    
    % compute additional columns
    t_valueMapping = [0, 0.05, 0.072, 0.094];
    t_valueMappingValues = [1, 2, 3, 4];
    s_valueMapping = [0, 0.1583, -0.1583, 0.2125, -0.2125, 0.2679, -0.2679];
    s_valueMappingValues = [5, 6, 6, 7, 7, 8, 8];
    cleanMergedTable.tParamVal = zeros(size(cleanMergedTable, 1), 1);
    cleanMergedTable.sParamVal = zeros(size(cleanMergedTable, 1), 1);
    for i = 1:numel(t_valueMapping)
        idx = (cleanMergedTable.SensoMotoricDelay == t_valueMapping(i));
        cleanMergedTable.tParamVal(idx) = t_valueMappingValues(i);
    end
    for i = 1:numel(s_valueMapping)
        idx = (cleanMergedTable.angleChange == s_valueMapping(i));
        cleanMergedTable.sParamVal(idx) = s_valueMappingValues(i);
    end
    
    % save to subject's preprocessed folder
    writetable(cleanMergedTable, strcat(preprocessedDataPath, '/', ...
        subject, '/preprocessedPart3.csv'))
end 