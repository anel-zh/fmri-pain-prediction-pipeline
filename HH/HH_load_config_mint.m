function [config_structure] = HH_load_config_mint(dataset, varargin)

%% Function: Setup
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 14th April 2024 -> Updated to have final model weights ->
% 11th June 2025 revised before project transfer
% Goal: 
%     - Creating configuration structure.

%% Input check
save_config = false;
load_final_model = false;
% Project Directory -> Can be updated through varargin 
[~, hostname] = system('hostname');
if contains(hostname, 'node') || contains(hostname, 'docker')
    % base = '/home/anel/nas1/'; % Server
    base = '/media/nas01/'; % Server
else
    base = '/Volumes/cocoanlab01/'; % MacBook
end
% Directories
for var_idx = 1:length(varargin)
    switch varargin{var_idx}
        case 'base'% June 11th 2025 -> update Anel
            base = varargin{var_idx+1};
        case 'save'
            save_config = varargin{var_idx+1};
            savedir = [base '/projects/MINT/analysis/imaging/connectivity/configuration_structures'];
        case 'load_final_model'
            load_final_model = true;% June 11th 2025 -> update Anel
            if var_idx+1 <= numel(varargin) && ~isempty(varargin{var_idx+1}) % June 11th 2025 -> update Anel
                model_wei_dir = varargin{var_idx+1};
            else
                model_wei_dir = [base '/projects/MINT/analysis/imaging/connectivity/model01_Schaefer_mpc_wani/model_development_results/9Jun2025_final_model/results_structure_full.mat'];
            end 
            % results_structure -> testing, training, validation is just
            % performance metric (+ model weights in testing) and
            % model_weights have all the model weights for all PCs
    end 
end 

%% =======================================================
%
% Part 1: Defining parametrs that are same between datasets
%
% ========================================================
projectdir = [base 'projects/MINT/analysis/'];

%% Binning
% Previous options
caps_bin_size_TR = 50:150; % fixing TR duration (23sec-69sec)
tr_bins_same_window = HH_same_time_window_bins_mint(caps_bin_size_TR, true);
previous_binning_options = tr_bins_same_window;

% Additionally adding new binning options
names = {'SS_90_TR_voxel'};
TR_values = str2double(regexp(cat(2, names{:}), '\d*', 'Match'));
main_binning_option = HH_same_time_window_bins_mint(TR_values, false); % saving all values
binning_all_options = vertcat(previous_binning_options, main_binning_option);

%% Parcellations
atlas_names = {'Schaefer_265_combined_2mm', 'Fan_r279_MNI_2mm'};

%% Brain measures
brain_measure_all = {'connectivity_and_boxcar', 'connectivity', 'boxcar', ...
                'connectivity_and_first_pc_activation', 'first_pc_activation', ...
                'connectivity_and_hrf_voxel_stw', 'hrf_voxel_stw', ...
                'connectivity_and_hrf_voxel_sbn', 'hrf_voxel_sbn'};

brain_measure_main = {'connectivity', 'hrf_voxel', 'connectivity_and_hrf_voxel'};


%% ==============================================
%
% Part 2: Creating structures
%
% ===============================================

