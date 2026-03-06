%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 15th Oct 2024 -> 13 Jun 2025 finalized before project transfer.
% Goal: 
%     - Dataset: MPC-Wani 
%     - Atlas: Schaefer_265. 
%     - Cross testing caps_rest model on caps and in reverse (saving
%     original performance caps_rest on caps_rest and caps on caps as well
%     for a quick use).

%% Content
% ====== Part 1 
% 1. Loading directories and configuration structure.
% 2. Loading brain data prepared in S2.
% 3. Combining connectivity and activation.
% 4. Loading testing results from original model development from S2.

% ====== Part 2 (cross-testing)
% 1. Defining looping parameters
    % -- loop start
% 2. Preparing data
% 3. Applying model weights
% 4. Getting performance
% 5. Visualizing
    % -- loop end 
% 6. Saving performance table
%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';

% Directories 
HH_set_dir_mint(model, dataset);
% % HH_set_dir_mint(model, dataset,'/home/anel/nas1/');

% Config structure
config_structure_all = HH_load_config_mint(dataset,'save',false, 'load_final_model');% default one in Jun9 model, but different one can be specified
% config_structure_all = HH_load_config_mint(dataset,'save',false,'base', '/home/anel/nas1/', 'load_final_model');

config_structure = config_structure_all.model01_mpc_wani;    
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;
figuredir = fullfile(basedir, '/figures/model/9Jun2025_final_model/cross_testing_final_models'); if ~exist(figuredir, 'dir'); mkdir(figuredir); end

%% 1.2 Loading brain data
% Connectivity and activation: intermittent output from S2 script 
load(fullfile(basedir,'optimized_data_files/for_model_dev_diff_vn_step_final_ver/', 'vn_split_data_mpc_wani_binned_C'), 'vn_split_data')

%% 1.3 Combining connectivity and activation
activation_name = 'hrf_voxel'; % sometimes activation can be hrf_roi, boxcar_roi, etc. -> just the variable name
vn_split_data_final = MINT_prepare_data.combine_connectivity_and_activation(vn_split_data, activation_name); % adding a combined model input

config_structure.vn_split_data_final = vn_split_data_final; % updating config

%% 1.4 Loading testing results from original model development (S2)
load(fullfile(basedir, '/model_development_results/9Jun2025_final_model/results_structure_full.mat'), 'testing')

%% Part 2 
% > Basically same as MINT_model_building.testing, just adding the model_wei_run to be cross-test 
main_table_result = table();
save_testing_visualization = true; 
%% 2.1 Defining looping parameters
               % Test on   % Model    
cross_test = {'caps_rest', 'caps';... % cross-testing caps_rest model on caps
              'caps', 'caps_rest';...
              'caps_rest', 'caps_rest';... % original way -> to keep everything in one table
              'caps', 'caps'}; % original way -> to keep everything in one table
brain_measures_all = fieldnames(testing);

for b = 1:length(brain_measures_all)
    brain_measure = brain_measures_all{b};
    for c = 1:size(cross_test,1)
        %% 2.2 Preparing data
        set_name = 'test'; % using testing set for cross-testing
        model_input_condition = cross_test{c,1};
        % case_run refers to whether it is capsaicin or for example quinine not to
        % the model_input condition
        [n_case, model_input_data] = MINT_prepare_data.reshape_for_model_input(vn_split_data_final, brain_measure, set_name, model_input_condition);

        %% 2.3 Applying model weights
        model_wei_run = cross_test{c,2};
        print_header(brain_measure, ['Model ' model_wei_run ' on ' model_input_condition]);
        model_weights = testing.(brain_measure).(model_wei_run).model_weights{1};
        intercept = testing.(brain_measure).(model_wei_run).model_weights{2};

        pred_score = MINT_model_building.apply_model_weights(model_input_condition, model_input_data.binned, n_case, model_weights, intercept);

        %% 2.4 Getting performance
        % Getting actual (Y) and predicted case ratings (yfit)
        [ratings_all] = MINT_model_building.get_shaped_ratings(model_input_condition, model_input_data.binned, pred_score);

        % Getting performance
        whfolds = MINT_model_building.get_whfolds(model_input_condition,n_case); %whfolds
        performance = MINT_model_building.get_performance( ...
            ratings_all.model_performance.(model_input_condition).y, ...
            ratings_all.model_performance.(model_input_condition).yfit, ...
            whfolds, n_case);


        % Saving results
        temp_table = table({brain_measure},{model_wei_run}, {model_input_condition}, ratings_all, 'VariableNames',{'Brain Feature', 'Model', 'Test on', 'ratings_all'});
        main_table_result = [main_table_result; temp_table, struct2table(performance)];

        %% 2.5 Visualizing
        % Visualize validation performance
        if save_testing_visualization
            figure_names = ['model_' model_wei_run '_tested_on_' model_input_condition '.pdf'];
            figures_save_dir = fullfile(figuredir, brain_measure);
            MINT_model_building.visualize(ratings_all, model_input_condition, n_case, figures_save_dir, figure_names, config_structure.dataset)
        end
    end
