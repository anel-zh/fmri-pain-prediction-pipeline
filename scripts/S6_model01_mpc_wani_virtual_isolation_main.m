%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 8th Oct 2024 -> 13th June 2025 - revised and updated before
% project transfer.
% Goal: 
%     - Dataset: MPC- Wani. 
%     - Atlas: Schaefer_265. 
%     - Virtual isolation using the final model and applying on (1)
%     original dataset and (2) replication dataset. Isolation is done on
%     network level and roi level.

%% Content
% ====== Part 1 
% 1. Loading directories and configuration structure.
% 2. Loading brain data (for original and replication sessions).
% 3. Combinning connectivity and activation.
% 4. Loading testing results (for model weights) from S2 script.
% 5. Setting network information (roi & network mask)

% ====== Part 2 (Virtual Isolation)
% 1. Defining parameters (whether original or replication dataset & whether
% roi or network level) -> should be run multiple times (avoided loops as
% it was already quite complex.)
% 2. Running virtual isolation 
% 3. Saving performance

% ====== Part 3 (Visualizing | can be run without part 2 by loading results)
% 3.1 Network level -> can be optimized using data from Part2. 

clc
clear
%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';

% Directories 
HH_set_dir_mint(model, dataset);
% % HH_set_dir_mint(model, dataset,'/home/anel/nas1/');

% Config structure
config_structure_all = HH_load_config_mint(dataset,'save',false, 'load_final_model');% default one in Jun9 model, but different one can be specified
% config_structure_all = HH_load_config_mint(dataset,'save',false,'base', '/home/anel/nas1/');

config_structure = config_structure_all.model01_mpc_wani;    
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;

%% 1.2 Loading brain data
% Connectivity and activation: intermittent output from S2 script 
% Original sessions data 
load(fullfile(basedir,'optimized_data_files/for_model_dev_diff_vn_step_final_ver/', 'vn_split_data_mpc_wani_binned_C'), 'vn_split_data')

% Replication sessions data
load(fullfile(basedir, 'optimized_data_files', 'replication_data_diff_vn_step'), "vn_dat"); 

%% 1.3 Combining connectivity and activation
activation_name = 'hrf_voxel'; % sometimes activation can be hrf_roi, boxcar_roi, etc. -> just the variable name
vn_split_data_orig = MINT_prepare_data.combine_connectivity_and_activation(vn_split_data, activation_name); % adding a combined model input
vn_split_data_rep = MINT_prepare_data.combine_connectivity_and_activation(vn_dat, activation_name);

% Combining orig and replication data to one structure
vn_split_data_final = vn_split_data_orig;
vn_split_data_final.independent_set = vn_split_data_rep.independent_set;

config_structure.vn_split_data_final = vn_split_data_final; % updating config

%% 1.4 Loading testing results from original model development (S2)
load(fullfile(basedir, '/model_development_results/9Jun2025_final_model/results_structure_full.mat'), 'testing')

%% 1.5 Setting network information 
mask = fmri_data((which('Schaefer_265_combined_2mm.nii')), which('gray_matter_mask.nii'));
load('Schaefer_Net_Labels_r265.mat')
roi_names = Schaefer_Net_Labels.names;
network_dat = Schaefer_Net_Labels.dat(:,2);
network_names = {'VN', 'SMN', 'DAN', 'VAN', 'LN', 'FPN', 'DMN', 'SCTX', 'CB', 'BS_PAG'};
% ROI mask
roi_mask = mask.dat; 

% Change mask dat from ROI to network level
network_mask = mask.dat;
for mask_val_idx  = 1:length(mask.dat)
    if mask.dat(mask_val_idx) ~= 0
       network_mask(mask_val_idx) =  network_dat(mask.dat(mask_val_idx));
    end 
end 


%% Part 2 
virtual_isolation_performance = struct(); % -> RUN ONLY ONCE
%% 2.1 Defining looping parameters
%===== THE 2.1 and 2.2 SHOULD BE RUN 4 (changing data and changing level) FOR SAVING RESULTS so it will
%have both original sessions and replication sessions and both network and
%roi level

% Choosing level of isolation
level = 'network'; 
switch level
    case 'network'
        all_names = network_names;
        mask_isolation = network_mask; 
    case 'roi'
        all_names = strrep(roi_names, ' (', '_');
        all_names = strrep(all_names, ')', '');
        mask_isolation = roi_mask; 
end 