%% By dataset
switch dataset
    case 'mpc_wani'
        % Define directories
        nasdir = [base 'data/MPC/MPC_wani/imaging/preprocessed/MNI_youngeun/preprocessed/'];

        % IDs
        % Three options: all, with sleep sessions and no sleep session
        dir_ids = dir(fullfile(nasdir, 'sub*'));
        participants_to_analyze = {dir_ids.name}.';
        prob_participants = {'sub-mpc005', ... % no caps data
            'sub-mpc007', ...  % abrnomal behavioral caps ratings
            'sub-mpc028', 'sub-mpc030', 'sub-mpc031', ... % sleeping sessions
            'sub-mpc032', 'sub-mpc033'}; % no caps data & sleeping sessions
        prob_participants_with_sleep = {'sub-mpc005', 'sub-mpc007', 'sub-mpc032', 'sub-mpc033'};
        remove_id = ismember(participants_to_analyze, prob_participants);
        remove_id_with_sleep = ismember(participants_to_analyze, prob_participants_with_sleep);
        participants_no_sleep_sessions = participants_to_analyze(~remove_id);
        participants_with_sleep_sessions = participants_to_analyze(~remove_id_with_sleep);

        % Behavioral Data
        % Adding zero-padding
        behavioral_caps_df = table2array(readtable(fullfile(projectdir, 'behavioral/Ratings/all_ratings_wani_cleaned_no_sleeping_sessions_2Jun.xlsx'))); % 26 x 1500 double
        behavioral_rest_df = table2array(readtable(fullfile(projectdir, 'behavioral/Ratings/all_ratings_wani_cleaned_rest_no_sleeping_sessions_2Jun.xlsx'))); % 26 x 783 double

        n_subj = length(participants_no_sleep_sessions);
        behavioral_caps = [zeros(n_subj, 10), behavioral_caps_df(1:n_subj, :)]; % zero-padding to match duration with a scan (output: 26x1510 double)
        behavioral_rest = [zeros(n_subj, 11), behavioral_rest_df(1:n_subj, :)]; % (output: 26x794 double)

        % Adding replication sessions (extra 4 scans)
        behavioral_rep = load_rep_behavioral(base); % Updated June 11 2025 to add base

        % Split
        % Youngeun's split
        test_id = {'sub-mpc001'; 'sub-mpc012'; 'sub-mpc014'; 'sub-mpc020'; 'sub-mpc026'};
        valid_id = {'sub-mpc002'; 'sub-mpc006'; 'sub-mpc016'; 'sub-mpc018'};
        train_id = participants_no_sleep_sessions(~ismember(participants_no_sleep_sessions, [test_id; valid_id]));

        % Creating the structure
        % Loop through models_wani to assign configurations
        % Configuration parameters for models_wani
        models_wani = {'model01_mpc_wani', 'model02_mpc_wani'};

        for i = 1:length(models_wani)
            % Details
            config_structure.(models_wani{i}).dataset = 'mpc_wani';
            config_structure.(models_wani{i}).atlas_name = atlas_names{i};
            config_structure.(models_wani{i}).denoising_method =  'mean_sig_';
            config_structure.(models_wani{i}).file_pattern = 'asw*';
            config_structure.(models_wani{i}).model_input_conditions = {'caps_rest', 'caps'};
            config_structure.(models_wani{i}).binning_conditions.all = {'same_time_window', 'same_bin_number'};
            config_structure.(models_wani{i}).binning_conditions.main = {'same_time_window'};
            config_structure.(models_wani{i}).task_runs.caps =  {'run-10'};
            config_structure.(models_wani{i}).task_runs.rest = {'run-01'};
            config_structure.(models_wani{i}).task_runs.comment = 'Numbering is from original scans.';
            % IDs
            config_structure.(models_wani{i}).participants_to_analyze.all = participants_to_analyze;
            config_structure.(models_wani{i}).participants_to_analyze.with_sleep_sessions = participants_with_sleep_sessions;
            config_structure.(models_wani{i}).participants_to_analyze.main = participants_no_sleep_sessions; % no sleep sessions
            config_structure.(models_wani{i}).participants_to_analyze.replication_sessions = {'sub-mpc034', 'sub-mpc036', 'sub-mpc037', 'sub-mpc038'};
            config_structure.(models_wani{i}).participants_to_analyze.comment = 'Replication sessions refer to 4 extra scans made for MPC-Wani after 4 years. Main refer to the original scan sessions collected throughout a year and only includes sessions that have capsaicin run';
            
            config_structure.(models_wani{i}).participants_removed_ids.all = prob_participants;     % Removed IDs
            config_structure.(models_wani{i}).participants_removed_ids.details.no_caps_data = {'sub-mpc005', 'sub-mpc032', 'sub-mpc033'};
            config_structure.(models_wani{i}).participants_removed_ids.details.abnormal_caps_ratings = {'sub-mpc007'};
            config_structure.(models_wani{i}).participants_removed_ids.details.sleep_sessions = {'sub-mpc0028', 'sub-mpc030', 'sub-mpc031','sub-mpc032', 'sub-mpc033'};

            % Binning
            config_structure.(models_wani{i}).binning_parameters.same_time_window.all = binning_all_options;
            config_structure.(models_wani{i}).binning_parameters.same_time_window.previous = previous_binning_options;
            config_structure.(models_wani{i}).binning_parameters.same_time_window.main = main_binning_option;

            % Behavioral Data
            config_structure.(models_wani{i}).behavioral_data.main.caps = behavioral_caps;
            config_structure.(models_wani{i}).behavioral_data.main.rest = behavioral_rest;
            config_structure.(models_wani{i}).behavioral_data.replication_sessions = behavioral_rep;

            % Split
            config_structure.(models_wani{i}).model_split.main.test_id = test_id;
            config_structure.(models_wani{i}).model_split.main.valid_id = valid_id;
            config_structure.(models_wani{i}).model_split.main.train_id = train_id;

            % Brain Measure
            config_structure.(models_wani{i}).brain_measure.all = brain_measure_all;
            config_structure.(models_wani{i}).brain_measure.main = brain_measure_main;

        end
        if load_final_model
           print_header('Model weights available only for model01_mpc_wani as for now') % Only for Schaefer parcellation
           final_model_results = load(model_wei_dir, 'testing', 'training', 'validation');
           config_structure.model01_mpc_wani.final_model.weights_and_testing_performance = final_model_results.testing;
           config_structure.model01_mpc_wani.final_model.validation_performance = final_model_results.validation;
           config_structure.model01_mpc_wani.final_model.training_performance = final_model_results.training;
        end 
        % Comments
        date = datetime("today");
        config_structure.comments = sprintf('Last Update: %s. Refer to the load_config_mint.m for creation details or contact anelzhunussova08@gmail.com', date);

        % Save Configuration

        if save_config
            save(fullfile(savedir, 'config_structure_mpc_wani.mat'), 'config_structure');
        end 


