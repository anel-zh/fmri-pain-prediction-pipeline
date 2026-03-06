%% Script Remarks
% Example script for the data extraction for Schaefer 265 ROI brain atlas and individual dataset
% Goal: 
%     - Dataset: MPC-1 (individual)
%     - Atlas: Schaefer_265 
%     - Extracting brain features for personalized and population models

%% Content
% 1. Loading directories and configuration structure.
% 2. Denoising, getting activation (HRF voxel) and connectivity (DCC) measures.

clc
clear
%% 1. Loading details by case 
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset); 

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    

%% Preprocessing
participants_option = 'main';
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel', 'DCC'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix);


