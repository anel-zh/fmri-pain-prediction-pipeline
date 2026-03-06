function data_cell = mint_a2_load_predictors(config_structure, option, runs_to_load, data_to_load, varargin)
%% Function: Setup 
% Author: Anel Zhunussova 
% Last Update: 14th April 2024 (Changed input type, adopted for
% replication)
% Details:
%     - Loading connectivity(DCC) and activation (HRF, boxcar). 
%     - Updated for final model option.
%     - Default for activation loading: cut duration after preprocessing to
%     remove stimulus delivery and removal.
%     - Works for both MPC-Wani and MPC-100.

% Logic:
%     1. Looping over participants. -> looping over runs (caps, rest).
%     2. Getting the directories for chosen brain feature.
%     3. Loading brain features into cell. 

% Output:
%     - Cell: each column is a session/participant; each row is the run. 

% data_cell = mint_a2_load_predictors(config_structure, 'main', {'caps', 'rest'}, 'hrf_voxel')
[basedir, participants_to_analyze, denoising_method, atlas_name, dataset] = deal(config_structure.basedir, ...
    config_structure.participants_to_analyze.(option), config_structure.denoising_method, ...
    config_structure.atlas_name, config_structure.dataset);

%% Function
binning_condition_to_load = 'same_time_window';

if ~isempty(varargin)
    binning_condition_to_load = varargin{1};
end

if strcmp(binning_condition_to_load, 'same_time_window')
    binning_condition_name = 'stw';
else
    binning_condition_name = 'sbn'; % same-bin-number -> previously checked option
end


data_cell = cell(numel(runs_to_load), numel(participants_to_analyze));


% Looping for each participant/session
for participant_i = 1:numel(participants_to_analyze)
    participant_name = participants_to_analyze{participant_i};
    
    % Defining main directory with saved brain features based on the dataset
    if strcmp(dataset, 'mpc_100') == 1
        participant_savedir = fullfile(basedir, 'results', sprintf('%s%s_%s_final', denoising_method, dataset, atlas_name), participant_name);
    elseif strcmp(dataset, 'mpc_wani') == 1 && strcmp(option, 'main')
        participant_savedir = fullfile(basedir,'results', sprintf('%s%s_final', denoising_method, atlas_name), participant_name);
    elseif strcmp(dataset, 'mpc_wani') == 1 && strcmp(option, 'replication_sessions') == 1
        participant_savedir = fullfile(basedir,'results',sprintf('%s%s_replication', denoising_method, atlas_name), participant_name);
    elseif strcmp(dataset, 'mpc_wani') == 1 && strcmp(option, 'replication_global_mean') == 1
        participant_savedir = fullfile(basedir,'results',sprintf('%s%s_replication_global_mean', denoising_method, atlas_name), participant_name);
    elseif strcmp(dataset, 'mpc_wani') == 1 && strcmp(option, 'main_global_mean') == 1
        participant_savedir = fullfile(basedir,'results',sprintf('%s%s_main_global_mean', denoising_method, atlas_name), participant_name);
    else
        disp('Something went wrong with identifying the participant_savedir -> sub-mpc with data storing directory');
    end

    % Looping over runs (caps, rest)
    for run_i = 1:numel(runs_to_load)
        run_name = runs_to_load{run_i};

        % Choosing features to load -> getting their directories 
        switch data_to_load
            case 'DCC'
                print_header(sprintf('Loading %s data - DCC for: %s', run_name, participant_name))
                data_files = dir(fullfile(participant_savedir, 'data', 'DCC', ['dcc_' denoising_method '*' run_name '*_bold.mat']));
            case 'hrf_voxel'
                print_header(sprintf('Loading %s data - HRF voxel %s for: %s', run_name,binning_condition_name, participant_name))
                data_files = dir(fullfile(participant_savedir, 'data', 'Activation', ['hrf_voxel_' denoising_method '*' run_name '*_bold.mat']));
            case 'hrf_roi'
                participant_savedir = fullfile(basedir, sprintf('%s%s_hrf_roi', denoising_method, atlas_name), participant_name);
                print_header(sprintf('Loading %s data - HRF roi %s for: %s', run_name,binning_condition_name, participant_name))
                data_files = dir(fullfile(participant_savedir, 'data', 'Activation', ['hrf_roi_' denoising_method '*' run_name '*_bold.mat']));
            case 'boxcar_roi'
                print_header(sprintf('Loading %s data - ROI timeseries %s for: %s', run_name,binning_condition_name, participant_name))
                data_files = dir(fullfile(participant_savedir, 'data', 'Activation', ['boxcar_roi_' denoising_method '*' run_name '*_bold.mat']));
            otherwise
                disp('Invalid data type specified. Choose either "DCC", "hrf_voxel"');
                return;
        end
        
        % Checking directories (so they are not empty)
        if isempty(data_files)
            disp('data_files is empty -> check directory');
        end

        % Loading files from chosen directories
        for data_i = 1:numel(data_files)
            data_file = data_files(data_i);
            % Defining load directory & load file
            switch data_to_load
                case 'DCC'
                    data_path = fullfile(participant_savedir, 'data','DCC', data_file.name);
                    load(data_path, 'dfc_dat');
                    data_cell{run_i, participant_i} = dfc_dat;                 
                case 'hrf_voxel' 
                    data_path = fullfile(participant_savedir, 'data','Activation', data_file.name);
                    load(data_path, 'voxel_beta_dat');
                    data_cell{run_i, participant_i} = voxel_beta_dat;  
                 case 'hrf_roi'
                    data_path = fullfile(participant_savedir, 'data','Activation', data_file.name);
                    load(data_path, 'roi_beta_dat');
                    data_cell{run_i, participant_i} = roi_beta_dat;  
                 case 'boxcar_roi' 
                    data_path = fullfile(participant_savedir, 'data','Activation', data_file.name);
                    load(data_path, 'roi_meants_dat');
                    data_cell{run_i, participant_i} = roi_meants_dat;  
            end 
        end

    end
end
end