%% MPC -100      
    case 'mpc_100'
        % Define directories
        nasdir = [base 'data/MPC/MPC_100/imaging/preprocessed'];
        % Participants
        dir_ids = dir(fullfile(nasdir, 'sub-*'));
        participants_to_analyze = {dir_ids.name}.';
        remove_id = strcmp(participants_to_analyze,'sub-mpc015') | strcmp(participants_to_analyze,'sub-mpc052') | strcmp(participants_to_analyze,'sub-mpc053'); % no caps session, abrnomal scan
        participants_to_analyze = participants_to_analyze(~remove_id);

        % Behavioral Data
        % Adding zero-padding
        behavioral_caps_df = table2array(readtable(fullfile(projectdir, 'behavioral/Ratings/all_ratings_100_cleaned_2Jun.xlsx'))); % 122 x 1500 double
        behavioral_rest_df = table2array(readtable(fullfile(projectdir, 'behavioral/Ratings/all_ratings_100_cleaned_rest_2Jun.xlsx'))); % 122 x 783 double

        n_subj = length(participants_to_analyze);
        behavioral_caps = [zeros(n_subj, 10), behavioral_caps_df(1:n_subj, :)]; % zero-padding to match duration with a scan (output: 26x1510 double)
        behavioral_rest = [zeros(n_subj, 11), behavioral_rest_df(1:n_subj, :)]; % (output: 26x794 double)
        
        % Creating the structure
        % Loop through models_100 to assign configurations
        % Configuration parameters for models_100
        models_100 = {'model01_mpc_100', 'model02_mpc_100'};


        for i = 1:length(models_100)
             % Details
            config_structure.(models_100{i}).dataset = 'mpc_100';
            config_structure.(models_100{i}).atlas_name = atlas_names{i};
            config_structure.(models_100{i}).denoising_method =  'mean_sig_';
            config_structure.(models_100{i}).file_pattern = 'asw*';
            config_structure.(models_100{i}).model_input_conditions = {'caps_rest', 'caps'};
            config_structure.(models_100{i}).binning_conditions.all = {'same_time_window', 'same_bin_number'};
            config_structure.(models_100{i}).binning_conditions.main = {'same_time_window'};
            config_structure.(models_100{i}).task_runs.caps =  {'run-10'};
            config_structure.(models_100{i}).task_runs.rest = {'run-01'};

            % IDs
            config_structure.(models_100{i}).participants_to_analyze.main = participants_to_analyze;
            config_structure.(models_100{i}).participants_removed_ids.all = {'sub-mpc015', 'sub-mpc052', 'sub-mpc053'};
            config_structure.(models_100{i}).participants_removed_ids.details.no_caps_data = {'sub-mpc052'};
            config_structure.(models_100{i}).participants_removed_ids.details.misunderstood_caps_rating_system = {'sub-mpc015'};
            config_structure.(models_100{i}).participants_removed_ids.details.no_scan_data = {'sub-mpc053'};
            
            % Binning
            config_structure.(models_100{i}).binning_parameters.same_time_window.all = binning_all_options;
            config_structure.(models_100{i}).binning_parameters.same_time_window.previous = previous_binning_options;
            config_structure.(models_100{i}).binning_parameters.same_time_window.main = main_binning_option;

            % Behavioral Data
            config_structure.(models_100{i}).behavioral_data.main.caps = behavioral_caps;
            config_structure.(models_100{i}).behavioral_data.main.rest = behavioral_rest;

            % Split
            load([base 'projects/MINT/analysis/imaging/split/results/YE_split_mpc_100.mat'], 'youngeun_split_main');
            config_structure.(models_100{i}).model_split.main.test_id = youngeun_split_main.subnames_te;
            config_structure.(models_100{i}).model_split.main.valid_id = youngeun_split_main.subnames_va;
            config_structure.(models_100{i}).model_split.main.train_id = youngeun_split_main.subnames_tr;

            
            % ==================================================
            % NOT DEFINED YET DUE TO THE PROBLEM WITH YE'S SPLIT -> TEMP ANEL SPLIT 
            % ==================================================

            load([base 'projects/MINT/analysis/imaging/split/results/Anel_split_mpc_100.mat'], 'Anel_split_mpc_100');
            config_structure.(models_100{i}).model_split.temp_anel = Anel_split_mpc_100;

            % Brain Measure
            config_structure.(models_100{i}).brain_measure.all = brain_measure_all;
            config_structure.(models_100{i}).brain_measure.main = brain_measure_main;
        end
        % Comments
        date = datetime("today");
        config_structure.comments = sprintf('Last Update: %s. Refer to the load_config_mint.m for creation details or contact anelzhunussova08@gmail.com', date);

        % Save Configuration
        if save_config
            save(fullfile(savedir, 'config_structure_mpc_100.mat'), 'config_structure');
        end

    otherwise 
        error('Inccorect dataset input.')
