%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 15th May 2024
% Goal: 
%     - Dataset: MPC- 100. 
%     - Quality control for FD, Mahalanobis, Spike Diary 
%     - The functions are made to exctract metrics for Caps and Rest run
%     from MPC-100 and MPC-Wani.
%     - threshold_mvmn_pry = 5;  % pitch roll yaw threshold optional; they
%     are * head (50);
%     - Dependencies: get_fd_on_mpc.m; get_spike_diary_on_mpc.m;
%     get_mahalnobis_on_mpc.m + get_spike_diary_on_mpc_subfunction.m;
%     get_mahalnobis_on_mpc_subfunction.m 
%     - Output: Excel files & structures

%% Loading directories
basedir = '/home/anel/nas1/projects/MINT/analysis/imaging/quality_control';
addpath(fullfile(basedir, 'scripts/functions/'));
savedir = fullfile(basedir, 'results/');
%% MPC - 100
preproc_dir_path_100 = '/home/anel/nas1/data/MPC/MPC_100/imaging/preprocessed';
subject_dirs_100 = dir(fullfile(preproc_dir_path_100, 'sub-*'));
preproc_subject_dir_100 = fullfile(preproc_dir_path_100, {subject_dirs_100.name});
preproc_subject_dir_100([12,43])=[]; % session MPC052 - no caps_run10; session MPC053 - anatomical problem

% Exctracting needed QC metrics
% FD, mean FD & movemement
threshold_mvmn_xyz = 5; 
FD_T100 = get_fd_on_mpc(preproc_subject_dir_100, threshold_mvmn_xyz);

% Mahalanobis - top 3 periods with spikes
window_size = 50; % in terms of TR
TR = 0.46;
mahalanobis_T100 = get_mahalanobis_on_mpc(preproc_subject_dir_100, window_size, TR); 

% QC diary - number of potential outliers, %spikes, global SNR.
snr_theshold_caps = 200;
snr_theshold_rest = 200;
spike_diary_T100 = get_spike_diary_on_mpc(preproc_subject_dir_100, snr_theshold_caps,snr_theshold_rest);

% Merging and Saving results   
% Save FD_T100 into Excel file with sheet name 'FD_T100'
savename_T100 = fullfile(savedir,'QC_MPC_100_15May.xlsx');
if ~exist(savename_T100, 'file')
    writetable(FD_T100,savename_T100, 'Sheet', 'FD');
    writetable(mahalanobis_T100, savename_T100, 'Sheet', 'Mahalanobis');
    writetable(spike_diary_T100, savename_T100, 'Sheet', 'Spike_QC_Diary');
    fprintf('Results are saved at %s', savename_T100);
else 
    fprintf('File already exists at:%s', savename_T100);
end 

% Creating a structure
T100 = [FD_T100, mahalanobis_T100(:,2:end), spike_diary_T100(:,2:end)]; 
T100_structure_scalar = table2struct(T100, 'ToScalar', true);
T100_structure = table2struct(T100); % T100_structure(1)

save(fullfile(savedir,'QC_MPC_100.mat'), 'T100_structure');
save(fullfile(savedir,'QC_MPC_100_scalar.mat'), 'T100_structure_scalar');

%% MPC - Wani
preproc_dir_path_wani = '/home/anel/nas1/data/MPC/MPC_wani/imaging/preprocessed/MNI_youngeun/preprocessed/';
subject_dirs_wani = dir(fullfile(preproc_dir_path_wani, 'sub-*'));
preproc_subject_dir_wani = fullfile(preproc_dir_path_wani, {subject_dirs_wani.name});
preproc_subject_dir_wani([5, 32, 33])=[]; % MPC005 - no caps_run10, MPC032 - no caps_10run10, MPC033 - no scan data for caps

% Exctracting needed QC metrics (Change the options from MPC-100 if needed)
FD_TWani = get_fd_on_mpc(preproc_subject_dir_wani, threshold_mvmn_xyz);
mahalanobis_TWani = get_mahalanobis_on_mpc(preproc_subject_dir_wani, window_size, TR); 
spike_diary_TWani = get_spike_diary_on_mpc(preproc_subject_dir_wani, snr_theshold_caps,snr_theshold_rest);

% Save the results
savename_TWani = fullfile(savedir,'QC_MPC_Wani_15May.xlsx');
if ~exist(savename_TWani, 'file')
    writetable(FD_TWani,savename_TWani, 'Sheet', 'FD');
    writetable(mahalanobis_TWani, savename_TWani, 'Sheet', 'Mahalanobis');
    writetable(spike_diary_TWani, savename_TWani, 'Sheet', 'Spike_QC_Diary');
    fprintf('Results are saved at %s', savename_TWani);
else 
    fprintf('File already exists at:%s', savename_TWani);
end 

% Create a structure
TWani = [FD_TWani, mahalanobis_TWani(:,2:end), spike_diary_TWani(:,2:end)];
TWani_structure_scalar = table2struct(TWani, 'ToScalar', true);
TWani_structure = table2struct(TWani); % TWani_structure(1)

save(fullfile(savedir,'QC_MPC_Wani.mat'), 'TWani_structure');
save(fullfile(savedir,'QC_MPC_Wani_scalar.mat'), 'TWani_structure_scalar');

