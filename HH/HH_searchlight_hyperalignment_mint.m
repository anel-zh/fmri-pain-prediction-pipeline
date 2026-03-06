function [aligned_replication, transforms, best_template_index] = HH_searchlight_hyperalignment_mint(original_wani, spec_wani, varargin)
    % Perform searchlight hyperalignment between original and replication sessions
    % Author: Anel Zhunussova (still in development)
    % INPUTS:
    %   original_wani: 1x26 cell array, each cell is 190K x 15 matrix (original sessions).
    %   spec_wani: 1x4 cell array, each cell is 190K x 15 matrix (replication sessions).
    %   varargin: Optional, index of the best session to use as template.
    %
    % OUTPUTS:
    %   aligned_replication: 1x4 cell array of aligned replication sessions.
    %   transforms: 1x4 cell array of transformation parameters for replication sessions.
    %   best_template_index: Index of the best template session (original_wani).

    %% Parameters
    radius = 50; % Number of voxels in each searchlight
    num_voxels = size(original_wani{1}, 1); % Number of voxels (assumes all sessions are consistent)
    
    % Initialize outputs
    aligned_replication = cell(size(spec_wani));
    transforms = cell(size(spec_wani));
    
    % Determine template session
    if isempty(varargin)
        % Compute mean activation across all original sessions to find the best template
        template_index = 1; % Default to the first session
        max_similarity = -inf; % Placeholder for max similarity score
        for i = 1:length(original_wani)
            avg_activation = mean(original_wani{i}, 2); % Mean activation across bins
            similarity = mean(avg_activation); % Placeholder for more complex similarity metric
            if similarity > max_similarity
                max_similarity = similarity;
                template_index = i;
            end
        end
    else
        template_index = varargin{1}; % User-specified template session index
    end
    best_template_index = template_index;
    template_data = original_wani{template_index};

    %% Generate searchlight neighborhoods
    searchlights = cell(num_voxels, 1);
    for i = 1:num_voxels
        % Define neighbors (simplified to a range-based selection)
        start_idx = max(1, i - floor(radius / 2));
        end_idx = min(num_voxels, i + floor(radius / 2));
        searchlights{i} = start_idx:end_idx;
    end

    %% Align each replication session
    for s = 1:length(spec_wani)
        replication_data = spec_wani{s};
        aligned_session = zeros(size(replication_data)); % Initialize aligned session
        transform_session = cell(num_voxels, 1); % Save transformations for each searchlight

        % Align each searchlight
        for i = 1:num_voxels
            neighbors = searchlights{i}; % Current searchlight voxels
            template_patch = template_data(neighbors, :); % Template patch (voxels x time)
            replication_patch = replication_data(neighbors, :); % Replication patch
            
            % Perform Procrustes alignment
            [~, Z, transform] = procrustes(template_patch', replication_patch');
                                           %'scaling', true, 'reflection', false);
            
            aligned_session(neighbors, :) = aligned_session(neighbors, :) + Z'; % Add aligned data
            transform_session{i} = transform; % Save transformation
        end

        % Average overlapping regions
        voxel_counts = zeros(num_voxels, 1); % Count contributions per voxel
        for i = 1:num_voxels
            neighbors = searchlights{i};
            voxel_counts(neighbors) = voxel_counts(neighbors) + 1;
        end
        aligned_session = aligned_session ./ voxel_counts; % Normalize overlapping regions

        % Save aligned session and transformations
        aligned_replication{s} = aligned_session;
        transforms{s} = transform_session;
    end
end
