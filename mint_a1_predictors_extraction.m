function mint_a1_predictors_extraction(config_structure, participants_option, varargin)

%% Function: Setup
% Author: Anel Zhunussova
% Last Update: 24th Mar 2024 -> double checked
% Details:
%     - Denoising, getting connectivity(DCC), activation (HRF voxel or roi).

%% ----- Input Check
extract_values = {'boxcar_roi_and_dcc'}; % default
run_to_analyze = {'caps', 'rest'}; % default
cut_duration = false;
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
            case 'cut_duration_activation'
                cut_duration = varargin{var_idx+1};
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

%% ----- Parameters
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


%% ----- Naming setup
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


%% ----- Getting results
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
        mkdir(fullfile(participant_savedir, 'data', 'DCC'));
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
        run_path = fullfile(participant_dir, run_file.name);
        fmri_img = fmri_data(run_path, which('gray_matter_mask.nii'));
        fprintf('Processing file: %s\n', run_path);

        % Assign nuisance covariates 
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


        % Adding global mean option (temp -> checking)
       for extract_idx = 1:length(extract_values) 
            switch extract_values{extract_idx}
                case 'hrf_voxel_global_mean'
                    % Adding global mean as a regressor 
                    global_mean = mean(fmri_img.dat, 1)';  % Average across all voxels per TR, result for caps specificity: 1613 x 1
                    fmri_img.covariates(:, end+1) = global_mean;
                case  'hrf_voxel_rescale_25'
                    fmri_img.dat = fmri_img.dat .* 25;% scaling factor of 25
            end  
       end 
        %% Denoising, extracting activation, connectivity
        for extract_idx = 1:length(extract_values)
            switch extract_values{extract_idx}
                case 'boxcar_roi_and_dcc'
                    % ROI Mean Time-series & Denoising
                    save_name = ['_' save_middle_name filename '.mat'];

                    [~, roi_meants_dat] = canlab_connectivity_preproc(fmri_img,'windsorize', 5, 'lpf', 0.1, 0.46, 'extract_roi', atlas_img, 'no_plots');
                    roi_meants_dat = roi_meants_dat{1,1}.dat;

                    roi_output_path = fullfile(participant_savedir, 'data', 'Activation', ['boxcar_roi' save_name]);
                    save(roi_output_path, 'roi_meants_dat', '-mat');
                    fprintf('ROI mean activation completed and saved.\n');


                    % DCC
                    dcc_output_path = fullfile(participant_savedir, 'data', 'DCC', ['dcc' save_name]);
                    dfc_dat = DCC_jj(roi_meants_dat, 'simple', 'whiten');

                    save(dcc_output_path, 'dfc_dat', '-mat');
                    fprintf('DCC calculation completed and saved.\n');

                case {'hrf_voxel', 'hrf_roi', 'hrf_voxel_rescale_25', 'hrf_voxel_global_mean'}
            
                    TR = 0.46;
                    total_TR = size(fmri_img.dat, 2);
                    length_scan = total_TR*TR;
                    if strcmp(binning_condition{1}, 'same_time_window')
                        binning_condition_name = 'stw';
                    else
                        binning_condition_name = 'sbn';
                    end

                    save_name = ['_' save_middle_name binning_condition_name '_' filename '.mat'];

                    % Getting binning parameters
                    binning_parameters = HH_get_binning_param_mint(config_structure);

                    % Generate the design matrix with single trial option
                    if specificity
                        input_onsets = HH_specificity_get_onset_duration_mint(run_condition, total_TR); % cut duration is set as default for capsaicin and quinine
                    else
                        if cut_duration && strcmp(run_condition, 'caps') || cut_duration && strcmp(run_condition, 'quinine')
                            input_onsets = HH_get_onset_duration_mint(total_TR, binning_parameters, run_condition, 'cut_duration', true);
                        else
                            input_onsets = HH_get_onset_duration_mint(total_TR, binning_parameters, run_condition);
                        end
                    end
                    X = plotDesign_mint(input_onsets,[], TR, length_scan, 'samefig', spm_hrf(1), 'singletrial');
                    close all;

                    % Extracting either hrf_voxel or hrf_roi
                    if contains(extract_values{extract_idx}, 'voxel')
                        output_path = fullfile(participant_savedir, 'data', 'Activation', ['hrf_voxel' save_name]);

                        num_bins = size(input_onsets,1);
                        voxel_beta_dat = nan(num_bins, size(fmri_img.dat,1));
                        tic
                        for bin_i = 1:num_bins
                            [~, ~, ~, voxel_beta_dat1, ~]= canlab_connectivity_preproc(fmri_img,'windsorize', 5, 'lpf', 0.1, 0.46, ...
                                'extract_roi', atlas_img, 'no_plots', 'regressors', X(:,bin_i));
                            voxel_beta_dat(bin_i, :) = voxel_beta_dat1.dat;
                        end
                        toc
                        voxel_beta_dat = voxel_beta_dat';
                        % Save Voxel-based activation pattern
                        save(output_path, 'voxel_beta_dat', '-mat', '-v7.3');
                        print_header(sprintf('HRF voxel done for %s | %s.', participant_name, run_condition));

                    elseif contains(extract_values{extract_idx}, 'roi')
                        output_path = fullfile(participant_savedir, 'data', 'Activation', ['hrf_roi' save_name]);

                        num_bins = size(input_onsets,1);
                        roi_beta_dat = nan(num_bins, 265); %roi_n is 265
                        tic
                        for bin_i = 1:num_bins
                            [~, ~, ~, ~, roi_beta_dat1]= canlab_connectivity_preproc(fmri_img,'windsorize', 5, 'lpf', 0.1, 0.46, ...
                                'extract_roi', atlas_img, 'no_plots', 'regressors', X(:,bin_i));
                            roi_beta_dat(bin_i, :) = roi_beta_dat1{1,1}.dat';
                        end
                        toc

                        roi_beta_dat = roi_beta_dat';
                        % Save Voxel-based activation pattern
                        save(output_path, 'roi_beta_dat', '-mat', '-v7.3');
                        print_header(sprintf('HRF roi done for %s | %s.', participant_name, run_condition));

                    end
   
                % Additional to QC replication set    
                case 'no_denoising_activation'
                    if ~exist(fullfile(participant_savedir, 'data', 'Activation_QC_no_denoising'), 'dir')
                        mkdir(fullfile(participant_savedir, 'data', 'Activation_QC_no_denoising'));
                    end
                    % ROI Mean Time-series & Denoising
                    save_name = ['_' save_middle_name filename '.mat'];

                    [voxel_dat1, roi_meants_dat] = canlab_connectivity_preproc(fmri_img, 'extract_roi', atlas_img);
                    roi_meants_dat = roi_meants_dat{1,1}.dat;

                    roi_output_path = fullfile(participant_savedir, 'data', 'Activation_QC_no_denoising', ['roi' save_name]);
                    save(roi_output_path, 'roi_meants_dat', '-mat');
                    fprintf('ROI mean activation completed and saved.\n');
                    close all;

                    voxel_dat = voxel_dat1.dat;
                    voxel_output_path = fullfile(participant_savedir, 'data', 'Activation_QC_no_denoising', ['voxel' save_name]);

                    save(voxel_output_path, 'voxel_dat', '-mat', '-v7.3');
                    print_header(sprintf('No denoising dat done for %s | %s.', participant_name, run_condition));
                    close all;
            end
        end
    end
end

