function tr_bins_same_window = HH_same_time_window_bins_mint(caps_bin_size_TR, min_only,  varargin)
%default for MINT
caps_TR = 1510;
rest_TR = 794;
TR = 0.46; 

if ~isempty(varargin)
   TR = varargin{1};
elseif numel(varargin) > 1
   caps_TR = varargin{2};
elseif numel(varargin) > 2
   rest_TR = varargin{3};
end 


Window_size_TR = {};
Window_size_sec = {};
CAPS_bin_number = {};
CAPS_discard_TR_number = {};
REST_bin_number = {};
REST_discard_TR_number = {};

% Loop over given bin sizes 
for bin_size = caps_bin_size_TR
    % Calculate the number of full bins that can be created for caps and rest data
    num_bins_caps = floor(caps_TR / bin_size);
    num_bins_rest = floor(rest_TR / bin_size);
    
    % Calculate discarded TRs
    discard_caps_TR = caps_TR - (num_bins_caps * bin_size);
    discard_rest_TR = rest_TR - (num_bins_rest * bin_size);
    
    % Append to the results arrays
    Window_size_TR{end+1} = bin_size;
    Window_size_sec{end+1} = bin_size*TR;
    CAPS_bin_number{end+1} = num_bins_caps;
    CAPS_discard_TR_number{end+1} = discard_caps_TR;
    REST_bin_number{end+1} = num_bins_rest;
    REST_discard_TR_number{end+1} = discard_rest_TR;
end

combined_table = table;

for i = 1:length(CAPS_bin_number)
    T = table(Window_size_TR{i}, Window_size_sec{i}, ...
              CAPS_bin_number{i}, REST_bin_number{i}, ...
              CAPS_discard_TR_number{i}, REST_discard_TR_number{i}, ...
              'VariableNames', {'Window_size_TR', 'Window_size (sec)', ...
                                'CAPS_bin_number', 'REST_bin_number', ...
                                'CAPS_discarded_TR','REST_discarded_TR'});
    combined_table = [combined_table; T]; 
end

% Loop through each unique CAPS_bin_number to find those with minimum disqard TR in CAPS among same binning options. 
min_discarded_rows = [];
unique_CAPS_bins = unique(combined_table.CAPS_bin_number);
for i = 1:length(unique_CAPS_bins)
    current_bin_number = unique_CAPS_bins(i);
    same_bin_rows = combined_table(combined_table.CAPS_bin_number == current_bin_number, :);
    [~, min_index] = min(same_bin_rows.CAPS_discarded_TR);
    min_discarded_rows = [min_discarded_rows; same_bin_rows(min_index, :)];
end

% Additionally, including 45-seconds time window as in ToPS (98TR)
if ~ismember(98, min_discarded_rows.Window_size_TR)
    TR_98 = find(combined_table.Window_size_TR == 98);
    min_discarded_rows = [min_discarded_rows; combined_table(TR_98, :)];
end

%CHANGE AS NEEDED
if min_only == 1
    tr_bins_same_window = min_discarded_rows;
else
    tr_bins_same_window = combined_table;
end

end