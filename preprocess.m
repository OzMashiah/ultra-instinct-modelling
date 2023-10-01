%% clean env
clc
clear all
close all
%% change working directory to script directory
cd(fileparts(matlab.desktop.editor.getActiveFilename));
%% load parameters files
params
%% 
if ~exist(preprocessedDataPath, 'dir')
    mkdir(preprocessedDataPath)
end

for subject = dir(dataPath + '/Sub*')'
    disp(preprocessedDataPath + '/' + string(subject.name))
    if ~exist(preprocessedDataPath + subject.name, 'dir')
        mkdir(preprocessedDataPath + subject.name)
    end 
end 