% Choosing dataset on which to apply isolated wei
data = 'replication_sessions'; 
switch data
    case 'original_sessions'
        set_name = 'test'; % can only apply isolated weights on other sets like training or validation if needed
                        % Test on   % Model 
        cross_test = {'caps_rest', 'caps_rest';... % if needed can add other cross test parameters
                        'caps', 'caps'};
    case 'replication_sessions'
        set_name = 'independent_set';
        cross_test = {'caps_rest', 'caps_rest';... 
                      'caps', 'caps';...
                      'quinine_rest', 'caps_rest'; ...
                      'quinine', 'caps'};
end 

%% 2.2 Virtual isolation   
brain_measures = {'connectivity_and_hrf_voxel', 'connectivity','hrf_voxel'};
for b = 1:length(brain_measures)
    brain_measure = brain_measures{b};
    main_table_result = table(); % reset -> important
    for c = 1:size(cross_test,1)
        for n = 1:length(all_names)
            id = all_names{n};

            % 2.2 Preparing data
            model_input_condition = cross_test{c,1};
            % case_run refers to whether it is capsaicin or for example quinine not to
            % the model_input condition
            [n_case, model_input_data] = MINT_prepare_data.reshape_for_model_input(vn_split_data_final, brain_measure, set_name, model_input_condition);

            % 2.3 Applying model weights
            model_wei_run = cross_test{c,2};
            print_header(brain_measure, ['Model ' model_wei_run ' isolating ' id]);
            model_weights_whole = testing.(brain_measure).(model_wei_run).model_weights{1};
            intercept = testing.(brain_measure).(model_wei_run).model_weights{2};


            %  =========  Isolating model wei for chosen network =========
            switch brain_measure
                case 'hrf_voxel'
                    model_weights = model_weights_whole .* double(mask_isolation == n);
                case 'connectivity'
                    if strcmp(level, 'network')
                        roi_idx = find(network_dat == n);
                    else 
                        roi_idx = n;
                    end 
                    r_original = reformat_r_new(model_weights_whole, 'reconstruct');
                    r_isolated = zeros(size(r_original));
                    r_isolated(roi_idx, :) = r_original(roi_idx, :);
                    r_isolated(:, roi_idx) =  r_original(:, roi_idx);
                    model_weights = reformat_r_new(r_isolated, 'flatten');
                case 'connectivity_and_hrf_voxel'
                     % Separating 
                     connectivity_end_idx = (length(roi_names) * (length(roi_names)-1))/2;
                     C_wei = model_weights_whole(1:connectivity_end_idx, 1);
                     A_wei = model_weights_whole((connectivity_end_idx+1):end, 1);
                     % Isolating
                     A_wei_isolated = A_wei .* double(mask_isolation == n);

                     if strcmp(level, 'network')
                         roi_idx = find(network_dat == n);
                     else
                         roi_idx = n;
                     end
                     r_original = reformat_r_new(C_wei, 'reconstruct');
                     r_isolated = zeros(size(r_original));
                     r_isolated(roi_idx, :) = r_original(roi_idx, :);
                     r_isolated(:, roi_idx) =  r_original(:, roi_idx);
                     C_wei_isolated = reformat_r_new(r_isolated, 'flatten');
                     % Combining back
                     model_weights = [C_wei_isolated;A_wei_isolated];
            end

            pred_score = MINT_model_building.apply_model_weights(model_input_condition, model_input_data.binned, n_case, model_weights, intercept);

            % 2.4 Getting performance
            % Getting actual (Y) and predicted case ratings (yfit)
            [ratings_all] = MINT_model_building.get_shaped_ratings(model_input_condition, model_input_data.binned, pred_score);

            % Getting performance
            whfolds = MINT_model_building.get_whfolds(model_input_condition,n_case); %whfolds
            performance = MINT_model_building.get_performance( ...
                ratings_all.model_performance.(model_input_condition).y, ...
                ratings_all.model_performance.(model_input_condition).yfit, ...
                whfolds, n_case);


            % Saving results
            temp_table = table({id},{model_wei_run}, {model_input_condition}, ratings_all, 'VariableNames',{['Isolated ' level], 'Model', 'Test on', 'ratings_all'});
            main_table_result = [main_table_result; temp_table, struct2table(performance)];

            % 2.5 Visualizing -> can be done per network if needed, but
            % figure names or figure dir should be adjusted
            %         % Visualize validation performance
            %         if save_testing_visualization
            %             figure_names = ['model_' model_wei_run '_tested_on_' model_input_condition '.pdf'];
            %             figures_save_dir = fullfile(figuredir, brain_measure);
            %             MINT_model_building.visualize(ratings_all, model_input_condition, n_case, figures_save_dir, figure_names, config_structure.dataset)
            %         end
        end
    end
    virtual_isolation_performance.(level).(data).(brain_measure) = main_table_result;
