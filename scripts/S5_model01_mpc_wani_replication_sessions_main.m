%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 9th Jan 2024 -> 13th June 2025 revised and checked before
% project transfer
% Goal: 
%     - Dataset: MPC- Wani. 
%     - Atlas: Schaefer_265. 
%     - Applying final model on replication dataset (includes cross-test
%     application like caps_rest on caps)
%% Content
% ====== Part 1 
% 1. Loading directories and configuration structure.
% 2. Loading final models, specificity brain and beahvioral data.
% 3. Preparing data (binning, variance, combining).
% 4. Loading testing results from original model development from S2.

% ====== Part 2 (cross-testing and applying model on replication data)
% 1. Defining looping parameters
    % -- loop start
% 2. Preparing data
% 3. Applying model weights
% 4. Getting performance
% 5. Visualizing
    % -- loop end 
% 6. Saving performance table

clc
clear
%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';

% Directories
HH_set_dir_mint(model, dataset);

% Config structure
config_structure_all = HH_load_config_mint(dataset,'save');
config_structure = config_structure_all.(['model01_' dataset]);
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;

%% 1.2 Loading specificity data 
% IMPORTANT TO use 'replication sessions' instead of 'main'

% Connectivity
connectivity_cell = mint_a2_load_predictors(config_structure, 'replication_sessions', {'caps','rest', 'quinine'}, 'DCC'); % 1st row is caps, 2nd row is rest
connectivity = HH_match_durations_mpc_wani_mint(connectivity_cell, 'DCC_cut_replication');

% Pattern Activation (Voxel)
hrf_voxel = mint_a2_load_predictors(config_structure, 'replication_sessions', {'caps','rest', 'quinine'}, 'hrf_voxel');

%% 1.3 Preparing the data 
% -- Using variance of the replication sessions to normalize 

% --- Binning
% window_size_TR = 90;
window_size_TR = config_structure.binning_parameters.same_time_window.main.Window_size_TR;
binned_behavioral = MINT_prepare_data.bin_behavioral_data(config_structure, 'replication_sessions', window_size_TR); 

% -- Brain data 
% Variance normalization
brain.connectivity.caps = connectivity(1,:);
brain.connectivity.rest = connectivity(2,:);
brain.connectivity.quinine = connectivity(3,:);

brain.hrf_voxel.caps = hrf_voxel(1,:);
brain.hrf_voxel.rest = hrf_voxel(2,:);
brain.hrf_voxel.quinine = hrf_voxel(3,:);

[vn_dat, std_rep] = MINT_prepare_data.variance_normalization_independent_set(brain, binned_behavioral);
 
% --- Binning connectivity 
fields = {'independent_set'};
for f = 1:length(fields)
    % Binning 
    current_dat = [vn_dat.(fields{f}).connectivity_caps; vn_dat.(fields{f}).connectivity_rest; vn_dat.(fields{f}).connectivity_quinine];
    current_binned_caps = MINT_prepare_data.bin_connectivity(current_dat, window_size_TR);
    
    % Updating structure
    [vn_dat.(fields{f}).connectivity_caps, vn_dat.(fields{f}).connectivity_rest, vn_dat.(fields{f}).connectivity_quinine] = deal(current_binned_caps.connectivity_caps, current_binned_caps.connectivity_rest, current_binned_caps.connectivity_quinine);
end 

% --- Saving for future use
save(fullfile(basedir, 'optimized_data_files', 'replication_data_diff_vn_step'), "vn_dat", '-v7.3');

% --- Combinning connectivity and activation 
activation_name = 'hrf_voxel'; % can be 'hrf_roi','activation' etc. depending on field naming
vn_split_data_final = MINT_prepare_data.combine_connectivity_and_activation(vn_dat, activation_name); 

%% 1.4 Loading testing results from original model development (S2)
load(fullfile(basedir, '/model_development_results/9Jun2025_final_model/results_structure_full.mat'), 'testing')

%% Part 2 
% Applying final models on replication session 
% > Basically same as MINT_model_building.testing, just adding the model_wei_run to be cross-test 
main_table_result = table();
save_testing_visualization = true; 
figuredir = fullfile(basedir, '/figures/model/9Jun2025_final_model/applying_final_model_on_replication_set_with_cross_testing'); if ~exist(figuredir, 'dir'); mkdir(figuredir); end

%% 2.1 Defining looping parameters
            % Test on(replication data)  % Model (original dataset)   
cross_test = {'caps_rest', 'caps';... 
              'caps', 'caps_rest';...
              'caps_rest', 'caps_rest';... 
              'caps', 'caps'; ...
              'quinine_rest', 'caps_rest'; ... % checking on quinine 
              'quinine', 'caps_rest'; ...
              'quinine_rest', 'caps'; ...
              'quinine', 'caps'}; 
brain_measures_all = fieldnames(testing);

for b = 1:length(brain_measures_all)
    brain_measure = brain_measures_all{b};
    for c = 1:size(cross_test,1)
        %% 2.2 Preparing data
        set_name = 'independent_set'; 
        model_input_condition = cross_test{c,1};
        % case_run refers to whether it is capsaicin or for example quinine not to
        % the model_input condition
        [n_case, model_input_data] = MINT_prepare_data.reshape_for_model_input(vn_split_data_final, brain_measure, set_name, model_input_condition);

        %% 2.3 Applying model weights
        model_wei_run = cross_test{c,2};
        print_header(brain_measure, ['Model ' model_wei_run ' on ' model_input_condition]);
        model_weights = testing.(brain_measure).(model_wei_run).model_weights{1};
        intercept = testing.(brain_measure).(model_wei_run).model_weights{2};

        pred_score = MINT_model_building.apply_model_weights(model_input_condition, model_input_data.binned, n_case, model_weights, intercept);

        %% 2.4 Getting performance
        % Getting actual (Y) and predicted case ratings (yfit)
        [ratings_all] = MINT_model_building.get_shaped_ratings(model_input_condition, model_input_data.binned, pred_score);

        % Getting performance
        whfolds = MINT_model_building.get_whfolds(model_input_condition,n_case); %whfolds
        performance = MINT_model_building.get_performance( ...
            ratings_all.model_performance.(model_input_condition).y, ...
            ratings_all.model_performance.(model_input_condition).yfit, ...
            whfolds, n_case);


        % Saving results
        temp_table = table({brain_measure},{model_wei_run}, {model_input_condition}, ratings_all, 'VariableNames',{'Brain Feature', 'Model', 'Test on', 'ratings_all'});
        main_table_result = [main_table_result; temp_table, struct2table(performance)];

        %% 2.5 Visualizing
        % Visualize validation performance
        if save_testing_visualization
            figure_names = ['model_' model_wei_run '_tested_on_' model_input_condition '.pdf'];
            figures_save_dir = fullfile(figuredir, brain_measure);
            MINT_model_building.visualize(ratings_all, model_input_condition, n_case, figures_save_dir, figure_names, config_structure.dataset)
        end
    end
end 

%% 2.6 Saving performance table
save(fullfile(basedir, 'model_development_results/9Jun2025_final_model/final_model_on_replication_including_cross_testing'), 'main_table_result', '-v7.3')


