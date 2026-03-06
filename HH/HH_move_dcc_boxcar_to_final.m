function HH_move_dcc_boxcar_to_final(dir_old, dir_new, participants)

% Function to move DCC files from a folder without suffix to the final participant savedir.
% Adds folder_dir_suffix to the folder name in the final savedir.
% Additionally, copies ROI files and renames part of the file name.

%% Inputs:
% dir_old: Directory where DCC and ROI files are located.
% dir_new: Directory where files will be copied.
% participants: Cell array containing the list of participant IDs.

%% Example usage:
% HH_move_dcc_boxcar_to_final('/path/to/data', '/path/to/save', {'P1', 'P2', 'P3'})

% Loop through each participant
for i = 1:numel(participants)
    participant = participants{i};
    
    %% Copy DCC files
    source_dir_dcc = fullfile(dir_old, participant, 'data', 'DCC');
    target_dir_dcc = fullfile(dir_new, participant, 'data', 'DCC');
    
    % Check if the target DCC directory exists, if not, create it
    if ~exist(target_dir_dcc, 'dir')
        mkdir(target_dir_dcc);
    end
    
    % Get the list of DCC files to copy
    dcc_files = dir(fullfile(source_dir_dcc, '*.mat'));
    fprintf('For %s moving %d DCC files.\n', participant, numel(dcc_files));
    
    % Copy each DCC file to the target directory
    for j = 1:length(dcc_files)
        source_file = fullfile(source_dir_dcc, dcc_files(j).name);
        target_file = fullfile(target_dir_dcc, dcc_files(j).name);
        
        % Copy the file
        copyfile(source_file, target_file);
        fprintf('Copied %s to %s\n', source_file, target_file);
    end

    %% Copy ROI files and rename
    source_dir_roi = fullfile(dir_old, participant, 'data', 'ROI');
    target_dir_roi = fullfile(dir_new, participant, 'data', 'Activation');
    
    % Check if the target Activation directory exists, if not, create it
    if ~exist(target_dir_roi, 'dir')
        mkdir(target_dir_roi);
    end
    
    % Get the list of ROI files starting with 'roi_timeseries_mean_sig_'
    roi_files = dir(fullfile(source_dir_roi, 'roi_timeseries_mean_sig_*.mat'));
    fprintf('For %s moving %d ROI files.\n', participant, numel(roi_files));
    
    % Copy and rename each ROI file to the target Activation directory
    for j = 1:length(roi_files)
        source_file = fullfile(source_dir_roi, roi_files(j).name);
        
        % Rename 'roi_timeseries' to 'boxcar_roi'
        new_filename = strrep(roi_files(j).name, 'roi_timeseries', 'boxcar_roi');
        target_file = fullfile(target_dir_roi, new_filename);
        
        % Copy the file
        copyfile(source_file, target_file);
        fprintf('Copied and renamed %s to %s\n', source_file, target_file);
    end
end

fprintf('DCC and ROI files successfully moved and renamed for all participants.\n');
end
