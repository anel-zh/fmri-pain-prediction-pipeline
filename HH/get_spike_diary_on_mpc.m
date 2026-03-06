function spike_diary_T = get_spike_diary_on_mpc(preproc_subject_dir, snr_theshold_caps, snr_theshold_rest)

    id = cell(numel(preproc_subject_dir), 1);
    caps_potential_outliers = zeros(numel(preproc_subject_dir), 1);
    caps_spikes_percentage = zeros(numel(preproc_subject_dir), 1);
    caps_global_snr_mean = zeros(numel(preproc_subject_dir), 1);
    rest_potential_outliers = zeros(numel(preproc_subject_dir), 1);
    rest_spikes_percentage = zeros(numel(preproc_subject_dir), 1);
    rest_global_snr_mean = zeros(numel(preproc_subject_dir), 1);
    snr_marked_caps = zeros(numel(preproc_subject_dir), 1);
    snr_marked_rest = zeros(numel(preproc_subject_dir), 1);

    
    % Loop through each subject directory
    for subj_idx = 1:numel(preproc_subject_dir)
        % For ID
        subject_dir = preproc_subject_dir{subj_idx};
        PREPROC = save_load_PREPROC(subject_dir, 'load');
        id{subj_idx} = PREPROC.subject_code;

        % For Data
        subject_dir = fullfile(preproc_subject_dir{subj_idx}, 'qc_images');
        runs_of_interest = {'caps', 'resting'};
        run_idx = 1;
        run = runs_of_interest{run_idx};
        diary_file = dir(fullfile(subject_dir, sprintf('qc_diary_*%s*.txt', run)));
        diary_file2 = fullfile(subject_dir, diary_file.name);
        [caps_spikes_percentage(subj_idx), caps_potential_outliers(subj_idx), caps_global_snr_mean(subj_idx)] = get_spike_diary_on_mpc_subfunction(diary_file2);
    
        run_idx = 2;
        run = runs_of_interest{run_idx};
        diary_file = dir(fullfile(subject_dir, sprintf('qc_diary_*%s*.txt', run)));
        diary_file2 = fullfile(subject_dir, diary_file.name);
        [rest_spikes_percentage(subj_idx), rest_potential_outliers(subj_idx), rest_global_snr_mean(subj_idx)] = get_spike_diary_on_mpc_subfunction(diary_file2);

    
        % Print header
        print_header('Exctraction of QC Diary (%Spike) is finished for: ', PREPROC.subject_code);
        
        if rest_global_snr_mean(subj_idx) < snr_theshold_rest
            snr_marked_rest(subj_idx) = 1;
        end 
        if caps_global_snr_mean(subj_idx) < snr_theshold_caps
            snr_marked_caps(subj_idx) = 1;
        end

    end

    variableNames = {'ID', ...
                 'CAPS: Potential Outliers', 'CAPS: %Spike', 'CAPS: Global SNR (Mean/STD)', sprintf('CAPS: Global SNR < %d', snr_theshold_caps), ...
                 'REST: Potential Outliers', 'REST: %Spike', 'REST: Global SNR (Mean/STD)', sprintf('REST: Global SNR < %d', snr_theshold_rest)};
                 
    spike_diary_T = table(id, ...
                caps_potential_outliers, caps_spikes_percentage, caps_global_snr_mean, snr_marked_caps, ...
                rest_potential_outliers, rest_spikes_percentage, rest_global_snr_mean, snr_marked_rest, ...
                'VariableNames', variableNames);

end

% Previous option of saving 
%     variableNames = {'ID', ...
%                  'CAPS: Potential Outliers', 'REST: Potential Outliers', 'CAPS: %Spike', 'REST: %Spike', ...
%                  'CAPS: Global SNR (Mean/STD)', 'REST: Global SNR (Mean/STD)', ...
%                  sprintf('CAPS: Global SNR < %d',snr_theshold_caps), sprintf('REST: Global SNR < %d',snr_theshold_rest)};
% 
%     spike_diary_T = table(id, caps_potential_outliers,rest_potential_outliers, caps_spikes_percentage, rest_spikes_percentage, ...
%                  caps_global_snr_mean, rest_global_snr_mean, ...
%                  snr_marked_caps, snr_marked_rest, ...
%                  'VariableNames',variableNames);