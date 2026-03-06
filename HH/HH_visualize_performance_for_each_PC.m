function HH_visualize_performance_for_each_PC(results_structure_full_dir, varargin)

%% Function: Setup
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 17th June before project transfer
% Goal: 
%     - Looking at model performance for each PC. 
% Example:
%results_structure_full_dir = '/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/model01_Schaefer_mpc_wani/model_development_results/9Jun2025_final_model/results_structure_full.mat';

results = load(results_structure_full_dir, 'training', 'validation'); 
% Define brain features and run types
brain_features = {'connectivity_and_hrf_voxel', 'connectivity', 'hrf_voxel'};
run_types = {'caps_rest', 'caps'};

% Metrics to plot
metrics = {'corr_y', 'rsquare', 'mean_r'};

% Titles for figures
metric_titles = {'Across sessions correlation', 'R² (rsquare)', 'Mean of within session correlations'};
close all
% Loop through metrics to create each figure
for m = 1:length(metrics)
    figure('Name', metric_titles{m}, 'NumberTitle', 'off');
    sgtitle(metric_titles{m});
    plot_metric = metrics{m};  % e.g., 'corr_y'
    
    for i = 1:length(brain_features)
        for j = 1:length(run_types)
            subplot_idx = (i - 1) * length(run_types) + j;
            subplot(3, 2, subplot_idx);
            
            % Extract data
            training_table = results.training.(brain_features{i}).(run_types{j});
            validation_table = results.validation.(brain_features{i}).(run_types{j});
            
            % Check if data exists and is valid
            if ~isempty(training_table) && ~isempty(validation_table)
                % Extract metric values
                y_train = training_table.(plot_metric);
                y_valid = validation_table.(plot_metric);
                
                % Plot lines
                plot(y_train, 'b-', 'DisplayName', 'Training');
                hold on;
                plot(y_valid, 'r--', 'DisplayName', 'Validation');
                
                % Find best PC (max validation)
                [~, max_idx] = max(y_valid);
                xline(max_idx, 'k--', 'LineWidth', 1.2, 'DisplayName', ['Max @ PC ' num2str(max_idx)]);
                
                % Labels
                title_str = sprintf('%s | %s', ...
                    brain_features{i}, run_types{j});
                title(title_str, 'Interpreter', 'none');
                xlabel('PC');
                ylabel(plot_metric);
                legend('Location', 'best');
                grid on;
                hold off;
                box off
            else
                title([brain_features{i} ' | ' run_types{j} ': no data'], 'Interpreter', 'none');
            end
            set(gcf, 'color', 'w', 'position', [675         151        1123         811]);
        end
    end
end

end 