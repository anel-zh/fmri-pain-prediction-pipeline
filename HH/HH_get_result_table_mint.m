function  result_table = HH_get_result_table_mint(test_performance_spec,runs_all,brain_measure_all,datasets_all)
% Define your conditions and model types
conditions = runs_all;
model_types = brain_measure_all;
for dat_idx = 1:length(datasets_all)
    dataset = datasets_all{dat_idx};
    table_data.(dataset) = {};
for i = 1:numel(model_types)
    for j = 1:numel(conditions)
        condition_name = conditions{j};
        model_type_name = model_types{i};
        
        if isfield(test_performance_spec.(dataset), model_type_name) && ...
           isfield(test_performance_spec.(dataset).(model_type_name), condition_name)

            result = test_performance_spec.(dataset).(model_type_name).(condition_name);

            across_s_corr = result.corr_y;     
            within_s_corr = result.mean_r;      
            r_square = result.rsquare;

            table_data.(dataset) = [table_data.(dataset); {sprintf('%s | %s', model_type_name, condition_name), across_s_corr, within_s_corr, r_square}];
        end
    end
end
result_table.(dataset) = cell2table(table_data.(dataset), 'VariableNames', {'Predictors', 'Across s. corr.', 'Within s corr.', 'R2'});
disp(result_table.(dataset));
end 
