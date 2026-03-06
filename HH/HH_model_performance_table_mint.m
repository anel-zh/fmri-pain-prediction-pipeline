function [result_table, predictors_names] = HH_model_performance_table_mint(results_structure, input_option)

performance_corr_y = [];
performance_mean_r = [];
performance_r_sqr = [];
pc_numbers = [];
predictors_names = {};
% Brain measure
only_same_time_window = true;

% Brain measure
brain_measures = fieldnames(results_structure);
normalization_options = {'variance_normalized'};
print_header('Using default normalization option - variance normalized');
% Extract test performance for each case
for bm_idx = 1:length(brain_measures)
    brain_measure_name = brain_measures{bm_idx};
    bm_struct = results_structure.(brain_measure_name);

    case_names = fieldnames(bm_struct);
    for scale_idx = 1:length(normalization_options)
        normatization_name = normalization_options{scale_idx};
        for case_idx = 1:length(case_names)
            case_name = case_names{case_idx};
            if contains(case_name, 'same_bin_number')
                continue
            end
            if strcmp(input_option, 'testing')
                performance_name = 'test_performance';
                performance = bm_struct.(case_name).(input_option).(normatization_name).(performance_name);

            else               
                performance_name = 'valid_performance';
                temp_pc = bm_struct.(case_name).testing.(normatization_name).test_performance.PC_number;
                pc_idx = bm_struct.(case_name).(input_option).(normatization_name).(performance_name).PC_number == temp_pc;
                performance = bm_struct.(case_name).(input_option).(normatization_name).(performance_name)(pc_idx,:);
            end 


            performance_corr_y = [performance_corr_y; performance.corr_y];
            performance_mean_r = [performance_mean_r; performance.mean_r];
            performance_r_sqr = [performance_r_sqr; performance.R_squared];

            pc_numbers = [pc_numbers; bm_struct.(case_name).testing.(normatization_name).test_performance.PC_number];
            formatted_case_name = sprintf('%s | %s', brain_measure_name, case_name);
            predictors_names = [predictors_names; formatted_case_name];
            predictors_names = strrep(predictors_names, 'results_', '');           
            predictors_names = strrep(predictors_names, '_stw', '');            

            
            if only_same_time_window
                predictors_names = strrep(predictors_names, '_same_time_window', '');
            end 
        end
    end
end

% Create a table for better visualization
result_table = table(predictors_names, pc_numbers, performance_corr_y, performance_mean_r,performance_r_sqr, ...
    'VariableNames', {'Predictors', 'PCs', 'Across s. corr.', 'Within-s. corr.', 'R2'});

% Display the table
disp(result_table);

%rows_with_C = result_table(contains(result_table.Predictors, 'connectivity'), :);
%rows_without_C = result_table(~contains(result_table.Predictors, 'connectivity'), :);

%result_table = [rows_without_C;rows_with_C];
end 