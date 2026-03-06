%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 15th Oct 2024 -> 13th June 2025 (checked and revised before
% project transfer)
% Goal: 
%     - Dataset: MPC-Wani 
%     - Atlas: Schaefer_265. 
%     - Booststrapping the model's with finalized parameters (e.g., PC
%     number)

%% Content
% ====== Part 1 
% 1. Loading directories and configuration structure.
% 2. Loading brain features (prepared and saved in S2 script)
% 3. Combinning connectivity and activation
% 4. Loading testing results to get PC number

% ====== Part 2
% 1. Running bootstrap and saving it.
clc
clear
%% Looping through nodes -> for convinience 
node_options = struct( ...
    'node01', struct('predictors', 'hrf_voxel', 'runs', 'caps'), ...
    'node02', struct('predictors', 'hrf_voxel', 'runs', 'caps_rest'), ...
    'node05', struct('predictors', 'connectivity', 'runs', 'caps'), ... % DONE
    'node06', struct('predictors', 'connectivity', 'runs', 'caps_rest'), ...
    'node13', struct('predictors', 'connectivity_and_hrf_voxel', 'runs', 'caps'), ... % May need to re-do just in case
    'node09', struct('predictors', 'connectivity_and_hrf_voxel', 'runs', 'caps_rest') ...
);

% Node 
fprintf('Select a node:\n');
node_numbers = fieldnames(node_options);
for i = 1:length(node_numbers)
    fprintf('%s: %s | %s\n', node_numbers{i}, ...
        node_options.(node_numbers{i}).predictors, ...
        node_options.(node_numbers{i}).runs);
end
selected_node = input('Enter the node (e.g., "node01", "node02"): ', 's');

% Check
if isfield(node_options, selected_node)
    predictors = node_options.(selected_node).predictors;
    runs = node_options.(selected_node).runs;
else
    error('Invalid node selection. Please run the script again and select a valid node.');
end

fprintf('%s |  %s | %s\n', predictors, runs, selected_node);


%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';

% Directories 
%HH_set_dir_mint(model, dataset);
HH_set_dir_mint(model, dataset, '/home/anel/nas1/'); % temp main while reruuning boot
% Config structure
%config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure_all = HH_load_config_mint(dataset,'save',false,'base', '/home/anel/nas1/');
config_structure = config_structure_all.model01_mpc_wani;    
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;

%% 1.2 Loading brain data
% Connectivity and activation: intermittent output from S2 script 
load(fullfile(basedir,'optimized_data_files/for_model_dev_diff_vn_step_final_ver/', 'vn_split_data_mpc_wani_binned_C'), 'vn_split_data')

%% 1.3 Combining connectivity and activation
activation_name = 'hrf_voxel'; % sometimes activation can be hrf_roi, boxcar_roi, etc. -> just the variable name
vn_split_data_final = MINT_prepare_data.combine_connectivity_and_activation(vn_split_data, activation_name); % adding a combined model input

config_structure.vn_split_data_final = vn_split_data_final; % updating config

%% 1.4 Getting PC value 
load(fullfile(basedir, '/model_development_results/9Jun2025_final_model/results_structure_full.mat'), 'testing')
PC_best = testing.(predictors).(runs).PC;
print_header(['Best PC is ' num2str(PC_best)], [predictors ' | ' runs]);
%% Part 2
% Boostrapping 
%% 2.1 Running bootstrap 
% Running bootstrap
save_folder_name = '14Jun2025_bootstrap_check'; % for figures -> change to 9Jun2025_final_model_bootsrtap10000
config_structure.bootstrap_option = 'do_boot'; % IMPORTANT
config_structure.bootstrap_n = 10000; % IMPORTANT -> default 10000

PC_train_plots_save = PC_best;
config_structure.loop_brain_measure = predictors;
config_structure.loop_binning_condition = 'same_time_window';
config_structure.loop_model_input_condition = runs;
config_structure.loop_analysis_saving_name = sprintf('%s/%s',save_folder_name, config_structure.loop_brain_measure);
[training_result, stats_table, model_weights_table] = MINT_model_building.training(PC_best, PC_train_plots_save, config_structure);
boot10_res.training_result = training_result;
boot10_res.stats_table = stats_table;
boot10_res.comment = 'Rerunning before project transfer to revise and double check. Boot number is 10000.';
if ~exist(fullfile(basedir, 'model_development_results/9Jun2025_final_model/bootstrap10000'), 'dir')
    mkdir(fullfile(basedir, 'model_development_results/9Jun2025_final_model/bootstrap10000'));
