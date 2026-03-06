function PC_range = HH_PC_range_by_condition(config_structure, PC_range_split, option, varargin)
%% Function: Get the range of possible PCs for hypertunning
% Author: Anel Zhunussova
% Last Update: 9 January 2025
% Details:
%     - Calculates the range of principal components (PCs) to test based on input conditions.
%     - Adjusts PC range based on binning, training data size, and brain measure type.
%     - Supports additional options such as 'cut_DCC' for connectivity data.

% Logic:
%     1. Determine the number of training subjects based on the specified option or default to 'main' -> YE's split and to adopt for both MPC-Wani and MPC-100.
%     2. Calculate the total number of bins:
%         - Based on model input condition ('caps', 'caps_rest').
%         - Adjust for binning conditions ('same_time_window', 'same_bin_number').
%         - Handle special cases like 'cut_DCC' to adjust total bins. ->
%         should be default based on final option.
%     3. Determine the maximum number of PCs:
%         - For connectivity or voxel-based brain measures: total_bin * train_n.
%         - For activation-based brain measures: limit by atlas size (e.g., Schaefer or Fan).
%     4. Adjust the maximum number of PCs for cross-validation:
%         - Exclude one fold and the last PC value. (based on how the
%         cv_pcr function operates)
%     5. Generate the PC range based on the specified split size.

% Output:
%     - PC_range: Array of principal components to test, evenly spaced up to the maximum allowed PCs.

% Example Usage:
%     PC_range = HH_PC_range_by_condition(config_structure, 10, 'main', 'cut_DCC');

if nargin < 3 
    train_n = length(config_structure.model_split.main.train_id);
else
    train_n = length(config_structure.model_split.(option).train_id);
end 
model_input_condition = config_structure.loop_model_input_condition;
binning_condition = config_structure.loop_binning_condition;
print_header("CHANGE PC_RANGE IF NOT 90 TR BIN");
caps_bin_n = config_structure.binning_parameters.same_time_window.main.CAPS_bin_number;
rest_bin_n = config_structure.binning_parameters.same_time_window.main.REST_bin_number;
brain_measure = config_structure.loop_brain_measure;
atlas_name = config_structure.atlas_name;

% Calculting total bin 
if strcmp(model_input_condition, 'caps')
    total_bin = caps_bin_n;
elseif strcmp(model_input_condition, 'caps_rest')
    if strcmp(binning_condition, 'same_time_window')
        total_bin = caps_bin_n + rest_bin_n;
    else
        total_bin = caps_bin_n * 2; % Assumes binning_condition is 'same_bin_number'
    end
else
    error('Invalid model_input_condition');
end

if strcmp(varargin{1},'cut_DCC')
    total_bin = total_bin-1;
end

if contains(brain_measure,'connectivity') || contains(brain_measure, 'voxel')
    max_PCs_all = total_bin * train_n;
elseif contains(brain_measure, 'roi') || contains(brain_measure, 'pc')
    if strcmp(atlas_name, 'Schaefer_265_combined_2mm') == 1
        max_PCs_bin = total_bin * train_n;
        max_PCs_atlas = 265;
        max_PCs_all = min(max_PCs_bin, max_PCs_atlas);
    elseif strcmp(atlas_name, 'Fan_r279_MNI_2mm') == 1
        max_PCs_bin = total_bin * train_n;
        max_PCs_atlas = 279;
        max_PCs_all = min(max_PCs_bin, max_PCs_atlas);
    else
        disp('Check atlas name, error has occured at the connectivity plotting stage.');
    end
end

max_PCs_cv = max_PCs_all - total_bin - 1; % removing one fold and 1 last PC value as in the cv_pcr function
PC_range = [1:PC_range_split:max_PCs_cv, max_PCs_cv];

end

