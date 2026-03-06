%% Function: Model building
% Author: Anel Zhunussova
% Last update date: 1st April 2025
% Details:
%     -
%% Content
% ====== Part 1

classdef MINT_model_building
    methods (Static = true)

        % ------- Main loop
        % Looping through training, validation, and testing.
        function results_structure = main_loop(config_structure, looping_param, varargin)

            % --- Getting parameters
            % Feature
            brain_measures = looping_param.brain_measures;
            % Normalization
            config_structure.loop_normalization_option = MINT_model_building.check_field(looping_param, 'normalization_option', 'variance_normalized');
            % Binning approach
            config_structure.loop_binning_condition = MINT_model_building.check_field(looping_param, 'binning_conditions', 'same_time_window');
            config_structure.bootstrap_option = MINT_model_building.check_field(looping_param, 'do_boostrap', 'NO_bootstrap_training');
            % Specifying what to save
            [save_folder_name, ...
                performance_base, save_testing_visualization] = deal(looping_param.save_folder_name, ...
                looping_param.performance_base, looping_param.save_testing_visualization);
            [PC_valid_plots_save, PC_train_plots_save] = deal(looping_param.PC_valid_plots_save, looping_param.PC_train_plots_save);

            % PCs to check (only 1 PC or PC range) | check if saving stats matrix is needed
            if ~isempty(varargin)
                for var_idx = 1:length(varargin)
                    if strcmp(varargin{var_idx}, 'one_PC_option') && ischar(varargin{var_idx})
                        one_PC_option = true;
                        PC_value = varargin{var_idx+1};
                    elseif strcmp(varargin{var_idx}, 'save_stats_matrix') && ischar(varargin{var_idx})
                        save_stats_matrix = varargin{var_idx+1};
                        save_stats_matrix_dir = varargin{var_idx+2};
                    end
                end
            else
                one_PC_option = false;
                PC_range_split = looping_param.PC_range_split;
                save_stats_matrix = false;
            end

            % --- Running cv-pcr and hypertunning
            tic
            results_structure = struct();

            % LOOP #1: Brain measures (Feature)
            for bm_idx = 1:length(brain_measures)
                brain_measure_name = brain_measures{bm_idx};
                results_structure.(brain_measure_name) = struct();
                config_structure.loop_brain_measure = brain_measure_name;
                print_header(sprintf(' ------ %s -----', brain_measure_name));
                config_structure.loop_analysis_saving_name = sprintf('%s/%s',save_folder_name, brain_measure_name);

                % LOOP #2: Model input conditions (Caps or Caps_Rest)
                for cond_idx = 1:length(config_structure.model_input_conditions)
                    model_input_condition = config_structure.model_input_conditions{cond_idx};
                    config_structure.loop_model_input_condition = model_input_condition;


                    % Calculate PC_range by condition and defined split
                    % option
                    if one_PC_option
                        PC_range_temp = PC_value;
                    else
                        PC_range_temp = MINT_model_building.get_PC_range(config_structure, PC_range_split, 'main', 'cut_stimulus_delivery'); % cut is default and used to calculate max number of bins
                        print_header('PC range was adopted to cut stimulus delivery duration in capsaicin run.', ['PCs that will be run:' num2str(PC_range_temp)]);

                    end
                    PC_range = PC_range_temp;

                    % 1. TRAINING
                    [training_result, stats_table, model_weights_table] = MINT_model_building.training(PC_range, PC_train_plots_save, config_structure);
                    %  saving of stats from mode training;
                    save_training_dir = fullfile(config_structure.basedir,'model_development_results', save_folder_name); if ~exist(save_training_dir, 'dir'); mkdir(save_training_dir); end
                    stats_all.(brain_measure_name).(model_input_condition) = stats_table; % added line to include for all conditions
                    save(fullfile(save_training_dir, 'stats_from_training'), 'stats_all', '-v7.3'); 

                    % 2. VALIDATION
                    validation_result = MINT_model_building.validation(model_weights_table, config_structure, ...
                        PC_valid_plots_save);

                    % Find best PC from validation
                    switch performance_base
                        case 'corr_y'
                            [max_valid_corr, max_valid_corr_idx] = max(validation_result.corr_y);
                            best_PC = validation_result.PC(max_valid_corr_idx);
                            print_header(sprintf('BEST PC %d | corr_y_valid %d | %s', best_PC, max_valid_corr, model_input_condition));
                        case 'mean_r'
                            [max_valid_mean_r, max_valid_mean_r_idx] = max(validation_result.mean_r);
                            best_PC = validation_result.PC(max_valid_mean_r_idx);
                            print_header(sprintf('BEST PC %d | mean_r_valid %d | %s', best_PC, max_valid_mean_r, model_input_condition));
                    end
                    % ==== Add plot of performance for each PC

                    % 3. TESTING
                    testing_result = MINT_model_building.testing(best_PC, model_weights_table, config_structure, save_testing_visualization);

                    % Save results
                    results_structure.training.(brain_measure_name).(model_input_condition) = training_result;
                    results_structure.validation.(brain_measure_name).(model_input_condition) = validation_result;
                    results_structure.testing.(brain_measure_name).(model_input_condition) = testing_result;
                    results_structure.model_weights.(brain_measure_name).(model_input_condition) = model_weights_table;
                    results_structure.additional_comments = looping_param.additional_comments;
  
                    save(fullfile(save_training_dir, 'results_structure_full'), '-struct', 'results_structure', '-v7.3');
                    print_header('Preliminary results were saved at:', fullfile(save_training_dir, 'results_structure_full'));
                end
                print_header(sprintf('FINISHED %s', brain_measure_name));
                results_structure.comment = sprintf('Stimulus delivery was removed by default. Used normalization option was %s. The binning approach was %s. The results were saved at %s. The performance metric that was used to choose the best model from validation set is %s', config_structure.loop_normalization_option, config_structure.loop_binning_condition, save_folder_name, performance_base);
                print_header('Results were saved at:', fullfile(save_training_dir, 'results_structure_full'));
                toc
            end


        end

        %% Sub-functions: training, testing, validation
        % ------ Training
        function [main_table_result, stats_table, model_weights_table] = training(PC_range, PC_train_plots_save, config_structure)
            if strcmp(config_structure.bootstrap_option, 'do_boot')
                bootstrap = true;
                boot_n = config_structure.bootstrap_n;
            else
                bootstrap = false;
            end

            % --- Getting parameters
            basedir = config_structure.basedir;
            [binning_condition, model_input_condition, brain_measure] = ...
                deal(config_structure.loop_binning_condition, config_structure.loop_model_input_condition, config_structure.loop_brain_measure);
            analysis_saving_name = config_structure.loop_analysis_saving_name;

            % --- Loop cv-pcr
            % Prepare input data
            set_name = 'train';
            vn_split_data_final = config_structure.vn_split_data_final;
            [n_case, model_input_data] = MINT_prepare_data.reshape_for_model_input(vn_split_data_final, brain_measure, set_name, model_input_condition);
            dat_brain = model_input_data.dat_brain;
            dat_behavioral = model_input_data.dat_behavioral;

            % Loop over PCs
            main_table_result = table();  % Creates an empty table with no rows
            stats_table = table();
            model_weights_table = table();
            for PC = PC_range
                print_header(sprintf('%s on %d/%d | %s | %s', set_name, PC, max(PC_range), model_input_condition, binning_condition));

                % Run cv_pcr
                % Defining model input 
                dat = fmri_data;
                dat.dat = dat_brain;
                dat.Y = dat_behavioral;

                % Defining whfolds (Leave-one-out cross-validation)
                whfolds = MINT_model_building.get_whfolds(model_input_condition, n_case);

                if bootstrap
                    [~, stats, optout] = predict(dat, 'algorithm_name', 'cv_pcr', 'nfolds', whfolds, 'numcomponents', PC, 'error_type', 'mse', 'bootweights', 'bootsamples', boot_n); 
                else
                    [~, stats, optout] = predict(dat, 'algorithm_name', 'cv_pcr', 'nfolds', whfolds, 'numcomponents', PC, 'verbose', 1, 'error_type', 'mse');
                end

                % Get the performance
                ratings_all = MINT_model_building.get_shaped_ratings_training(stats, model_input_condition, n_case);
                performance = MINT_model_building.get_performance(stats.Y, stats.yfit, whfolds, n_case);

                % Update main_table_result 
                temp_table_result = table(PC, ratings_all, 'VariableNames',{'PC', 'ratings_all'});
                main_table_result = [main_table_result; temp_table_result, struct2table(performance)];

                temp_model_weights_table = table(PC, optout, 'VariableNames',{'PC', 'model_weights'});
                model_weights_table = [model_weights_table; temp_model_weights_table];

                temp_stats_table = table(PC, stats, 'VariableNames', {'PC', 'stats_cv_pcr'}); % saving separately just in case;
                stats_table = [stats_table; temp_stats_table];

                % Save figures 
                if ismember(PC, PC_train_plots_save)
                    figure_names = sprintf('Bin_%d_caps_Condition_%s_PC_%d.pdf', n_case.n_bins_caps, model_input_condition, PC);
                    figures_save_dir = fullfile(basedir, 'figures/model/', analysis_saving_name, set_name);
                    MINT_model_building.visualize(ratings_all, model_input_condition, n_case, figures_save_dir, figure_names, config_structure.dataset)
                end
            end
        end


        % -----Validation
        function main_table_result = validation(model_weights_table, config_structure, PC_valid_plots_save)

            % Getting Parameters
            basedir = config_structure.basedir;
            [binning_condition, model_input_condition, brain_measure] = ...
                deal(config_structure.loop_binning_condition, config_structure.loop_model_input_condition, config_structure.loop_brain_measure);

            analysis_saving_name = config_structure.loop_analysis_saving_name;

            % Getting data
            set_name = 'valid';
            vn_split_data_final = config_structure.vn_split_data_final;
            [n_case, model_input_data] = MINT_prepare_data.reshape_for_model_input(vn_split_data_final, brain_measure, set_name, model_input_condition);
            binned = model_input_data.binned;

            main_table_result = table();
            for PC_idx = 1:size(model_weights_table, 1)
                PC = model_weights_table.PC(PC_idx);
                model_weights = model_weights_table.model_weights{PC_idx, 1};
                intercept = model_weights_table.model_weights{PC_idx, 2};

                print_header(sprintf('%s on %d/%d | %s | %s', set_name, PC, max(model_weights_table.PC), model_input_condition, binning_condition));
                
                % Applying training model weights on validation data
                pred_score = MINT_model_building.apply_model_weights(model_input_condition, binned, n_case, model_weights, intercept);
                
                % Getting actual (Y) and predicted case ratings (yfit)
                [ratings_all] = MINT_model_building.get_shaped_ratings(model_input_condition, binned, pred_score);
                
                % Getting performance
                whfolds = MINT_model_building.get_whfolds(model_input_condition,n_case); %whfolds
                performance = MINT_model_building.get_performance( ...
                    ratings_all.model_performance.(model_input_condition).y, ...
                    ratings_all.model_performance.(model_input_condition).yfit, ...
                    whfolds, n_case);

                % Saving results
                % Update main_table_result directly
                temp_table_result = table(PC, ratings_all, 'VariableNames',{'PC', 'ratings_all'});
                main_table_result = [main_table_result; temp_table_result, struct2table(performance)];

                % Visualize validation performance
                if ismember(PC, PC_valid_plots_save)
                    figure_names = sprintf('Bin_%d_caps_Condition_%s_PC_%d.pdf', n_case.n_bins_caps, model_input_condition, PC);
                    figures_save_dir = fullfile(basedir, 'figures/model/', analysis_saving_name, set_name);
                    MINT_model_building.visualize(ratings_all, model_input_condition, n_case, figures_save_dir, figure_names, config_structure.dataset)
                end

            end


        end

        % ------ Testing
        function main_table_result = testing(best_PC, model_weights_table, config_structure, save_testing_visualization)
            % Getting Parameters
            basedir = config_structure.basedir;

            [binning_condition, model_input_condition, brain_measure] = ...
                deal(config_structure.loop_binning_condition, config_structure.loop_model_input_condition, config_structure.loop_brain_measure);

            analysis_saving_name = config_structure.loop_analysis_saving_name;

            model_weights_row = model_weights_table.model_weights(model_weights_table.PC == best_PC, :);
            model_weights_best_PC = model_weights_row{1,1};
            intercept = model_weights_row{1,2};

            % Getting data
            set_name = 'test';
            vn_split_data_final = config_structure.vn_split_data_final;
            [n_case, model_input_data] = MINT_prepare_data.reshape_for_model_input(vn_split_data_final, brain_measure, set_name, model_input_condition);

            binned = model_input_data.binned;

            print_header(sprintf('%s on best PC %d | %s | %s', set_name, best_PC, model_input_condition, binning_condition));

            % Applying training model weights on test data
            pred_score = MINT_model_building.apply_model_weights(model_input_condition, binned, n_case, model_weights_best_PC, intercept);

            % Getting actual (Y) and predicted case ratings (yfit)
            [ratings_all] = MINT_model_building.get_shaped_ratings(model_input_condition, binned, pred_score);
            
            % Getting performance
            whfolds = MINT_model_building.get_whfolds(model_input_condition,n_case);
            performance = MINT_model_building.get_performance( ...
                ratings_all.model_performance.(model_input_condition).y, ...
                ratings_all.model_performance.(model_input_condition).yfit, ...
                whfolds, n_case);

            % Saving results
            main_table_result = table(best_PC, model_weights_row, ratings_all, 'VariableNames',{'PC', 'model_weights', 'ratings_all'});
            main_table_result = [main_table_result, struct2table(performance)];

            % Visualize validation performance
            if save_testing_visualization
                figure_names = sprintf('Bin_%d_caps_Condition_%s_PC_%d.pdf', n_case.n_bins_caps, model_input_condition, best_PC);
                figures_save_dir = fullfile(basedir, 'figures/model/', analysis_saving_name, set_name);
                MINT_model_building.visualize(ratings_all, model_input_condition, n_case, figures_save_dir, figure_names, config_structure.dataset)
            end

        end


        %% ------ Supporting functions
        % Checking the structure for field
        function variable = check_field(structure, fieldname, default_value)
            if isfield(structure, fieldname)
                variable = structure.(fieldname);
            else
                variable = default_value;
                print_header('Input was empty, using default:', variable);
            end
        end

        % Getting PC range
        function PC_range = get_PC_range(config_structure, PC_range_split, option, varargin)
            if nargin < 3
                train_n = length(config_structure.model_split.main.train_id);
            else
                train_n = length(config_structure.model_split.(option).train_id); % in case of using different split
            end
            model_input_condition = config_structure.loop_model_input_condition;
            binning_condition = config_structure.loop_binning_condition;
            print_header("CHANGE PC_RANGE IF NOT 90 TR BIN");
            caps_bin_n = config_structure.binning_parameters.same_time_window.main.CAPS_bin_number;
            rest_bin_n = config_structure.binning_parameters.same_time_window.main.REST_bin_number;
            brain_measure = config_structure.loop_brain_measure;
            atlas_name = config_structure.atlas_name;

            % Calculting total bin
            if strcmp(model_input_condition, 'caps')
                total_bin = caps_bin_n;
            elseif strcmp(model_input_condition, 'caps_rest')
                if strcmp(binning_condition, 'same_time_window')
                    total_bin = caps_bin_n + rest_bin_n;
                else
                    total_bin = caps_bin_n * 2; % Assumes binning_condition is 'same_bin_number'
                end
            else
                error('Invalid model_input_condition');
            end

            if strcmp(varargin{1},'cut_stimulus_delivery')
                total_bin = total_bin-1; %1  since also capsaicin waa affected
            end

            if contains(brain_measure,'connectivity') || contains(brain_measure, 'voxel') || contains(brain_measure, 'activation')
                max_PCs_all = total_bin * train_n;
            elseif contains(brain_measure, 'roi') || contains(brain_measure, 'pc')
                if strcmp(atlas_name, 'Schaefer_265_combined_2mm') == 1
                    max_PCs_bin = total_bin * train_n;
                    max_PCs_atlas = 265;
                    max_PCs_all = min(max_PCs_bin, max_PCs_atlas);
                elseif strcmp(atlas_name, 'Fan_r279_MNI_2mm') == 1
                    max_PCs_bin = total_bin * train_n;
                    max_PCs_atlas = 279;
                    max_PCs_all = min(max_PCs_bin, max_PCs_atlas);
                else
                    disp('Check atlas name, error has occured at the connectivity plotting stage.');
                end
            end

            max_PCs_cv = max_PCs_all - total_bin - 1; % removing one fold and 1 last PC value as in the cv_pcr function
            PC_range = [1:PC_range_split:max_PCs_cv, max_PCs_cv];

        end



        % --- Additional functions cv-pcr
        % Getting whfolds
        function whfolds = get_whfolds(model_input_condition,n_case)
            case_run = n_case.case_run;
            switch model_input_condition
                case {'caps_rest', 'quinine_rest'}

                print_header(sprintf('Model Input: %s', model_input_condition));
                print_header(sprintf('Number of subjects %d | caps bins %d | rest bins %d', n_case.n_subj, n_case.(['n_bins_' case_run]), n_case.n_bins_rest));


                whfolds_caps = repmat(1: n_case.n_subj,  n_case.(['n_bins_' case_run]), 1); whfolds_caps = whfolds_caps(:); % should look like zig-zag
                whfolds_rest = repmat(1:n_case.n_subj, n_case.n_bins_rest, 1); whfolds_rest = whfolds_rest(:);
                whfolds = [whfolds_caps; whfolds_rest];

                case{'caps', 'quinine'} 

                print_header(sprintf('Model Input: %s.', model_input_condition));
                print_header(sprintf('Number of subjects %d | caps bins %d', n_case.n_subj, n_case.(['n_bins_' case_run])));

                whfolds = repmat(1:n_case.n_subj, n_case.(['n_bins_' case_run]), 1); whfolds = whfolds(:); % should look like one mountain

                otherwise 
                disp('Recheck the model_input_condition');
            end 
            

            % Intermittent check of whfolds

            figure;
            plot(whfolds);
            title(sprintf('Check whfolds for %s condition', model_input_condition));
            close all;

        end
        
        % Applying training model weights on validation/testing data
        function pred_score = apply_model_weights(model_input_condition, binned, n_case, model_weights, intercept)
                n_subj = n_case.n_subj;
                case_run = n_case.case_run;
                print_header(sprintf('The data has %d subjects', n_subj));
                for i = 1:n_subj
                    pred_score.(case_run){i} = sum(binned.(case_run){1, i} .* model_weights, 'omitnan')' + intercept;
                    if contains(model_input_condition, 'rest')
                        pred_score.rest{i} = sum(binned.rest{1, i} .* model_weights, 'omitnan')' + intercept;
                    end
                end
        end 
        % Getting plotY & plotYfit for training data
        function [ratings_all] = get_shaped_ratings_training(stats,model_input_condition, n_case)
            n_bins_caps = n_case.n_bins_caps;
            n_subj = n_case.n_subj;

            % model performance
            Y = stats.Y;
            yfit = stats.yfit;
            ratings_all.model_performance.(model_input_condition).y = Y;
            ratings_all.model_performance.(model_input_condition).yfit = yfit;

            % plot
            % for caps run
            pain_end_index = n_subj*n_bins_caps;
            control_start_index = pain_end_index+1;
            Y_pain = reshape(Y(1:pain_end_index)', [n_bins_caps,n_subj])'; % 26 x 10
            yfit_pain = reshape(yfit(1:pain_end_index)', [n_bins_caps, n_subj])';

            ratings_all.plot.(model_input_condition).y = Y_pain;
            ratings_all.plot.(model_input_condition).yfit = yfit_pain;

            % for caps_rest run
            if strcmp(model_input_condition, 'caps_rest') == 1
                n_bins_rest = n_case.n_bins_rest;
                Y_control = reshape(Y(control_start_index:end)', [n_bins_rest, n_subj])'; % 26 x 5
                yfit_control = reshape(yfit(control_start_index:end)', [n_bins_rest, n_subj])';

                ratings_all.plot.(model_input_condition).y = [Y_pain, Y_control];
                ratings_all.plot.(model_input_condition).yfit = [yfit_pain, yfit_control];
            end

        end

        % Getting predicted yfit in the correct form for checking performance and plotting.
        function ratings_all = get_shaped_ratings(model_input_condition, binned, pred_score)
            pre_runs = fieldnames(pred_score)';
            case_run = pre_runs{1}; % e.g., caps || quinine 
            if contains(model_input_condition, '_') == 1
                runs_all = [pre_runs, [pre_runs{1} '_' pre_runs{2}]]; % order is important
            else
                runs_all = pre_runs;
            end

            ratings_all = struct();
            for r = 1:length(runs_all)
                run = runs_all{r};
                if ~contains(run, '_') % e.g., caps_rest || quinine_rest
                    ratings_all.plot.(run).y = binned.behavioral.(run);
                    ratings_all.model_performance.(run).y = reshape(binned.behavioral.(run)', [], 1);

                    ratings_all.plot.(run).yfit = cat(2, pred_score.(run){:})';
                    ratings_all.model_performance.(run).yfit =  cat(1, pred_score.(run){:});
                else
                    ratings_all.model_performance.(run).y = [ratings_all.model_performance.(case_run).y; ratings_all.model_performance.rest.y];
                    ratings_all.model_performance.(run).yfit = [ratings_all.model_performance.(case_run).yfit; ratings_all.model_performance.rest.yfit];

                    ratings_all.plot.(run).y = [ratings_all.plot.(case_run).y, ratings_all.plot.rest.y];
                    ratings_all.plot.(run).yfit = [ratings_all.plot.(case_run).yfit, ratings_all.plot.rest.yfit];
                end
            end

        end


        % ----- Performance
        function  performance = get_performance(Y, yfit, whfolds, n_case)
      
            r = zeros(1,n_case.n_subj);
            for sb_i = 1:n_case.n_subj
                r(sb_i) = corr(Y(whfolds == sb_i), yfit(whfolds == sb_i));
            end

            y_pred = yfit;
            y_actual = Y;
            TSS = sum(((y_actual-mean(y_actual)).^2)); 
            SSR = sum((y_pred - y_actual).^2); 
            Rsquared = 1 - SSR/TSS;

            performance.r = r;
            performance.mean_r = mean(r);
            performance.corr_y = corr(Y, yfit);
            performance.rsquare = Rsquared;

            if length(r) > 1
                performance.boot_r_for_mean = boot_mean_wani(r, 10000);
                performance.boot_r_for_mean.comment = 'Using the function boot_mean_wani(r,10000).';
            else
                performance.bootres = [];
            end
        end

        % ----- Visualization
        function  visualize(ratings_all, model_input_condition, n_case, main_fig_dir, figure_names, dataset)
            plotY = ratings_all.plot.(model_input_condition).y;
            plotYfit = ratings_all.plot.(model_input_condition).yfit;
            n_bins_case = n_case.(['n_bins_' n_case.case_run]);
            plot_y_fit_dir = fullfile(main_fig_dir, 'plot_y_fit');
            trace_plot_overlap_dir = fullfile(main_fig_dir, 'trace_plot_overlap');

         
                mkdir(main_fig_dir);
                mkdir(plot_y_fit_dir);
                mkdir(trace_plot_overlap_dir);
                fprintf('New folders were created at %s', main_fig_dir);
            

            % PlotYfit
            figure;
            plot_y_yfit(plotY', plotYfit', 'data_alpha', 1, 'line_alpha', 0.7, 'dotsize', 25, 'xlim', [-0.1 1.2], 'ylim', [-0.1 0.5]);
            xlabel('Actual pain ratings', 'fontsize', 20); ylabel('Model predicted ratings', 'fontsize', 20);
            set(gca, 'tickdir', 'out','ticklength', [.02, .02], 'FontSize', 20, 'LineWidth', 1.5, 'color', 'w')
            set(gcf, 'Position', [451   709   359   268], 'color', 'w'); % Adjust size for a 2x6 grid
            pagesetup(gcf);
            saveas(gcf, fullfile(fullfile(plot_y_fit_dir, figure_names)));
            close all

            % Trace_plot_overlap -> input subject by bin (4 x 15 double)
            if size(plotYfit,1) >1
                figure;

                if contains(figure_names, 'quinine')
                    trace_plot_overlap_anel(plotY, plotYfit, 'color2_option', 10);
                else
                    switch dataset
                        case 'mpc_wani'
                            trace_plot_overlap_anel(plotY, plotYfit, 'color2_option', 7);
                        otherwise
                            trace_plot_overlap_anel(plotY, plotYfit, 'color2_option', 1);
                    end
                end
                xlabel('Time (Bins)', 'fontsize', 20);
                yyaxis left;  ylabel('Actual pain ratings', 'fontsize', 20);
                yyaxis right; ylabel('Model predicted ratings', 'fontsize', 20);
                ylim_val = get(gca, 'ylim');
                xlim([1,size(plotY, 2)]);
                %yticks(0:0.2:0.8);
                line([n_bins_case n_bins_case], ylim_val, 'linewidth', 1.5, 'color', [.5 .5 .5], 'linestyle', '--');
                if ~contains(figure_names, 'rest')
                    if contains(figure_names, 'quinine')
                        text(2, ylim_val(1) + diff(ylim_val)*0.2, {'Quinine'}, 'Fontsize', 20);
                    else
                        text(2, ylim_val(1) + diff(ylim_val)*0.2, {'Capsaicin'}, 'Fontsize', 20);

                    end
                else
                    if contains(figure_names, 'quinine')
                        text([2; n_bins_case+0.5], [ylim_val(1) + diff(ylim_val)*0.2; ylim_val(2) - diff(ylim_val)*0.2], {'Quinine', 'Resting'}, 'Fontsize', 20);
                    else
                        text([2; n_bins_case+0.5], [ylim_val(1) + diff(ylim_val)*0.2; ylim_val(2) - diff(ylim_val)*0.2], {'Capsaicin', 'Resting'}, 'Fontsize', 20);
                    end
                end
                set(gca, 'tickdir', 'out','ticklength', [.02, .02], 'FontSize', 20, 'LineWidth', 1.5, 'color', 'w')
                set(gcf, 'Position', [451   709   359   268], 'color', 'w'); % Adjust size for a 2x6 grid
                pagesetup(gcf);
                saveas(gcf, fullfile(fullfile(trace_plot_overlap_dir, figure_names)));
                close all
            end
        end
    end

end
