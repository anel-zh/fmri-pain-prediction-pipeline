function [spike_percentage, num_potential_outliers, global_snr] = get_spike_diary__on_mpc_subfunction(diary_file)
    % Read the diary text file
    diary_text = fileread(diary_file);
    
    % Find lines containing session information
    pattern_spikes = '%Spikes: (\d+\.\d+)';
    matches_spikes = regexp(diary_text, pattern_spikes, 'tokens');
    spike_percentage = str2double(matches_spikes{1});

    pattern_num_potential_outliers = 'Session\s+\d+:\s+(\d+)\s+Potential outliers';
    matches_num_potential_outliers = regexp(diary_text, pattern_num_potential_outliers, 'tokens');
    num_potential_outliers = str2double(matches_num_potential_outliers{1});


    pattern_global_snr = 'Global SNR \(Mean/STD\): (\d+\.\d+)';
    matches_global_snr = regexp(diary_text, pattern_global_snr, 'tokens');
    global_snr = str2double(matches_global_snr{1});
end
