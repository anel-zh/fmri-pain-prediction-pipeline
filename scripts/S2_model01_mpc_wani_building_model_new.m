%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 26th Oct 2024 -> 8th June 2025 rerun and double check
% Goal: 
%     - Dataset: MPC-Wani 
%     - Atlas: Schaefer_265. 
%     - Creating optimized file with saving binned and variance normalized data.
%     - Goal: prepare data and train, valid, test model. Main results are
%     from here.


%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';

% Directories 
HH_set_dir_mint(model, dataset);

% Config structure
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;

%% 1.2 Loading 
% Connectivity
connectivity_cell = mint_a2_load_predictors(config_structure, 'main', {'caps','rest'}, 'DCC'); % 1st row is caps, 2nd row is rest
connectivity = HH_match_durations_mpc_wani_mint(connectivity_cell, 'DCC_cut');

% Pattern Activation (Voxel)
hrf_voxel = mint_a2_load_predictors(config_structure, 'main', {'caps','rest'}, 'hrf_voxel');


%% 1.3 Preparing data 
% -- This part is dedicated to prepare a data for model training (binning,
% splitting, normalizing -> order of the normalizing and splitting can be
% changed based on the order the functions are run and input -> lower in comments) 


% --- Defining a dir were to save data for model development (can be used later)
savedir = fullfile(basedir, '/optimized_data_files/for_model_dev_diff_vn_step_final_ver'); % SW 
mkdir(savedir);

% --- Binning
% window_size_TR = 90;
window_size_TR = config_structure.binning_parameters.same_time_window.main.Window_size_TR;
binned_behavioral = MINT_prepare_data.bin_behavioral_data(config_structure, 'main', window_size_TR);

% -- Brain data 
brain.connectivity_caps = connectivity(1,:);
brain.connectivity_rest = connectivity(2,:);

brain.hrf_voxel_caps = hrf_voxel(1,:);
brain.hrf_voxel_rest = hrf_voxel(2,:);

% --- Splitting data into train,test, valid
split_data = MINT_prepare_data.divide_data_by_split(config_structure, brain, binned_behavioral);
save(fullfile(savedir, 'split_data_mpc_wani'), 'split_data', '-v7.3')

% --- Variance normalziation 
normType = "wholebrain";
[vn_split_data, std_all] = MINT_prepare_data.variance_normalize_after_split(split_data, normType);
save(fullfile(savedir, 'vn_split_data_mpc_wani'), 'vn_split_data', '-v7.3')
save(fullfile(savedir, 'std_all_mpc_wani'), 'std_all', '-v7.3')

% --- Binning connectivity 
fields = {'train','valid', 'test'};
for f = 1:length(fields)
    % Binning 
    current_dat = [vn_split_data.(fields{f}).connectivity_caps; vn_split_data.(fields{f}).connectivity_rest];
    current_binned_caps = MINT_prepare_data.bin_connectivity(current_dat, window_size_TR);
    
    % Updating structure
    [vn_split_data.(fields{f}).connectivity_caps, vn_split_data.(fields{f}).connectivity_rest] = deal(current_binned_caps.connectivity_caps, current_binned_caps.connectivity_rest);
end 
save(fullfile(savedir, 'vn_split_data_mpc_wani_binned_C'), 'vn_split_data', '-v7.3')

%% 1.3b Combining connectivity and activation
% [Can be rerun from here after loading saved vn_split_data data] 
activation_name = 'hrf_voxel'; % sometimes activation can be hrf_roi, boxcar_roi, etc. -> just the variable name
vn_split_data_final = MINT_prepare_data.combine_connectivity_and_activation(vn_split_data, activation_name); % adding a combined model input

config_structure.vn_split_data_final = vn_split_data_final; % updating config
%% Part 2 
% Model building 
% Getting testing performance
% Performance base
looping_param.performance_base = 'corr_y';
looping_param.PC_range_split = 20; % CHANGE TO 1 to hypertunne final model % SW

% Saving options
looping_param.PC_train_plots_save = [1, 21, 81, 101, 161];  % figures to save (random for myself, to see the pattern)
looping_param.PC_valid_plots_save = looping_param.PC_train_plots_save;
looping_param.save_testing_visualization = true;
looping_param.save_model_weights_stats = true;
looping_param.save_folder_name = '9Jun2025_final_model'; % the results will be saved in model_development_results folder % SW
looping_param.brain_measures = {'connectivity_and_hrf_voxel', 'connectivity', 'hrf_voxel'};
looping_param.additional_comments = 'Rerunning the model final time before project transfer to SW to double check the scripts and final model parameters. Varaince normalization: before binning for connectivity and after binning on activation.';

tic
results_structure = MINT_model_building.main_loop(config_structure, looping_param);
toc


%% Comments -> additional approach 
% binning connectivity and then applying variance normalization (not
% originally used approach, but tried to match the step of normalization for activation) 

% ===== results saved at: for_model_dev_matched_vn_step

% % --- Defining a dir were to save data for model development (can be used later)
% savedir = fullfile(basedir, '/optimized_data_files/for_model_dev_matched_vn_step');
% 
% % --- Binning
% % window_size_TR = 90;
% window_size_TR = config_structure.binning_parameters.same_time_window.main.Window_size_TR;
% 
% binned_behavioral = MINT_prepare_data.bin_behavioral_data(config_structure, window_size_TR);
% binned_brain = MINT_prepare_data.bin_connectivity(connectivity, window_size_TR);
% binned_brain.hrf_voxel_caps = hrf_voxel(1,:);
% binned_brain.hrf_voxel_rest = hrf_voxel(2,:);
% save(fullfile(savedir, 'binned_brain_mpc_wani'), 'binned_brain', '-v7.3')
% 
% % --- Splitting data into train,test, valid
% split_data = MINT_prepare_data.divide_data_by_split(config_structure, binned_brain, binned_behavioral);
% save(fullfile(savedir, 'split_data_mpc_wani'), 'split_data', '-v7.3')
% 
% % --- Variance normalziation 
% [vn_split_data, std_all] = MINT_prepare_data.variance_normalize_after_split(split_data);
% save(fullfile(savedir, 'vn_split_data_mpc_wani'), 'vn_split_data', '-v7.3')
% save(fullfile(savedir, 'std_all_mpc_wani'), 'std_all', '-v7.3')