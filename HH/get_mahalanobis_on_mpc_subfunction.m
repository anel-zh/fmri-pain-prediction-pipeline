function [id, print_text] = get_mahalanobis_on_mpc_subfunction(PREPROC, run_n, window_size, TR)

    if length(PREPROC.nuisance.spike_covariates) < 10
        id = {PREPROC.subject_code};
        print_text = cell(3, 1);
        for j = 1:3
            print_text{j} = 'No nuisance covariates, manual input required';
        end
        return;
    end

    num_windows = ceil(length(PREPROC.nuisance.spike_covariates{run_n}) / window_size);
    num_spikes = zeros(num_windows, 1);
    spike_counts = cell(1, num_windows);

    % Iterate through the data with fixed-size windows and counting # of
    % spikes in that window
    for i = 1:num_windows
        start_index = (i - 1) * window_size + 1;
        end_index = i*window_size;
        if i == num_windows
            end_index = length(PREPROC.nuisance.spike_covariates{run_n});
        end 
        
        [spike_counts{i}, ~, ~] = find(PREPROC.nuisance.spike_covariates{run_n}(start_index:end_index, :));
        if ~isempty(spike_counts{i})
            spike_counts{i} = unique(spike_counts{i});
            num_spikes(i) = numel(spike_counts{i});
        end
    end

    % Find the top 3 periods with maximum spike count
    [sorted_counts, sorted_indices] = sort(num_spikes, 'descend');
    top_periods_indices = sorted_indices(1:3);
    top_periods_spike_counts = sorted_counts(1:3);

    id = {PREPROC.subject_code};
    print_text = cell(3, 1);
    for j = 1:3
        print_text{j} = ['Period ', num2str(top_periods_indices(j)*window_size), 'TR/', num2str(top_periods_indices(j)*window_size*TR), 'sec: Spike count = ', num2str(top_periods_spike_counts(j))];
    end
end 
