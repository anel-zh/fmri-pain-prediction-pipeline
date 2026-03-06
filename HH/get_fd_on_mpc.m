function FD_T = get_fd_on_mpc(preproc_subject_dir, threshold_mvmn_xyz,  threshold_mvmn_pry)
    % Initialize variables to store data for table
    id = cell(numel(preproc_subject_dir), 1);
    caps_mean_FD = zeros(numel(preproc_subject_dir), 1);
    caps_mean_FD_more_point_2 = zeros(numel(preproc_subject_dir), 1);
    caps_FD_max = zeros(numel(preproc_subject_dir), 1);
    caps_FD_max_more_5 = zeros(numel(preproc_subject_dir), 1);
    xyz_caps_max = cell(numel(preproc_subject_dir), 1);
    xyz_caps_more = zeros(numel(preproc_subject_dir), 1);
    pry_caps_max = cell(numel(preproc_subject_dir), 1);
    pry_caps_more = zeros(numel(preproc_subject_dir), 1);

    rest_mean_FD = zeros(numel(preproc_subject_dir), 1);
    rest_mean_FD_more_point_2 = zeros(numel(preproc_subject_dir), 1);
    rest_FD_max = zeros(numel(preproc_subject_dir), 1);
    rest_FD_max_more_5 = zeros(numel(preproc_subject_dir), 1);
    xyz_rest_max = cell(numel(preproc_subject_dir), 1);
    xyz_rest_more = zeros(numel(preproc_subject_dir), 1);
    pry_rest_max = cell(numel(preproc_subject_dir), 1);
    pry_rest_more = zeros(numel(preproc_subject_dir), 1);
    
    % Loop through each subject directory
    for subj_i = 1:numel(preproc_subject_dir)
        % Load PREPROC
        subject_dir = preproc_subject_dir{subj_i};
        PREPROC = save_load_PREPROC(subject_dir, 'load');
        data = PREPROC.framewise_displacement;
        
        % Calculating FD
        head = 50;
        
        % CAPS
        caps_mov= data.raw{1,10};
        caps_mov(:, 4:6) = head*caps_mov(:,4:6);
        delta_caps_mov = [zeros(1,size(caps_mov,2)); diff(caps_mov)];
        FD_caps = sum(abs(delta_caps_mov),2);
        MeanFd_caps = mean(FD_caps);

        % REST
        rest_mov = data.raw{1,1};
        rest_mov(:, 4:6) = head*rest_mov(:,4:6);
        delta_rest_mov = [zeros(1,size(rest_mov,2)); diff(rest_mov)];
        FD_rest = sum(abs(delta_rest_mov),2);
        MeanFd_rest = mean(FD_rest);
        
        % Extract data
        id{subj_i} = PREPROC.subject_code;
        caps_mean_FD(subj_i) = MeanFd_caps;
        caps_FD_max(subj_i) = max(abs(FD_caps));
        xyz_caps_max{subj_i} = max(abs(caps_mov(:,1:3)));
        rest_mean_FD(subj_i) = MeanFd_rest;
        rest_FD_max(subj_i) = max(abs(FD_rest));
        xyz_rest_max{subj_i} = max(abs(rest_mov(:,1:3)));
        pry_caps_max{subj_i} = max(abs(caps_mov(:,4:6)));
        pry_rest_max{subj_i} = max(abs(rest_mov(:,4:6)));
        
        % Calculate markers 
        caps_mean_FD_more_point_2(subj_i) = caps_mean_FD(subj_i) > 0.2;
        caps_FD_max_more_5(subj_i) = caps_FD_max(subj_i) > 5;
        rest_mean_FD_more_point_2(subj_i) = rest_mean_FD(subj_i) > 0.2;
        rest_FD_max_more_5(subj_i) = rest_FD_max(subj_i) > 5;
        xyz_caps_more(subj_i) = max(xyz_caps_max{subj_i}) > threshold_mvmn_xyz;
        xyz_rest_more(subj_i) = max(xyz_rest_max{subj_i}) > threshold_mvmn_xyz;
        
        % Calculate additional values only if threshold_mvmn_pry is provided
        if nargin == 3
            pry_caps_more(subj_i) = max(pry_caps_max{subj_i}) > threshold_mvmn_pry;
            pry_rest_more(subj_i) = max(pry_rest_max{subj_i}) > threshold_mvmn_pry;
        end
        
        % Print header
        print_header('Exctraction of FD & Mean FD finished for: ', PREPROC.subject_code);
    end

    % Convert numerical data to strings with specific format
    xyz_rest_max = cellfun(@(x) [num2str(x, '%0.2f | ')], xyz_rest_max, 'UniformOutput', false);
    xyz_caps_max = cellfun(@(x) [num2str(x, '%0.2f | ')], xyz_caps_max, 'UniformOutput', false);
    pry_caps_max = cellfun(@(x) [num2str(x, '%0.2f | ')], pry_caps_max, 'UniformOutput', false);
    pry_rest_max = cellfun(@(x) [num2str(x, '%0.2f | ')], pry_rest_max, 'UniformOutput', false);

    % Add column names for additional CAPS and REST data if pry threshold is provided
    if nargin == 3
        variableNames1 = {'ID', ...
             'CAPS: Mean FD', 'CAPS: Max FD', 'CAPS: Max XYZ', 'CAPS: Max (Pitch, Roll, Yaw)', ...
             'CAPS: Mean FD > 0.2', 'CAPS: Max FD > 5', ...
             sprintf('CAPS: Max XYZ > %d', threshold_mvmn_xyz), sprintf('CAPS: Max (Pitch, Roll, Yaw) > %d', threshold_mvmn_pry), ...
             'REST: Mean FD', 'REST: Max FD', 'REST: Max XYZ', 'REST: Max (Pitch, Roll, Yaw)', ...
             'REST: Mean FD > 0.2', 'REST: Max FD > 5', ...
              sprintf('REST: Max XYZ > %d', threshold_mvmn_xyz), sprintf('REST: Max (Pitch, Roll, Yaw) > %d', threshold_mvmn_pry)};
            
        FD_T = table(id, ...
                 caps_mean_FD, caps_FD_max, xyz_caps_max, pry_caps_max, ...
                 caps_mean_FD_more_point_2, caps_FD_max_more_5, ...
                 xyz_caps_more, pry_caps_more, ...
                 rest_mean_FD, rest_FD_max, xyz_rest_max, pry_rest_max, ...
                 rest_mean_FD_more_point_2, rest_FD_max_more_5, ...
                 xyz_rest_more, pry_rest_more, ...
                 'VariableNames', variableNames1);
    else
        variableNames2 = {'ID', ...
             'CAPS: Mean FD', 'CAPS: Max FD', ...
             'CAPS: Max XYZ', 'CAPS: Max (Pitch, Roll, Yaw)', ...
             'CAPS: Mean FD > 0.2', 'CAPS: Max FD > 5', ...
             sprintf('CAPS: Max XYZ > %d', threshold_mvmn_xyz), ...
             'REST: Mean FD', 'REST: Max FD', ...
             'REST: Max XYZ', 'REST: Max (Pitch, Roll, Yaw)', ...
             'REST: Mean FD > 0.2', 'REST: Max FD > 5', ...
             sprintf('REST: Max XYZ > %d', threshold_mvmn_xyz)};
            
        FD_T = table(id, ...
                 caps_mean_FD, caps_FD_max, xyz_caps_max, pry_caps_max, ...
                 caps_mean_FD_more_point_2, caps_FD_max_more_5, ...
                 xyz_caps_more, ...
                 rest_mean_FD, rest_FD_max, xyz_rest_max, pry_rest_max, ...
                 rest_mean_FD_more_point_2, rest_FD_max_more_5, ...
                 xyz_rest_more, ...
                 'VariableNames', variableNames2);
    end

    print_header('FD & Mean FD Table has been created.');
