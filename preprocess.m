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
    % save to subject's preprocessed folder
    writetable(cleanMergedTable, strcat(preprocessedDataPath, '/', ...
        subject, '/preprocessedPart3.csv'))
end 