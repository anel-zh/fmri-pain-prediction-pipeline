function voxel_beta_dat_all = HH_mint_a1_pain_as_regressor(config_structure, participants_option, varargin)

%% Function: Setup
% Author: Anel Zhunussova
% Last Update: 11th October 2024
% Details:
%     - Denoising, getting connectivity(DCC), activation (HRF, boxcar, 1st PC).

%% Input Check
extract_values = {'hrf_voxel_1beta_pain_based_regressor'}; % default
run_to_analyze = {'caps'}; % default
folder_dir_input = false;
func_folder_input = false;
specificity = false;
for var_idx = 1:length(varargin)
    if ischar(varargin{var_idx})
        switch varargin{var_idx}
            case 'extract_values'
                extract_values = varargin{var_idx+1};
            case 'run_to_analyze'
                run_to_analyze = varargin{var_idx+1}; 
            case 'caps_run_num'
                run_num_caps = varargin{var_idx+1};
            case 'quinine_run_num'
                run_num_quinine =  varargin{var_idx+1};
            case 'folder_name_suffix'
                folder_dir_input = true;
                folder_dir_suffix = varargin{var_idx+1};
            case 'func_folder_name'
                func_folder_input = true;
                func_folder_name = varargin{var_idx+1};
            case 'specificity'
                specificity = varargin{var_idx+1};
        end
    end
end

%% Parameters
% Extract from config_structure
nasdir = config_structure.nasdir;
basedir = config_structure.basedir;
savedir = fullfile(basedir, '/results/');

dataset = config_structure.dataset;
atlas_name = config_structure.atlas_name;
atlas_img = which([atlas_name '.nii']);

if isfield(config_structure, 'loop_binning_condition')
    binning_condition = config_structure.binning_conditions.loop;
else
    binning_condition = config_structure.binning_conditions.main;
end


denoising_method = config_structure.denoising_method;
participants_to_analyze = config_structure.participants_to_analyze.(participants_option);
file_pattern = config_structure.file_pattern;


%% Naming setup
% Based on the dataset
nuisance_name_rest = ['nuisance_' denoising_method 'run1.mat'];
nuisance_name_caps = ['nuisance_' denoising_method  'run10.mat'];
if ismember('quinine', run_to_analyze)
    nuisance_name_caps = ['nuisance_' denoising_method 'run' num2str(run_num_caps) '.mat'];
    nuisance_name_quinine = ['nuisance_' denoising_method  'run' num2str(run_num_quinine) '.mat'];
    print_header('CHECK QUININE RUN NUMBER');
end


switch dataset
    case 'mpc_100'
        header_text = 'Working with MPC-100 case.';
        if folder_dir_input == false
            folder_dir = sprintf('%s%s_%s', denoising_method, dataset, atlas_name);
        else
            folder_dir = sprintf('%s%s_%s_%s', denoising_method, dataset, atlas_name, folder_dir_suffix);
        end
        save_middle_name = [denoising_method dataset '_'];
    case 'mpc_wani'
        header_text = 'Working with MPC-Wani case.';
        if folder_dir_input == false
            folder_dir = sprintf('%s%s', denoising_method, atlas_name);
        else
            folder_dir = sprintf('%s%s_%s', denoising_method, atlas_name, folder_dir_suffix);
        end
        save_middle_name = denoising_method;
    otherwise
        disp('Something went wrong with dataset name.');
end
print_header(header_text);