end






% function FD_T = get_fd_on_mpc(preproc_subject_dir, threshold_mvmn_xyz,  threshold_mvmn_pry)
%     digits(2);
%     % Initialize variables to store data for table
%     id = cell(numel(preproc_subject_dir), 1);
%     caps_mean_FD = zeros(numel(preproc_subject_dir), 1);
%     caps_mean_FD_more_point_2 = zeros(numel(preproc_subject_dir), 1);
%     caps_FD_max = zeros(numel(preproc_subject_dir), 1);
%     caps_FD_max_more_5 = zeros(numel(preproc_subject_dir), 1);
%     xyz_caps_max = cell(numel(preproc_subject_dir), 1);
%     xyz_caps_more = zeros(numel(preproc_subject_dir), 1);
%     pry_caps_max = cell(numel(preproc_subject_dir), 1);
%     pry_caps_more = zeros(numel(preproc_subject_dir), 1);
% 
% 
% 
%     rest_mean_FD = zeros(numel(preproc_subject_dir), 1);
%     rest_mean_FD_more_point_2 = zeros(numel(preproc_subject_dir), 1);
%     rest_FD_max = zeros(numel(preproc_subject_dir), 1);
%     rest_FD_max_more_5 = zeros(numel(preproc_subject_dir), 1);
%     xyz_rest_max = cell(numel(preproc_subject_dir), 1);
%     pry_rest_max = cell(numel(preproc_subject_dir), 1);
%     xyz_rest_more = zeros(numel(preproc_subject_dir), 1);
%     pry_rest_more = zeros(numel(preproc_subject_dir), 1);
%     
% 
%     
%     % Loop through each subject directory
%     for subj_i = 1:numel(preproc_subject_dir)
%         % Load PREPROC
%         subject_dir = preproc_subject_dir{subj_i};
%         PREPROC = save_load_PREPROC(subject_dir, 'load');
%         data = PREPROC.framewise_displacement;
%         % Calculating FD
%         head = 50;
%         % Caps
%         caps_mov= data.raw{1,10};
%         caps_mov(:, 4:6) = head*caps_mov(:,4:6);
%         delta_caps_mov = [
%                     zeros(1,size(caps_mov,2));
%                     diff(caps_mov);
%                     ];
%         FD_caps = sum(abs(delta_caps_mov),2);
%         MeanFd_caps = mean(FD_caps);
% 
%         % Rest
%         rest_mov = data.raw{1,1};
%         rest_mov(:, 4:6) = head*rest_mov(:,4:6);
%         delta_rest_mov = [
%             zeros(1,size(rest_mov,2));
%             diff(rest_mov);
%             ];
%         FD_rest = sum(abs(delta_rest_mov),2);
%         MeanFd_rest = mean(FD_rest);
% 
%         
%         % Extract data
%         id{subj_i} = PREPROC.subject_code;
%         caps_mean_FD(subj_i) = MeanFd_caps;
%         caps_FD_max(subj_i) = max(abs(FD_caps));
%         xyz_caps_max{subj_i} = max(abs(caps_mov(:,1:3)));
%         pry_caps_max{subj_i} = max(abs(caps_mov(:,4:6)));
% 
%         rest_mean_FD(subj_i) = MeanFd_rest;
%         rest_FD_max(subj_i) = max(abs(FD_rest));
%         xyz_rest_max{subj_i} = max(abs(rest_mov(:,1:3)));
%         pry_rest_max{subj_i} = max(abs(rest_mov(:,4:6)));
% 
%         
%         
%         % Calculate binary values
%         if caps_mean_FD(subj_i) > 0.2
%             caps_mean_FD_more_point_2(subj_i) = 1;
%         end
%         if caps_FD_max(subj_i) > 5
%             caps_FD_max_more_5(subj_i) = 1;
%         end
%         if rest_mean_FD(subj_i) > 0.2
%             rest_mean_FD_more_point_2(subj_i) = 1;
%         end
%         if rest_FD_max(subj_i) > 5
%             rest_FD_max_more_5(subj_i) = 1;
%         end
%         if max(xyz_caps_max{subj_i}) > threshold_mvmn_xyz
%             xyz_caps_more(subj_i) = 1;
%         end 
%         if max(xyz_rest_max{subj_i}) > threshold_mvmn_xyz
%             xyz_rest_more(subj_i) = 1;
%         end
%         if max(pry_caps_max{subj_i}) > threshold_mvmn_pry
%             pry_caps_more(subj_i) = 1;
%         end 
%         if max(pry_rest_max{subj_i}) > threshold_mvmn_pry
%             pry_rest_more(subj_i) = 1;
%         end
% 
%         
%         % Print header
%         print_header('Exctraction of FD & Mean FD finished for: ', PREPROC.subject_code);
%     end
% 
%     xyz_rest_max = cellfun(@(x) [ num2str(x, '%0.2f | ')], xyz_rest_max, 'UniformOutput', false);
%     xyz_caps_max = cellfun(@(x) [ num2str(x, '%0.2f | ')], xyz_caps_max, 'UniformOutput', false);
%     pry_caps_max = cellfun(@(x) [ num2str(x, '%0.2f | ')], pry_caps_max, 'UniformOutput', false);
%     pry_rest_max = cellfun(@(x) [ num2str(x, '%0.2f | ')], pry_rest_max, 'UniformOutput', false);
% 
%     variableNames = {'ID', ...
%                  'CAPS: Mean FD', 'CAPS: Max FD', 'CAPS: Max XYZ', 'CAPS: Max (Pitch, Roll, Yaw)', ...
%                  'CAPS: Mean FD > 0.2', 'CAPS: Max FD > 5', ...
%                  sprintf('CAPS: Max XYZ > %d', threshold_mvmn_xyz), sprintf('CAPS: Max (Pitch, Roll, Yaw) > %d', threshold_mvmn_pry), ...
%                  'REST: Mean FD', 'REST: Max FD', 'REST: Max XYZ', 'REST: Max (Pitch, Roll, Yaw)', ...
%                  'REST: Mean FD > 0.2', 'REST: Max FD > 5', ...
%                  sprintf('REST: Max XYZ > %d', threshold_mvmn_xyz), sprintf('REST: Max (Pitch, Roll, Yaw) > %d', threshold_mvmn_pry)};
%     % Create table
%     FD_T = table(id, ...
%                  caps_mean_FD, caps_FD_max, xyz_caps_max, pry_caps_max, ...
%                  caps_mean_FD_more_point_2, caps_FD_max_more_5, ...
%                  xyz_caps_more, pry_caps_more, ...
%                  rest_mean_FD, rest_FD_max, xyz_rest_max, pry_rest_max, ...
%                  rest_mean_FD_more_point_2, rest_FD_max_more_5, ...
%                  xyz_rest_more, pry_rest_more, ...
%                  'VariableNames', variableNames);
% 
%     print_header('FD & Mean FD Table has been created.');
% end


