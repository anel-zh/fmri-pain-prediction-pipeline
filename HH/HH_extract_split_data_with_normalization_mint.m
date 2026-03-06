function [train_data, valid_data, test_data, vn_data_std_all] = HH_extract_split_data_with_normalization_mint(config_structure, option, z_scaling, vn_scaling, varargin)
%% Function: HH_extract_split_data_with_normalization_mint
% Author: Anel Zhunussova
% Last Update: 9 January 2025
% Details:
%     - Extracts training, validation, and testing data based on participant IDs.
%     - Handles behavioral data (caps, rest, quinine) and optional additional datasets.
%     - Supports variance and z-score normalization.

% Logic:
%     1. Get participant indices for train, validation, and test sets.
%     2. Assign behavioral data to train, valid, and test splits.
%     3. Process varargin datasets with/without normalization.

% Output:
%     - Structs for train, validation, and test splits with normalized and raw data.
%     - Standard deviations for variance normalization.


%% Function 
    function data_subset = extract_subset(data, indices)
        if iscell(data)
            data_subset = data(:, indices);
        else
            data_subset = data(indices, :);
        end
    end

    % Helper function for variance normalization
    function [normalized_data, data_std] = variance_normalization(data, indices)
        data_std = std(cat(2, data{indices}), 0, 2);
        normalized_data = cellfun(@(x) x ./ data_std, data(indices), 'UniformOutput', false);
    end

    % Helper function for z-score normalization
    function [normalized_data, data_mean, data_std] = z_score_normalization(data, indices)
        data_cat = cat(2, data{indices});
        data_mean = mean(data_cat, 2);
        data_std = std(data_cat, 0, 2);
        normalized_data = cellfun(@(x) (x - data_mean) ./ data_std, data(indices), 'UniformOutput', false);
    end

    % Apply normalization to validation and test data using training stats
    function normalized_data = apply_normalization(data, indices, data_mean, data_std, norm_type)
        if strcmp(norm_type, 'variance')
            normalized_data = cellfun(@(x) x ./ data_std, data(indices), 'UniformOutput', false);
        elseif strcmp(norm_type, 'z_score')
            normalized_data = cellfun(@(x) (x - data_mean) ./ data_std, data(indices), 'UniformOutput', false);
        end
    end

    % Extract needed variables
    participants_to_analyze = config_structure.participants_to_analyze.(option);
    train_id = config_structure.model_split.(option).train_id;
    valid_id = config_structure.model_split.(option).valid_id;
    test_id = config_structure.model_split.(option).test_id;
    behavioral_caps = config_structure.behavioral_data.(option).caps;
    behavioral_rest = config_structure.behavioral_data.(option).rest;
 
    % Get indices for training, validation, and testing
    train_indices = find(ismember(participants_to_analyze, train_id));
    valid_indices = find(ismember(participants_to_analyze, valid_id));
    test_indices = find(ismember(participants_to_analyze, test_id));

    % Initialize data structures
    train_data = struct();
    valid_data = struct();
    test_data = struct();

    % Assign behavioral data without normalization
    train_data.behavioral_caps = extract_subset(behavioral_caps, train_indices);
    train_data.behavioral_rest = extract_subset(behavioral_rest, train_indices);
    valid_data.behavioral_caps = extract_subset(behavioral_caps, valid_indices);
    valid_data.behavioral_rest = extract_subset(behavioral_rest, valid_indices);
    test_data.behavioral_caps = extract_subset(behavioral_caps, test_indices);
    test_data.behavioral_rest = extract_subset(behavioral_rest, test_indices);

    if isfield(config_structure.behavioral_data.(option), 'quinine')
        behavioral_quinine = config_structure.behavioral_data.(option).quinine;
        train_data.behavioral_quinine = extract_subset(behavioral_quinine, train_indices);
        valid_data.behavioral_quinine = extract_subset(behavioral_quinine, valid_indices);
        test_data.behavioral_quinine = extract_subset(behavioral_quinine, test_indices);
    end

    % Process each varargin input for connectivity and/or activation data
    for k = 1:length(varargin)
        data_cell = varargin{k};
        if ~isempty(data_cell)
            var_name = inputname(k + 4); % Get the name of the variable passed in varargin based on the loop number
            conditions = {'caps', 'rest'};
            if size(data_cell, 1) > 2
                conditions = {'caps', 'rest', 'quinine'};
                disp('quinine will be also analyzed');
            end

            for j = 1:length(conditions)
                condition = conditions{j};
                field_name = sprintf('%s_%s', var_name, condition);

                % Extract data without normalization
                train_data.no_scaling.(field_name) = extract_subset(data_cell(j, :), train_indices);
                valid_data.no_scaling.(field_name) = extract_subset(data_cell(j, :), valid_indices);
                test_data.no_scaling.(field_name) = extract_subset(data_cell(j, :), test_indices);

                % Ensure data is numeric for normalization
                condition_data = data_cell(j, :);

                % Variance normalization
                if vn_scaling
                    [train_data.variance_normalized.(field_name), data_std] = variance_normalization(condition_data, train_indices);
                    vn_data_std_all.(field_name) = data_std;
                    valid_data.variance_normalized.(field_name) = apply_normalization(condition_data, valid_indices, [], data_std, 'variance');
                    test_data.variance_normalized.(field_name) = apply_normalization(condition_data, test_indices, [], data_std, 'variance');
                end
                % Z-score normalization
                if z_scaling
                    [train_data.z_scored.(field_name), data_mean, data_std] = z_score_normalization(condition_data, train_indices);
                    valid_data.z_scored.(field_name) = apply_normalization(condition_data, valid_indices, data_mean, data_std, 'z_score');
                    test_data.z_scored.(field_name) = apply_normalization(condition_data, test_indices, data_mean, data_std, 'z_score');
                end
            end
        end
    end
end
