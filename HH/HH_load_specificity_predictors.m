function [connectivity, hrf_voxel, behavioral, boxcar_roi_final] = HH_load_specificity_predictors(basedir, varargin)
behavioral = [];
boxcar_roi_final = [];
connectivity =[];
hrf_voxel = [];
% New preproc option
% New preproc option
if ~isempty(varargin)
    if ~any(cellfun(@(x) strcmp(x, 'only_behavioral'), varargin))

% ========= Brain Data
% Connectivity
if contains(basedir, 'Schaefer')
    mid_name = 'mean_sig_Schaefer_265_combined_2mm_specificity';
    print_header('Basedir is from MPC-Wani | Schaefer atlas');

elseif contains(basedir, 'Fan')
    mid_name = 'Fan_et_al_atlas_r279_MNI_specificity';
    print_header('Basedir is from MPC-Wani | Fan atlas');
end

% New preproc option
if ~isempty(varargin)
    if strcmp(varargin{:}, 'new_T1') 
        mid_name = 'mean_sig_Schaefer_265_combined_2mm_specificity_new_T1';
        print_header('Basedir is from MPC-Wani | Schaefer atlas | new_T1 option'); 
    elseif strcmp(varargin{:}, 'rescaled_to_16bit') 
         mid_name = 'mean_sig_Schaefer_265_combined_2mm_specificity_rescaled_to16bit';
        print_header('Basedir is from MPC-Wani | Schaefer atlas | Rescaled to 16bit option'); 
    elseif strcmp(varargin{:}, 'after_ica_new_T1') 
        mid_name = 'after_ica_mean_sig_Schaefer_265_combined_2mm_specificity_new_T1_nuisance_after_ICA';
        print_header('Basedir is from MPC-Wani | Schaefer atlas | Rescaled to 16bit option'); 
    elseif strcmp(varargin{:}, 'rerun_preproc') 
        mid_name = 'mean_sig_Schaefer_265_combined_2mm_specificity_rerun';
        print_header('Basedir is from MPC-Wani | Schaefer atlas | Rerun Preproc option'); 
    end 
end 

caps_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/DCC/*caps*']));
rest_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/DCC/*resting*']));
quinine_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/DCC/*quinine*']));

connectivity_cell =[];
connectivity = [];
for file_idx = 1:length(caps_files) % Change later
    connectivity_cell{1, file_idx} = load(caps_files{file_idx}).dfc_dat;
    connectivity_cell{2,file_idx} = load(rest_files{file_idx}).dfc_dat;
    connectivity_cell{3,file_idx} = load(quinine_files{file_idx}).dfc_dat;
    print_header(['Done Connectivity: ' num2str(file_idx)]);

end 


% Matching the duration to normal sessions
connectivity = connectivity_cell;
rm_TR_start = round(17/0.46); %17 sec from the start
rm_TR_end = round(30/0.46); %30 sec from the end
for file_idx = 1:length(caps_files) % Change later
    for run_idx = 1: size(connectivity_cell, 1)
        connectivity{run_idx, file_idx}(:,1:rm_TR_start) = [];
        connectivity{run_idx, file_idx}(:,(end-rm_TR_end):end) = [];
    end
end

% Removing the stimulus deliver and removal period
for i = 1:size(connectivity, 2)
    start_TR = round(34.6/0.46); %75TR
    finish_TR = round(74.6/0.46);%162TR
    if size(connectivity{1,i},2) == 1510
        connectivity{1,i}(:, start_TR:finish_TR) = []; % only applicable for caps & correctly interpolated data
        connectivity{3,i}(:, start_TR:finish_TR) = []; % only applicable for caps & correctly interpolated data
    end
end


% HRF 
A_caps_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/Activation/hrf_voxel*caps*']));
A_rest_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/Activation/hrf_voxel*resting*']));
A_quinine_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/Activation/hrf_voxel*quinine*']));
  hrf_voxel =[];
for file_idx = 1:length(A_caps_files) 
    hrf_voxel{1, file_idx} = load(A_caps_files{file_idx}).voxel_beta_dat;
    hrf_voxel{2,file_idx} = load(A_rest_files{file_idx}).voxel_beta_dat;
    hrf_voxel{3,file_idx} = load(A_quinine_files{file_idx}).voxel_beta_dat;
    print_header(['Done HRF voxel: ' num2str(file_idx)]);
end 

if ~isempty(varargin) && strcmp(varargin{:}, 'boxcar_roi')  
    % boxcar roi 
    A_caps_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/Activation/boxcar_roi*caps*']));
    A_rest_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/Activation/boxcar_roi*resting*']));
    A_quinine_files = filenames(fullfile(basedir, ['results/' mid_name '/sub-mpc*/data/Activation/boxcar_roi*quinine*']));
    for file_idx = 1:length(A_caps_files)
        boxcar_roi{1, file_idx} = load(A_caps_files{file_idx}).roi_meants_dat;
        boxcar_roi{2,file_idx} = load(A_rest_files{file_idx}).roi_meants_dat;
        boxcar_roi{3,file_idx} = load(A_quinine_files{file_idx}).roi_meants_dat;
    end
    boxcar_roi_new = cellfun(@transpose, boxcar_roi,  'UniformOutput', false);
    % Matching the duration to normal sessions
    boxcar_roi_final = boxcar_roi_new;
    rm_TR_start = round(17/0.46); %17 sec from the start
    rm_TR_end = round(30/0.46); %30 sec from the start
    for file_idx = 1:length(caps_files) % Change later
        for run_idx = 1: size(boxcar_roi_new, 1)
            boxcar_roi_final{run_idx, file_idx}(:,1:rm_TR_start) = [];
            boxcar_roi_final{run_idx, file_idx}(:,(end-rm_TR_end):end) = [];
        end
    end

    % Removing the stimulus deliver and removal period
    for i = 1:size(boxcar_roi_final, 2)
        start_TR = round(34.6/0.46); %75TR
        finish_TR = round(74.6/0.46);%162TR
        if size(boxcar_roi_final{1,i},2) == 1510
            boxcar_roi_final{1,i}(:, start_TR:finish_TR) = []; % only applicable for caps & correctly interpolated data
            boxcar_roi_final{3,i}(:, start_TR:finish_TR) = []; % only applicable for caps & correctly interpolated data
        end
    end