%     Option #1: Marker after the value, Caps and Rest togeter
%     variableNames = {'ID', ...
%                  'CAPS: Mean FD', 'REST: Mean FD', 'CAPS: Mean FD > 0.2', 'REST: Mean FD > 0.2', ...
%                  'CAPS: Max FD', 'REST: Max FD', 'CAPS: Max FD > 5', 'REST: Max FD > 5', ...
%                  'CAPS: Max XYZ','REST: Max XYZ','CAPS: Max XYZ > 5','REST: Max XYZ > 5', ...
%                  'CAPS: Max (Pitch, Roll, Yaw)','REST: Max (Pitch, Roll, Yaw)','CAPS: Max (Pitch, Roll, Yaw) > 5','REST: Max (Pitch, Roll, Yaw) > 5'};
%     % Create table
%     FD_T = table(id, ...
%                 caps_mean_FD, rest_mean_FD, caps_mean_FD_more_point_2,rest_mean_FD_more_point_2, ...
%                 caps_FD_max, rest_FD_max, caps_FD_max_more_5, rest_FD_max_more_5, ...
%                 xyz_caps_max, xyz_rest_max, xyz_caps_more_5, xyz_rest_more_5, ...
%                 pry_caps_max, pry_rest_max, pry_caps_more_5,pry_rest_more_5, ...
%                 'VariableNames',variableNames);
% %     
%     Option #2: First values, then markers, Caps and Rest together    
%     variableNames = {'ID', ...
%                  'CAPS: Mean FD', 'REST: Mean FD', 'CAPS: Max FD', 'REST: Max FD', ...
%                  'CAPS: Max XYZ', 'REST: Max XYZ', 'CAPS: Max (Pitch, Roll, Yaw)', 'REST: Max (Pitch, Roll, Yaw)', ...
%                  'CAPS: Mean FD > 0.2', 'REST: Mean FD > 0.2', 'CAPS: Max FD > 5', 'REST: Max FD > 5', ...
%                  'CAPS: Max XYZ > 5', 'REST: Max XYZ > 5', 'CAPS: Max (Pitch, Roll, Yaw) > 5', 'REST: Max (Pitch, Roll, Yaw) > 5'};
%     % Create table
%     FD_T = table(id, ...
%                  caps_mean_FD, rest_mean_FD, caps_FD_max, rest_FD_max, ...
%                  xyz_caps_max, xyz_rest_max, pry_caps_max, pry_rest_max, ...
%                  caps_mean_FD_more_point_2, rest_mean_FD_more_point_2, caps_FD_max_more_5, rest_FD_max_more_5, ...
%                  xyz_caps_more_5, xyz_rest_more_5, pry_caps_more_5, pry_rest_more_5, ...
%                  'VariableNames', variableNames);

