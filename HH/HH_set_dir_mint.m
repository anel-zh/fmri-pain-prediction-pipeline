function HH_set_dir_mint(model_option, dataset_option, varargin)

%% Function: Setup 
% Author: Anel Zhunussova 
% Last Update: 11th October 2024 -> June 11th 2025 revised before project
% transfer, added option of setting base dir
% Details:
%     - Set-up of the directories based on the dataset and parcellations.

%% Input check
% Parcellation 
if strcmp(model_option, 'model01_Schaefer') || strcmp(model_option, 'model02_Fan')
    model = model_option;
else
    error('Model input is not correct.')
end

% Dataset
if strcmp(dataset_option, 'mpc_wani') || strcmp(dataset_option, 'mpc_100')
    dataset = dataset_option;
else
    error('Dataset input is not correct.')
end

%% Setting up directories
% Host
if ~isempty(varargin)
    base = varargin{1}; %% Jun11 2025 added
else
    [~, hostname] = system('hostname');
    if contains(hostname, 'node') || contains(hostname, 'docker')
        % base = '/home/anel/nas1/'; % Server
        base = '/media/nas01/'; % Server
    else
        base = '/Volumes/cocoanlab01/'; % MacBook
    end
end 

% Add directories only if they are not already on the path
add_custom_path([base 'projects/MINT/analysis/imaging/connectivity/functions']);
add_custom_path([base 'projects/MINT/analysis/behavioral/scripts/functions']);
add_custom_path([base 'projects/MINT/analysis/github']);

% Set directories
projectdir = [base 'projects/MINT/analysis/'];
if strcmp(dataset_option, 'mpc_wani')
    nasdir = [base 'data/MPC/MPC_wani/imaging/preprocessed/MNI_youngeun/preprocessed/'];
    %datdir = [base 'projects/MINT/data/MPC_wani/preprocessed'];
elseif strcmp(dataset_option, 'mpc_100')
    nasdir = [base 'data/MPC/MPC_100/imaging/preprocessed'];
end

behavioral_dir = [base 'projects/MINT/analysis/behavioral'];
basedir = fullfile(projectdir, ['imaging/connectivity/' model '_' dataset]);

% Assign variables to the base workspace
assignin('base', 'projectdir', projectdir);
assignin('base', 'nasdir', nasdir);
assignin('base', 'basedir', basedir);
assignin('base', 'behavioral_dir', behavioral_dir);
%assignin('base', 'datdir', datdir);


end

%% Helper function: add path
function add_custom_path(path)
    if ~contains(path, pathdef)
        addpath(genpath(path));
    end
end