end 

    else % Only load behavioral
%% ========= Behavioral Data
TR = 0.46;
clear behavioral_caps behavioral_rest behavioral_quinine
% Preallocate matrices for each condition with rows for each week
weeks = {'week34*', 'week36*', 'week37*', 'week38*'};
zero_padding = zeros(1, round(4.6 / 0.46));

for week_idx = 1:length(weeks)
    % Construct file paths
    caps_file = filenames(['/home/anel/nas1/data/MPC/MPC_wani/behavioral/raw/scanner/' weeks{week_idx} '/*_caps_MPC.mat']);
    quinine_file = filenames(['/home/anel/nas1/data/MPC/MPC_wani/behavioral/raw/scanner/' weeks{week_idx} '/*_quinine_MPC.mat']);
    rest_file =filenames(['/home/anel/nas1/data/MPC/MPC_wani/behavioral/raw/scanner/' weeks{week_idx} '/*001_resting_MPC.mat']);
    
    % Load data for each condition
    caps_behavioral = load(caps_file{1});
    raw_caps = caps_behavioral.data.dat.continuous_rating;
    
    quinine_behavioral = load(quinine_file{1});
    raw_quinine = quinine_behavioral.data.dat.quin_continuous_rating;
    
    rest_behavioral = load(rest_file{1});
    raw_rest = rest_behavioral.data.dat.continuous_rating;
    
    % Interpolate data
    [~, ratings_tr_caps] = ALL_behavioral_mint.interpolate({raw_caps}, TR);
    [~, ratings_tr_quinine] = ALL_behavioral_mint.interpolate({raw_quinine}, TR);
    [~, ratings_tr_rest] = ALL_behavioral_mint.interpolate({raw_rest}, TR);

    if week_idx == 2 
        remove_from_start_TR = round(28/TR);
        ratings_tr_caps{1}(1:remove_from_start_TR, :) = [];
        ratings_tr_quinine{1}(1:remove_from_start_TR, :) = [];
        ratings_tr_rest{1}(1:remove_from_start_TR, :) = [];
    end 


    if week_idx == 3 || week_idx == 4
        if week_idx == 3
            remove_from_start_TR = round(30/TR);
            remove_from_end_TR = round(28/TR);
            ratings_tr_caps{1}(1:remove_from_start_TR, :) = [];
            ratings_tr_caps{1}((end-remove_from_end_TR)+1:end, :) = [];
             ratings_tr_rest{1}(1:remove_from_start_TR, :) = [];
        ratings_tr_rest{1}((end-remove_from_end_TR)+1:end, :) = [];
        elseif week_idx == 4
            remove_from_start_TR = round(30/TR);
            remove_from_end_TR = round(25/TR);
            ratings_tr_caps{1}(1:remove_from_start_TR, :) = [];
            ratings_tr_caps{1}((end-remove_from_end_TR):end, :) = [];
             ratings_tr_rest{1}(1:remove_from_start_TR, :) = [];
        ratings_tr_rest{1}((end-remove_from_end_TR):end, :) = [];
        end

        ratings_tr_quinine{1}(1:remove_from_start_TR, :) = [];
        ratings_tr_quinine{1}((end-remove_from_end_TR):end, :) = [];

        
    end

    if ~isempty(varargin) && any(cellfun(@(x) strcmp(x, 'no_zero_padding'), varargin))
        % Zero-padding
        behavioral.caps(week_idx, :) = ratings_tr_caps{1, 1}';
        behavioral.quinine(week_idx, :) = ratings_tr_quinine{1, 1}';
        behavioral.rest(week_idx, :) = ratings_tr_rest{1, 1}';
    else
        % Zero-padding
        behavioral.caps(week_idx, :) = [zero_padding, ratings_tr_caps{1, 1}'];
        behavioral.quinine(week_idx, :) = [zero_padding, ratings_tr_quinine{1, 1}'];
        behavioral.rest(week_idx, :) = [zero_padding, ratings_tr_rest{1, 1}'];

    end
    print_header(['Done Behavioral: ' num2str(week_idx)]);
end 
    end
end 