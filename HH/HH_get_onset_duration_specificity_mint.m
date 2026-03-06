function input_onsets = HH_get_onset_duration_specificity_mint(run_condition, total_TR)

% cut duration is default since the analysis is done after deciding on the
% final model (Nov4 2024 comment).

%% Info
% [Normal caps]
% Sessions 1-4: 1836
% Sessions after: 1510
cut_duration = true;

TR = 0.46;
window_size_TR = 90;
if strcmp(run_condition, 'caps') || strcmp(run_condition, 'quinine')
    num_bins = 16;
else 
    num_bins = 8;
end 


% sub-mpc034
% start onset = as normal case with cut duration for caps run and
% normal case for rest

% sub-mpc036
% start onset = set the total_TR to to 1510 and start onset to 0

% sub-mpc037
% start onset = 30;

% sub-mpc038
% start onset = 30



if strcmp(run_condition, 'rest')
    start_onset = 0;
    if total_TR > 844
        start_onset = 30;
        end_onset = total_TR*TR + start_onset;
    else
        end_onset = total_TR*TR;
    end


elseif strcmp(run_condition, 'caps') || strcmp(run_condition, 'quinine')
    total_TR_threshold = 1561;
    start_onset_second_bin_longer_duration = 104.6;
    start_onset_second_bin_main = 74.6;


    if total_TR > total_TR_threshold
        start_onset = start_onset_second_bin_longer_duration;
        num_bins = num_bins -2; % since first bin is set separately + 40 sec removed
        end_onset = total_TR_threshold*TR;
    else
        start_onset = start_onset_second_bin_main;
        num_bins = num_bins - 2;
        end_onset = total_TR*TR;
    end
end

onsets = (start_onset:(window_size_TR*TR):(end_onset - window_size_TR*TR))';
durations = repmat(window_size_TR*TR, num_bins, 1);

input_onsets = cell(num_bins,1);
for bin_idx = 1:num_bins
    input_onsets{bin_idx} = [onsets(bin_idx) durations(bin_idx)];
end

if cut_duration && strcmp(run_condition, 'caps') || cut_duration && strcmp(run_condition, 'quinine')
    if total_TR > total_TR_threshold
        first_bin = {[30 20.0000]};
    else
        first_bin = {[0 20.0000]};
    end
    input_onsets = [first_bin; input_onsets];
end

end