end 

function behavioral = load_rep_behavioral(base)
%% ========= Behavioral Data
TR = 0.46;
clear behavioral_caps behavioral_rest behavioral_quinine
weeks = {'week34*', 'week36*', 'week37*', 'week38*'};
zero_padding = zeros(1, round(4.6 / TR));

% Define TR trimming values
% first column is from start and the second from end 
trim_params = {
    [], [];                                   % week 34
    round(28/TR), [];                         % week 36
    round(30/TR), round(28/TR);              % week 37
    round(30/TR), round(25/TR);              % week 38
};

for week_idx = 1:length(weeks)
    % Load files
    base_behav = [base 'data/MPC/MPC_wani/behavioral/raw/scanner/'];
    caps_file = filenames([base_behav weeks{week_idx} '/*_caps_MPC.mat']);
    quinine_file = filenames([base_behav weeks{week_idx} '/*_quinine_MPC.mat']);
    rest_file = filenames([base_behav weeks{week_idx} '/*001_resting_MPC.mat']);

    % Extract raw ratings
    raw_caps = load(caps_file{1}).data.dat.continuous_rating;
    raw_quinine = load(quinine_file{1}).data.dat.quin_continuous_rating;
    raw_rest = load(rest_file{1}).data.dat.continuous_rating;

    % Interpolate
    [~, caps] = ALL_behavioral_mint.interpolate({raw_caps}, TR);
    [~, quinine] = ALL_behavioral_mint.interpolate({raw_quinine}, TR);
    [~, rest] = ALL_behavioral_mint.interpolate({raw_rest}, TR);

    % Apply TR trimming
    start_TR = trim_params{week_idx, 1};
    end_TR = trim_params{week_idx, 2};
    

    if ~isempty(start_TR)
        caps{1}(1:start_TR, :) = [];
        quinine{1}(1:start_TR, :) = [];
        rest{1}(1:start_TR, :) = [];
    end
    if ~isempty(end_TR)
        if week_idx == 3 % sub-mpc037 caps session in 1 TR shorter than quinine
            caps{1}((end-end_TR)+1:end, :) = [];
            rest{1}((end-end_TR)+1:end, :) = [];
        else
            caps{1}((end-end_TR):end, :) = [];
            rest{1}((end-end_TR):end, :) = [];
        end
        quinine{1}((end-end_TR):end, :) = [];
    end

    % Zero-padding + assignment
    behavioral.caps(week_idx, :) = [zero_padding, caps{1}'];
    behavioral.quinine(week_idx, :) = [zero_padding, quinine{1}'];
    behavioral.rest(week_idx, :) = [zero_padding, rest{1}'];

   % print_header(['Done Behavioral: ' num2str(week_idx)]);
end