end 

%% 2.3 Saving results to structure
virtual_isolation_performance.comment = 'The isolation was done using Schaefer 265 atlas. caps_rest and caps models performances are in the same brain feature, hence (265 ROI x 2 models -> brain feature field will have 530rows and in case of specificity + 2 test on options with quinine_rest and quinine will result in 1060 rows). The main script for the structure is in S6_model01_mpc_wani_virtual_isolation.m. The isolation weights were applied on testing set of original dataset and on the replication set. The mentioned S6 script can be used if cross-tested application (e.g., isolated caps_rest model weights on caps data) is needed or if the application on validation or training sets of original data is required.';
save(fullfile(basedir, 'model_development_results/9Jun2025_final_model', 'final_model_virtual_isolation_on_original_and_replication'), '-struct', 'virtual_isolation_performance', '-v7.3')

%% Part 3 
% CAN LOAD saved virtual_isolation_performance to avoid redoing
% Visualization 
figuredir = fullfile(basedir, '/figures/model/9Jun2025_final_model/virtual_isolation/'); if ~exist(figuredir, 'dir'); mkdir(figuredir); end
%% 3.1 Spider plots 
% (Some main network level plots! however spider plot can be created for other levels using virtual_isolation_performance)
% Colors
colors = [0.545, 0.8, 0.722; 0.945, 0.718, 0.533; 0.643, 0.639, 0.769; 0.969, 0.745, 0.745; 0.482, 0.827, 0.918];

% Data (! if cross-testing was not done, model should match the test on)
brain_measures = {'connectivity_and_hrf_voxel', 'connectivity','hrf_voxel'};
for b = 1:length(brain_measures)
    brain_measure = brain_measures{b};
    model = 'caps';
    test = model; % test on in original data
    rep_test_on = strrep(model, 'caps', 'quinine'); % test on in replication data
    performance_visualize = 'corr_y';

    values_orig = virtual_isolation_performance.network.original_sessions.(brain_measure).(performance_visualize)(...
        strcmp(virtual_isolation_performance.network.replication_sessions.(brain_measure).Model, model) & ...
        strcmp(virtual_isolation_performance.network.replication_sessions.(brain_measure).("Test on"), test));

    values_rep_with_caps = virtual_isolation_performance.network.replication_sessions.(brain_measure).(performance_visualize)(...
        strcmp(virtual_isolation_performance.network.replication_sessions.(brain_measure).Model, model) & ...
        strcmp(virtual_isolation_performance.network.replication_sessions.(brain_measure).("Test on"), test));

    value_rep_with_quinine = virtual_isolation_performance.network.replication_sessions.(brain_measure).(performance_visualize)(...
        strcmp(virtual_isolation_performance.network.replication_sessions.(brain_measure).Model, model) & ...
        strcmp(virtual_isolation_performance.network.replication_sessions.(brain_measure).("Test on"), rep_test_on));

    close all;
    input = [values_orig, values_rep_with_caps, value_rep_with_quinine];

    % Create spider plot
    spider_plot(input', ...
        'AxesLabels', strrep(network_names, '_', ' & '), ...                % Network label
        'FillOption', 'on', ...                    % Fill the area under the plot
        'AxesInterval', 4, ...
        'AxesLimits', [repmat(min(input(:))-0.1, 1, 10); repmat(max(input(:))+0.1, 1, 10)], ...
        'FillTransparency', 0.2, ...
        'AxesDataOffset', 0.1, ...
        'AxesDisplay', 'one', ...
        'Color', colors([2, 4,5], :), ...
        'AxesLabelsEdge', 'none', ...
        'AxesFontSize', 14,...
        'LabelFontSize', 14);             % Line color
    legend_str = {'orig: caps & rest', 'rep: caps & rest', 'rep: quinine & rest'};
    legend(legend_str, 'Location', 'southoutside', 'Box', 'off');
    set(gca, 'tickdir', 'out','ticklength', [.02, .02], 'FontSize', 16, 'LineWidth', 1.5, 'color', 'w')
    set(gcf, 'Position', [446   482   588   480], 'color', 'w'); % Adjust size for a 2x6 grid
    pagesetup(gcf);
    saveas(gcf, fullfile(figuredir, 'network_level/', [brain_measure '_' model '_model_' performance_visualize '.pdf']))
end

