function mahalanobis_T = get_mahalanobis_on_mpc(preproc_subject_dir, window_size, TR)
    % Initialize variables to store data for table
    id = cell(numel(preproc_subject_dir), 1);
    caps_mah_top= cell(numel(preproc_subject_dir), 1);
    print_text_caps = cell(numel(preproc_subject_dir), 1);   
    rest_mah_top= cell(numel(preproc_subject_dir), 1);
    print_text_rest = cell(numel(preproc_subject_dir), 1);
   
    for subj_i = 1:numel(preproc_subject_dir)
        % Load PREPROC
        subject_dir = preproc_subject_dir{subj_i};
        PREPROC = save_load_PREPROC(subject_dir, 'load');
        % Extract data
        [id{subj_i}, print_text_caps{subj_i}] = get_mahalanobis_on_mpc_subfunction(PREPROC, 10, window_size, TR);
        [~, print_text_rest{subj_i}] = get_mahalanobis_on_mpc_subfunction(PREPROC, 1, window_size, TR);
        print_text_combined_caps = strjoin(print_text_caps{subj_i}, '\n');
        print_text_combined_rest = strjoin(print_text_rest{subj_i}, '\n');
        caps_mah_top{subj_i}= string(print_text_combined_caps);
        rest_mah_top{subj_i}= string(print_text_combined_rest);
       
        print_header('Extraction of top 3 periods with Mahalanobis spikes is finished for: ', PREPROC.subject_code);
    end 
     % Create the table
     variableNames = {'ID', ...
                 'CAPS: Mahalanobis Top 3 Periods (Images)', 'REST: Mahalanobis Top 3 Periods (TR)'};

     mahalanobis_T = table(id, caps_mah_top, rest_mah_top, 'VariableNames',variableNames);
end