%% Getting results
for participant_i = 1:numel(participants_to_analyze)
    participant_name = participants_to_analyze{participant_i};
    if func_folder_input == false
        participant_dir = fullfile(nasdir, participant_name, 'func');
    else
        participant_dir = fullfile(nasdir, participant_name, func_folder_name);
    end

    % Create participant-specific folders for results if they don't exist
    participant_savedir = fullfile(savedir, folder_dir, participant_name);
    if ~exist(fullfile(participant_savedir, 'data', 'Activation'), 'dir')
        mkdir(fullfile(participant_savedir, 'data', 'Activation'));
    end

    % Load nuisance files for the selected runs
    if ismember('rest', run_to_analyze)
        nuisance_rest = load(fullfile(nasdir, participant_name, 'nuisance_mat', nuisance_name_rest));
    end
    if ismember('caps', run_to_analyze)
        nuisance_caps = load(fullfile(nasdir, participant_name, 'nuisance_mat', nuisance_name_caps));
    end
    if ismember('quinine', run_to_analyze)
        nuisance_quinine = load(fullfile(nasdir, participant_name, 'nuisance_mat', nuisance_name_quinine));
    end

    % Files based on the selected runs
    run_files_all = [];
    if ismember('caps', run_to_analyze)
        run_files_caps = dir(fullfile(participant_dir, sprintf('%s-caps_*_bold.nii', file_pattern)));
        run_files_all = [run_files_all; run_files_caps];
    end
    if ismember('rest', run_to_analyze)
        run_files_rest = dir(fullfile(participant_dir, sprintf('%s-resting_run-01*_bold.nii', file_pattern)));
        run_files_all = [run_files_all; run_files_rest];
    end
    if ismember('quinine', run_to_analyze)
       run_files_quinine = dir(fullfile(participant_dir, sprintf('%s-quinine_*_bold.nii', file_pattern)));
       run_files_all = [run_files_all; run_files_quinine];
    end 

    % Loop through each run
    for run_i = 1:numel(run_files_all)
        run_file = run_files_all(run_i);
        % Loading behavioral data
        run_name = extractBetween(run_file.name, 'task-', '_run');
        behav_all = config_structure.behavioral_data.main.(run_name{1}); %main can be changed to spec in the future for convinience.

        % Loadinf fmri data
        run_path = fullfile(participant_dir, run_file.name);
        fmri_img = fmri_data(run_path, which('gray_matter_mask.nii'));
        fprintf('Processing file: %s\n', run_path);

        % Assign nuisance covariates for run 1 and run 10
        if contains(run_file.name, 'caps')
            fmri_img.covariates = nuisance_caps.R;
            run_condition = 'caps';
        elseif contains(run_file.name, 'resting')
            fmri_img.covariates = nuisance_rest.R;
            run_condition = 'rest';
        elseif contains(run_file.name, 'quinine')
            fmri_img.covariates = nuisance_quinine.R;
            run_condition = 'quinine';
        end

        % Get filename for saving
        [~, filename, ~] = fileparts(run_file.name);


        %% Denoising, extracting activation, connectivity
        for extract_idx = 1:length(extract_values)
            switch extract_values{extract_idx}
                case 'hrf_voxel_1beta_pain_based_regressor'


                    TR = 0.46;
                    dur_TR = size(fmri_img.dat, 2);
                    if dur_TR > 1510 && strcmp(run_name{1}, caps)
                        % Here should be the consideration for sessions with
                        % longer TR
                        error('Have not finished function');
                    end 
                    
                    % Convolving pain ratings 
                    % From onsets2fmridesign
                    res = 16;   % resolution, in samples per second
                    hrfparams = [6 16 1 1 6 0 32];
                    hrf = spm_hrf(1/res, hrfparams);   % canonical hrf %Anel-> get hrf here

                    % Pain rating
                    behav1 = behav_all(participant_i,:); % 1 session -> 1x1510TR

                    original_indices = 1:dur_TR;
                    new_size = round(dur_TR * TR * res);  % New length | changing to sec res as in hrf
                    new_indices = linspace(1, dur_TR, new_size);
                    behav1_resampled = interp1(original_indices, behav1, new_indices, 'linear')'; %size 11114x1

                    % Convolution
                    additional_param = {dur_TR*TR, [],'noampscale'};
                    X = getPredictors(behav1_resampled, hrf, 'dslen', dur_TR, 'force_delta', additional_param{:});
                    close all;
                    plot(X); hold on; plot(behav1);
                    box off;
                    set(gcf, 'color', 'w');
                    ylabel('Pain Intensity');
                    xlabel('TR')
                    title('Convolved capsaicin ratings vs Original (sub-mpc006)');


                    close all;
                    RR = [X, fmri_img.covariates]; % double check 
                    imagesc(RR, [-1,1]); % should I save this (?)
                    close all;

                
                    % Getting beta
                    tic
                    [~, ~, ~, voxel_beta_dat, ~]= canlab_connectivity_preproc(fmri_img,'windsorize', 5, 'lpf', 0.1, 0.46, ...
                         'extract_roi',atlas_img, 'no_plots', 'regressors', X);
                    toc

                    voxel_beta_dat_all{participant_i} = voxel_beta_dat;

                    % Save Voxel-based activation pattern
                        % Save name defining
%                     if strcmp(binning_condition{1}, 'same_time_window')
%                         binning_condition_name = 'stw';
%                     else
%                         binning_condition_name = 'sbn';
%                     end
%                     save_name = ['_' save_middle_name binning_condition_name '_' filename '.mat'];

                    %output_path = fullfile(participant_savedir, 'data', 'Activation', ['hrf_voxel' save_name]);
    
                   % save(output_path, 'voxel_beta_dat', '-mat', '-v7.3');
                    print_header(sprintf('Univariate Beta done for %s | %s.', participant_name, run_condition));

            end
        end
    end
end

