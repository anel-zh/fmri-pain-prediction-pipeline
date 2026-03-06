function input_onsets = HH_get_onset_duration_mint(total_TR, binning_parameters, run_condition, varargin)

cut_duration = true; % Default final model
for var_idx = 1:length(varargin)
    switch varargin{var_idx}
        case 'cut_duration'
            cut_duration = varargin{var_idx+1};
    end 
end 

%% Info
% [Normal caps]
% Sessions 1-4: 1836
% Sessions after: 1510  


    TR = 0.46;
    window_size_TR = binning_parameters.(run_condition).window_size_TR;
    num_bins = binning_parameters.(run_condition).num_bins;

    if strcmp(run_condition, 'rest')
        start_onset = 0; 
        if total_TR > 794
            total_TR = 794; 
            end_onset = total_TR*TR;
        else 
            end_onset = total_TR*TR;
        end 


    elseif strcmp(run_condition, 'caps')
        if cut_duration
            total_TR_threshold = 1510;
            start_onset_second_bin_longer_duration = 104.6;
            start_onset_second_bin_main = 74.6;
        end

        if total_TR > total_TR_threshold 
            if cut_duration
                start_onset = start_onset_second_bin_longer_duration; 
                num_bins = num_bins -2; % since first bin is set separately + 40 sec removed
                end_onset = total_TR_threshold*TR;
            else
                start_onset = 30; % sec 
                end_onset = total_TR_threshold*TR + start_onset;
            end
            
        else 
            if cut_duration 
                start_onset = start_onset_second_bin_main;
                num_bins = num_bins - 2;
            else 
                start_onset = 0;
            end
            end_onset = total_TR*TR;
        end 
    end 

    onsets = (start_onset:(window_size_TR*TR):(end_onset - window_size_TR*TR))';
    durations = repmat(window_size_TR*TR, num_bins, 1);

    input_onsets = cell(num_bins,1);
    for bin_idx = 1:num_bins
        input_onsets{bin_idx} = [onsets(bin_idx) durations(bin_idx)];
    end
    
    if cut_duration && strcmp(run_condition, 'caps') 
        if total_TR > total_TR_threshold
            first_bin = {[30 20.0000]};
        else
            first_bin = {[0 20.0000]};
        end
        input_onsets = [first_bin; input_onsets];
    end 

%  pagesetup(gcf);
%         figure
%         set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
%         X = plotDesign_mint(input_onsets,[], TR,length_scan, 'samefig', spm_hrf(1), 'singletrial');
%         saveas(gcf, fullfile(fig_save_dir,['design_matrix_' design_matrix_name]));
%         close all
%
%         set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
%         create_figure('vifs'); vif = getvif(X, 0, 'plot');
%         saveas(gcf, fullfile(fig_save_dir,['vif_' design_matrix_name]));



%% Script to find the first bin duration 
% caps_TR = 1510;
% TR = 0.46;
% binning_parameters = HH_get_binning_param_mint(config_structure);
% input_onsets = HH_get_onset_duration_mint(caps_TR, binning_parameters, 'caps');
% length_scan = caps_TR*TR;
% time_1st_bin_options = 2:-0.1:0.1;
% input_onsets_to_change = input_onsets;
% for time_idx = 1:length(time_1st_bin_options)
%     X = [];
%     non_zero_X = [];
%     time_1st_bin = time_1st_bin_options(time_idx);
%     input_onsets_to_change{1,1}(1,2) = time_1st_bin;
%     X = plotDesign_mint(input_onsets_to_change,[], 0.46, length_scan, 'samefig', spm_hrf(1), 'singletrial');
%     non_zero_X = find(X(:,1)==0);
%     if non_zero_X(2)*0.46 < 34.6
%         fprintf('The optimal duration bin is %d with the ending hrf curve at %d', time_1st_bin, non_zero_X(2)*0.46);
%         break
%     end
% end