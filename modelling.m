%% clean env
clc
clear all
close all
%% change working directory to script directory
cd(fileparts(mfilename('fullpath')));
%% load parameters files
params
%% extract subject choice data
% test on subject 160
answersFilePath = dataPath + '/sub160/Part3/';
answersFilePath = answersFilePath + dir(answersFilePath + 'Sub*').name;
answersFilePath = answersFilePath + '/' + dir(answersFilePath + '/Answers*').name;
subject = readtable(answersFilePath);

% ^ first thing to do is acquire all the data in a simple csv.
% trial number, questionresult, temporallevel, spatiallevel.