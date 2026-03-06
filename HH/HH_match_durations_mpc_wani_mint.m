function modified_cell = HH_match_durations_mpc_wani_mint(raw_cell_df, varargin)
% Final output for CAPS should be 1510TR; rest 794TR (in replications
% sessions rest is 793TR)

modified_cell = raw_cell_df;
% ====== Logic
% start_removal_time_TR = round(30/0.46);
% end_removal_time_TR = base_time + start_removal_time_TR +1;

if ~isempty(varargin)
    if strcmp(varargin, 'DCC_cut')
        % The default duration matching
        for i = 1:4
            modified_cell{1,i}(:, [1:65,1576:end]) = [];
            modified_cell{2,i}(:, 795:end) = [];
        end
    elseif strcmp(varargin, 'DCC_cut_replication')
        % Matching the duration to normal sessions
        rm_TR_start = round(17/0.46); %17 sec from the start
        rm_TR_end = round(30/0.46); %30 sec from the end
        for file_idx = 1:size(modified_cell, 2)
            for run_idx = 1:size(modified_cell, 1)
                modified_cell{run_idx, file_idx}(:,1:rm_TR_start) = [];
                modified_cell{run_idx, file_idx}(:,(end-rm_TR_end):end) = [];
            end
        end
    end

end

% Apply the removal of the stimulus delivery period for the first row
if ~isempty(varargin)
    for var_idx = 1:length(varargin)
        switch varargin{var_idx}
            case {'DCC_cut', 'DCC_cut_replication'} % cut DCC size is 1422TR
                for i = 1:size(raw_cell_df, 2)
                    start_TR = round(34.6/0.46); %75TR
                    finish_TR = round(74.6/0.46);%162TR
                    if size(modified_cell{1,i},2) == 1510
                        modified_cell{1,i}(:, start_TR:finish_TR) = []; % only applicable for caps & correctly interpolated data
                        if size(raw_cell_df, 1) == 3 && size(modified_cell{3,i},2) == 1510 % includes quinine
                           modified_cell{3,i}(:, start_TR:finish_TR) = []; % only applicable for quinine & correctly interpolated data
                        end
                    end
                end
        end
    end
end
