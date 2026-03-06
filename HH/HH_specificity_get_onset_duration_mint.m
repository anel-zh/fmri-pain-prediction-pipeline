function input_onsets = HH_specificity_get_onset_duration_mint(run_condition, total_TR)

% cut duration is default since the analysis is done after deciding on the
% final model (Nov4 2024 comment).

%% Info
% [Normal caps]
% Sessions 1-4: 1836s
% Sessions after: 1510
cut_duration = true;

TR = 0.46;
window_size_TR = 90;
if strcmp(run_condition, 'caps') || strcmp(run_condition, 'quinine')
    num_bins = 16;
    if total_TR ~=1613
        error('Double check TR')
    end 
else 
    num_bins = 8;
    if total_TR ~=896
        error('Double check TR')
    end 
end 

% start_onset -> 17 sec 
% remove from the end -> 30 sec
shift_from_start = 17;
if strcmp(run_condition, 'rest')
    start_onset = shift_from_start;
    end_onset = total_TR*TR + start_onset;
elseif strcmp(run_condition, 'caps') || strcmp(run_condition, 'quinine')
    start_onset = shift_from_start + 74.6; % 74.6 - usual case
    num_bins = num_bins -2; % since first bin is set separately + 40 sec removed
    end_onset = total_TR*TR;
end

onsets = (start_onset:(window_size_TR*TR):(end_onset - window_size_TR*TR))';
durations = repmat(window_size_TR*TR, num_bins, 1);

input_onsets = cell(num_bins,1);
for bin_idx = 1:num_bins
    input_onsets{bin_idx} = [onsets(bin_idx) durations(bin_idx)];
end

if cut_duration && strcmp(run_condition, 'caps') || cut_duration && strcmp(run_condition, 'quinine')
    first_bin = {[shift_from_start 20.0000]};
    input_onsets = [first_bin; input_onsets];
end

final_value = input_onsets{end}(1,1) + input_onsets{end}(1,2);
max_final_value = total_TR-30;

if final_value > max_final_value
    error('final value exceeds the duration');
end 

end
