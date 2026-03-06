function binning_parameters = HH_get_binning_param_mint(config_structure)
fields  = fieldnames(config_structure);
binning_main = config_structure.binning_parameters.same_time_window.main;

if any(contains(fields, 'loop_binning'))
    binning_condition = config_structure.loop_binning_condition;
else 
    binning_condition = 'same_time_window'; % default
end 


%% Function: Helper inside the functions
% Author: Anel Zhunussova 
% Last Update: 11th October 2024
% Details:
%     - Getting the bin duration and number of bins

% Binning
    switch binning_condition
        case 'same_time_window'
            num_bins_caps = binning_main.CAPS_bin_number;
            num_bins_rest = binning_main.REST_bin_number;

            window_size_TR_caps = binning_main.Window_size_TR;
            window_size_TR_rest = window_size_TR_caps;
        case 'same_bin_number'
            num_bins_caps = binning_main.CAPS_bin_number;
            num_bins_rest = num_bins_caps;

            window_size_TR_caps = binning_main.Window_size_TR;
            rest_TR = 794;
            window_size_TR_rest = floor(rest_TR / binning_main.CAPS_bin_number);
        otherwise
            disp('Recheck the binning_condition, should be same_time_window or same_bin_number.');
            return;
    end
    
% Run
binning_parameters.rest.window_size_TR = window_size_TR_rest;
binning_parameters.rest.num_bins = num_bins_rest;

binning_parameters.caps.window_size_TR = window_size_TR_caps;
binning_parameters.caps.num_bins = num_bins_caps;
binning_parameters.binning_condition = binning_condition; % double-checking

end 
