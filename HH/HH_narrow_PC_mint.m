% Split 100 by 20
% range = 100;
% step = 20

% range = 20;
% step = 10;

% range = 10;
% step = 1;
function results_structure_narrowed = HH_narrow_PC_mint(config_structure, previous_results_structure, runs, predictors, range, step)

%% 2.1 PC range
results_name = ['results_' runs '_same_time_window'];
valid_performance = previous_results_structure.(predictors).(results_name).validation.variance_normalized.valid_performance;
[~, max_corrY_idx] = max(valid_performance.corr_y);
optimal_PC_split100 =  valid_performance.PC_number(max_corrY_idx);
start_idx = optimal_PC_split100 - range;
end_idx = optimal_PC_split100 + range;
config_structure.narrow_PC_range = start_idx:step:end_idx;

%% 2.2 CV_PCR
split = step;
config_structure.DCC_cut = true;  % Important

% Performance base
C0.performance_base = 'corr_y';
C0.normalization_options = {'variance_normalized'};

% PC-split 
C0.range_name = sprintf('split_by_%d_PC', split);
C0.PC_train_plots_save = config_structure.narrow_PC_range;
C0.PC_valid_plots_save = C0.PC_train_plots_save;
C0.save_testing_visualization = true;
C0.save_result_to_excel = false;
C0.save_model_weights_stats = true;
C0.structure_name = ['Pre_Final_' num2str(split) '_31Oct2024_' predictors '_' runs];
config_structure.binning_conditions = {'same_time_window'}; % chnaging from the default option

tic

% Connectivity & HRF Activation
C0.brain_measures = {predictors}; 
config_structure.model_input_conditions = {runs};  %IMPORTANT ADDITION
results_structure_narrowed  = SS_C0_main_loop_mint(config_structure, C0, 'narrow_PC_range');
toc