end 

%% 2.6 Saving performance table
save(fullfile(basedir, 'model_development_results/9Jun2025_final_model/all_performance_including_cross_testing'), 'main_table_result', '-v7.3')


% %% %% 2.1 Cross-testing (previous way before optimizing to class functions)
% % Case
% save_figure = true;
% run_case = 'caps_rest';
% model_used = 'caps';
% %feature_case = 'connectivity'; 
% brain_measure_all = {'connectivity', 'hrf_voxel', 'connectivity_and_hrf_voxel'};
% 
% for brain_measure_idx = 1:length(brain_measure_all)
%     feature_case = brain_measure_all{brain_measure_idx};
% 
% 
% model_data_cross_test = struct();
% condition_dir = sprintf('Final_model_figures_cross_testing_caps_rest_and_caps_and_original/May29_%s_model_on_%s_run', model_used,run_case);
% 
% switch feature_case
%     case 'connectivity'
%         wei_name = 'C_wei';
%     case 'hrf_voxel'
%         wei_name = 'A_wei';
%     case 'connectivity_and_hrf_voxel'
%         wei_name = 'CA_wei';
% end 
% 
% 
% switch run_case
%     case 'rest'
%         n_bin = 8; % for future convenience
%         subplot_n1 = 2;
%         subplot_n2 = 4;
%         position = [127         150        1706         812];
%     otherwise
%         n_bin = 15;
%         subplot_n1 = 3;
%         subplot_n2 = 5;
%         position = [122          49        1680         901];
% end
% 
% model_data_cross_test.(feature_case).(run_case).(wei_name) = model_data.(dataset).(feature_case).(model_used).(wei_name);
% model_data_cross_test.(feature_case).(run_case).intercept = model_data.(dataset).(feature_case).(model_used).intercept;
% 
% % Applying the model 
% clear binned
% [pain_score, binned] = HH_specificity_binning_applying_model_weights(model_data_cross_test, behavioral_original, C_original, A_original, feature_case, run_case);
% 
% n_subj = size(pain_score.caps, 2);
% [~, Y, yfit, whfolds, plotY, plotYfit, n_bins_caps] = HH_cv_pcr_mint.get_Yfit(run_case, pain_score, binned, n_subj);
% test_performance.(['model_' model_used]).(feature_case).(run_case) = HH_cv_pcr_mint.test_performance(Y, yfit, whfolds, n_subj);
% if save_figure
%     save_name = [feature_case '_' run_case];
%     basedir = ['/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/' 'model01_Schaefer_' dataset '/figures/model/Final_model_before_matching_the_timing_of_normalization'];
%     HH_cv_pcr_mint.plot_model_results(plotY, plotYfit, n_bins_caps,save_name, basedir, condition_dir);
% end
% end
% 
% save(fullfile(basedir, 'Final_model_figures_cross_testing_caps_rest_and_caps_and_original/May29_performance_original_and_cross_testing_caps_rest_and_caps.mat'), 'test_performance', '-v7.3')
% 
% close all;
% 
% %% 2.2 Visualizing 
%    