end 
save(fullfile(basedir, ['model_development_results/9Jun2025_final_model/bootstrap' num2str(config_structure.bootstrap_n)], [predictors '_' runs]), "boot10_res", '-v7.3')





%% Previous code (before S2 was optimized to class function)
% 
% %% Part 2 
% % Model building 
% % Getting testing performance
% % Performance base
% looping_param.performance_base = 'corr_y';
% looping_param.PC_range_split = 1; % CHANGE TO 1 to hypertunne final model
% 
% % Saving options
% looping_param.PC_train_plots_save = [1, 21, 81, 101, 161];  % figures to save (random for myself, to see the pattern)
% looping_param.PC_valid_plots_save = looping_param.PC_train_plots_save;
% looping_param.save_testing_visualization = true;
% looping_param.save_model_weights_stats = true;
% looping_param.save_folder_name = 'TEMP_13Jun2025_bootstrap_check'; % the results will be saved in model_development_results folder
% looping_param.brain_measures = {'connectivity_and_hrf_voxel', 'connectivity', 'hrf_voxel'};
% looping_param.additional_comments = 'Running bootstrap with final parameters on the choosen model';
% 
% tic
% results_structure = MINT_model_building.main_loop(config_structure, looping_param);
% toc
% 
% 
% %% ===== Part 2
% %% 2.1 Prepare for CV-PCR
% data_to_process = 'model_input_data';
% config_structure.loop_normalization_option = 'variance_normalized';
% config_structure.loop_brain_measure = predictors;
% config_structure.loop_binning_condition = 'same_time_window';
% config_structure.loop_model_input_condition = runs;
% config_structure.DCC_cut = 1;
% 
% [binned, n_case, dat_brain, dat_behavioral] = mint_b3_prepare_input_data(config_structure, data_to_process);
% 
% % PC-number 
% load(fullfile(basedir, 'cv_pcr_performance/Final_table_Oct24.mat'));
% PCs_main = result_table.PCs(strcmp(result_table.Predictors, [config_structure.loop_brain_measure ' | ' config_structure.loop_model_input_condition]));
% 
% %% 2.2 Bootstrap 
% tic
% rng('default');
% config_structure.loop_analysis_saving_name = ['boot10_' config_structure.loop_brain_measure '_' config_structure.loop_model_input_condition];
% 
% [mean_r, corr_y, R_squared, bootres, CV_accuracy_perc, n_bins_caps, n_bins_rest, optout, stats] = C2_cv_pcr_mint(PCs_main, config_structure, ...
%     n_case, dat_brain, dat_behavioral, ...
%     'do_visualization', 'do_bootstrap');
% 
% 
% % Store results
% boot_cv_pcr_performance{1, 1} = PCs_main;
% boot_cv_pcr_performance{1, 2} = mean_r;
% boot_cv_pcr_performance{1, 3} = R_squared;
% boot_cv_pcr_performance{1, 4} = corr_y;
% boot_cv_pcr_performance{1, 5} = CV_accuracy_perc;
% boot_cv_pcr_performance{1, 6} = struct('bootMean', bootres.bootmean, 'bootSTE', bootres.bootste, ...
%     'bootZ', bootres.bootZ, 'bootP', bootres.bootP, 'bootCI95', bootres.ci95);
% boot_cv_pcr_performance{1, 7} = optout;
% boot_cv_pcr_performance{1, 8} = stats;
% 
%  % Save cv_pcr 
% boot_res = struct2table(cat(2, boot_cv_pcr_performance{1, 6}), 'AsArray',true);
% boot_cv_pcr_performance_table = [cell2table(boot_cv_pcr_performance(1, 1:5), 'VariableNames', {'PC_number', 'mean_r','R_squared','corr_y', 'CV_accuracy_perc'}), boot_res]; 
% boot_cv_pcr_structure.train_performance = boot_cv_pcr_performance_table;
% 
% 
% boot_cv_pcr_structure.model_weights = cell2table(boot_cv_pcr_performance(1, [1,7]),'VariableNames', {'PC_number', 'outpout'});
% boot_cv_pcr_structure.stats = cell2table(boot_cv_pcr_performance(1, [1,8]), 'VariableNames', {'PC_number', 'stats'});
% save(fullfile(basedir, 'cv_pcr_performance/', ['Boot10_' config_structure.loop_brain_measure '_' config_structure.loop_model_input_condition]), "boot_cv_pcr_structure", '-v7.3');
% 
% toc