% Option # 3 Caps and Rest different 
%     variableNames = {'ID', ...
%                      'CAPS: Mean FD', 'CAPS: Max FD', 'CAPS: Mean FD > 0.2', 'CAPS: Max FD > 5', ...
%                      'CAPS: Max XYZ','CAPS: Max (Pitch, Roll, Yaw)',...
%                       sprintf('CAPS: Max XYZ > %d', threshold_mvmn1), sprintf('CAPS: Max (Pitch, Roll, Yaw) > %d', threshold_mvmn2), ...
%                      'REST: Mean FD', 'REST: Max FD', 'REST: Mean FD > 0.2', 'REST: Max FD > 5', ...
%                      'REST: Max XYZ','REST: Max (Pitch, Roll, Yaw)',...
%                       sprintf('REST: Max XYZ > %d', threshold_mvmn1), sprintf('REST: Max (Pitch, Roll, Yaw) > %d', threshold_mvmn2)};
%     % Create table
%     FD_T = table(id, ...
%                  caps_mean_FD, caps_FD_max, caps_mean_FD_more_point_2, caps_FD_max_more_5, ...
%                  xyz_caps_max,pry_caps_max, xyz_caps_more, pry_caps_more, ...
%                  rest_mean_FD, rest_FD_max, rest_mean_FD_more_point_2, rest_FD_max_more_5, ...
%                  xyz_rest_max, pry_rest_max, xyz_rest_more, pry_rest_more, ...
%                  'VariableNames', variableNames);
% 