%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 15th Oct 2024 -> 16th June 2025 updated and revised before
% project transfer.
% Goal: 
%     - Dataset: MPC-Wani 
%     - Atlas: Schaefer_265. 
%     - Visualizing model weights (original & bootstrap)
%% Content
% ====== Part 1 
% 1. Loading directories and configuration structure.
% 2. Loading final model weights.
% 3. Loading atlas details.

% ====== Part 2 (visualization of normal model weights)
% 1. Activation
% 2. Connectivity

% ====== Part 3 (visualization of bootstrap model weights -> significant)
% 1. Activation
% 2. Connectivity

clear
clc
%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';

% Directories
HH_set_dir_mint(model, dataset);
%HH_set_dir_mint(model, dataset, '/home/anel/nas1/');

% Config structure
config_structure_all = HH_load_config_mint(dataset,'save',false);
%config_structure_all = HH_load_config_mint(dataset,'save',false, 'base', '/home/anel/nas1/');

config_structure = config_structure_all.model01_mpc_wani;
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;
%% 1.2 Loading final model weights
% combined_model  -> CA -> inside has separated model weights for A and C
% hrf voxel - activation based model -> A
% DCC - connectivity based model -> C

% This function is mainly used for loading final model wei in format easy
% to visualize (separated combined model wei and p-values), however for the main results for performance,plotting,etc,
% better to use results_structure_full.testing(from 9Jun2025_final_model).

% Bootstrap model wei + original wei inside
normal_wei = HH_loading_final_models(basedir, model, dataset, 'normal_wei');
boot_wei = HH_loading_final_models(basedir, model, dataset, 'boot_wei');

%% 1.3 Loading atlas details
load('Schaefer_Net_Labels_r265.mat'); % Schaefer_Net_Labels
atlas_dat = fmri_data((which('Schaefer_265_combined_2mm.nii')), which('gray_matter_mask.nii'));

%% ==== Part 2 
% Visualizing model wei 

% Parameters
features_A = {'hrf_voxel', 'connectivity_and_hrf_voxel'};
features_C = {'connectivity', 'connectivity_and_hrf_voxel'};
runs = {'caps_rest', 'caps'};
figure_dir = fullfile(basedir, 'figures/model/9Jun2025_final_model/model_weights_visualized/');

% Local functions
thres_fun = @(x,y) x .* double(abs(x) > prctile(abs(x), y)); % threshold function x is input and y is threshold level
circos_plot = @(x) circos_multilayer(x, 'group',Schaefer_Net_Labels.dat(:,2),'region_names',Schaefer_Net_Labels.names, ...
    'group_color',Schaefer_Net_Labels.ten_network_col, 'alpha_fun',  @(x) ones(size(x))*0.8);  % plot circos
vis_plot = @(x) vis_corr(reformat_r_new(x, 'reconstruct'), 'nolines', 'group',Schaefer_Net_Labels.dat(:,2), 'group_color',Schaefer_Net_Labels.ten_network_col, ...
    'group_linewidth', 3, 'group_linecolor', 'k', ...
    'colorbar', 'group_ticks', 'triangle');

%% 2.1 Normal wei + thresholding: Activation
no_thres = false; % Can be run for full-map with no thresholding
threshold_lvl = 99; % leaving top 1%

% --- Visualizing activation
for f = 1:length(features_A)
    for r = 1:length(runs)
        feature = features_A{f};
        run = runs{r};
 
        % Getting weights
        wei = normal_wei.(feature).(run).A_wei; 
        if no_thres
            wei_thres = wei; % full map 
            figure_name = [feature '_' run '_full.pdf'];
        else 
            wei_thres = thres_fun(wei, threshold_lvl); % thresholding
            figure_name = [feature '_' run '_top' num2str(100-threshold_lvl) 'percent.pdf'];
        end 

        % Visualizing
        img = atlas_dat; % template
        img.dat = wei_thres;
        close all
        brain_activations_display(region(img), 'all2', 'colorbar');
        pagesetup(gcf);
        % Saving
        saveas(gcf, fullfile(figure_dir, 'normal_weights','activation', figure_name));
    end
end


%% 2.2 Normal weights + thresholding: Connectivity
threshold_lvl = 99.9; % leaving top 0.1%

% --- Visualizing connectivity
for f = 1:length(features_C)
    for r = 1:length(runs)
        feature = features_C{f};
        run = runs{r};

        % Getting weights
        wei = normal_wei.(feature).(run).C_wei; 
        wei_thr = reformat_r_new(thres_fun(wei, threshold_lvl), 'reconstruct'); 

        % Circos  multilayer
        figure_name_circos = ['circos_' feature '_' run '_top' num2str(100-threshold_lvl) 'percent.pdf'];
        close all;
        circos_plot(wei_thr);
        set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
        pagesetup(gcf);
        saveas(gcf, fullfile(figure_dir, 'normal_weights','connectivity', figure_name_circos));

        % Viss corr
        figure_name_viss = ['visscorr_' feature '_' run '_full.pdf'];
        close all;
        vis_plot(wei)
        set(gcf, 'color', 'w', 'Position', [744 492 774 557]);
        saveas(gcf, fullfile(figure_dir, 'normal_weights','connectivity', figure_name_viss));

    end
end

%% ==== Part 3 
% Visualizing significant weights 

%% 3.1 Boot wei: Activation 
p_lvl = 0.05; % leaving top 1%
p_options = {'fdr', 'unc'};

% !!!!!! NO FDR FOR CAPS_REST HRF_VOXEL model
% --- Visualizing activation
for f = 1:length(features_A)
    for r = 1:length(runs)

        for p = 1:length(p_options)
            try
                feature = features_A{f};
                run = runs{r};

                % Making statistic image
                A = statistic_image;
                A.p = boot_wei.(feature).(run).A_wei_p';
                A.dat = boot_wei.(feature).(run).A_wei';
                A.volInfo = atlas.volInfo;

                % Thresholding and plotting
                A_img = threshold(A, p_lvl, p_options{p});
                close all
                brain_activations_display(region(A_img), 'all2', 'colorbar');
                pagesetup(gcf);

                figure_name = [feature '_' run '_' p_options{p} num2str(p_lvl) '.pdf'];

                saveas(gcf, fullfile(figure_dir, 'bootstrap10000_weights/','activation', figure_name));
            catch
                print_header([feature ' | ' run '|' p_options{p}])
            end
        end
    end
end



%% 3.2 Boot wei: Connectivity
% ONlY FDR -> unc too much
p_lvl = 0.05;
threshold_lvl = 99.9; % leaving top 0.1%

% --- Visualizing connectivity
for f = 1:length(features_C)
    for r = 1:length(runs)
        try 
        feature = features_C{f};
        run = runs{r};

        % Getting weights
        wei = boot_wei.(feature).(run).C_wei; 
        thr_FDR = FDR(boot_wei.(feature).(run).C_wei_p, p_lvl);
        wei_thr_FDR = thres_fun(wei, thr_FDR);
        wei_thr = reformat_r_new(thres_fun(wei_thr_FDR, threshold_lvl), 'reconstruct'); 

        % Circos  multilayer
        figure_name_circos = ['circos_' feature '_' run 'FDR' num2str(p_lvl)  '_top' num2str(100-threshold_lvl) 'percent.pdf'];
        close all;
        circos_plot(wei_thr);
        set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
        pagesetup(gcf);
        saveas(gcf, fullfile(figure_dir, 'bootstrap10000_weights/','connectivity', figure_name_circos));
        catch
        end 
    end
end





%% PREV CODE -> Also good, but more complicated
% %% 1.2 Choose model to analyze
% 
% predictors = {'connectivity', 'connectivity_and_hrf_voxel', 'hrf_voxel'};
% runs = {'caps_rest', 'caps'};
% pred_name = predictors{3};
% run_name = runs{1};
% 
% % Generate filename for saving figures
% name_to_save_figures = [pred_name '_' run_name '.pdf'];
% 
% % Extract weights and p-values for the specified condition from model_data
% if isfield(model_data.(pred_name).(run_name), 'C_wei')
%     C_wei = model_data.(pred_name).(run_name).C_wei;
%     C_wei_p = model_data.(pred_name).(run_name).C_wei_p;
% end
% 
% if isfield(model_data.(pred_name).(run_name), 'A_wei')
%     A_wei = model_data.(pred_name).(run_name).A_wei;
%     A_wei_p = model_data.(pred_name).(run_name).A_wei_p;
% end
% 
% 
% %% ===== Part 2
% % Activation visualization
% predictors = {'connectivity', 'connectivity_and_hrf_voxel', 'hrf_voxel'};
% runs = {'caps_rest', 'caps'};
% 
% 
% hrf_voxel_wei = model_data.(pred_name).(run_name).A_wei;
% hrf_vowel_wei_p = model_data.(pred_name).(run_name).A_wei_p;
% 
% 
% %% 2.1 FDR & UNC
% % Making statistic image
% A = statistic_image;
% A.p = A_wei_p';
% A.dat = A_wei';
% A.volInfo = atlas.volInfo;
% 
% % Thresholding and plotting
% 
% A_unc = threshold(A, 0.05, 'unc'); 
% close all
% brain_activations_display(region(A_unc), 'all2', 'colorbar');
% pagesetup(gcf);
% %saveas(gcf, fullfile(basedir, 'figures_brain/Activation/unc05', name_to_save_figures));
% 
% if strcmp(predictors{pred_idx}, 'hrf_voxel') ~=1 && strcmp(runs{run_idx}, 'caps_rest') ~=1
%   A_fdr = threshold(A, 0.05, 'fdr');
%   close all
%   brain_activations_display(region(A_fdr), 'all2', 'colorbar');
%   pagesetup(gcf);
%   %saveas(gcf, fullfile(basedir, 'figures_brain/Activation/fdr05', name_to_save_figures));
% end
% 
% %% 2.2 Combined FDR
% % Caps & rest
% for run_idx = 1:length(runs)
%     run_name = runs{run_idx};
% 
%     A_wei_comb_p = model_data.connectivity_and_hrf_voxel.(run_name).A_wei_p;
%     A_wei_hrf_p =  model_data.hrf_voxel.(run_name).A_wei_p;
%     p_combined = [A_wei_comb_p,A_wei_hrf_p];
%     p_combined_FDR = FDR(p_combined, 0.05); 
%     
%     for pred_name = {'connectivity_and_hrf_voxel', 'hrf_voxel'}
%         name_to_save_figures = [pred_name{1} '_' run_name '.pdf'];
% 
%         A = statistic_image;
%         A.p =  model_data.(pred_name{1}).(run_name).A_wei_p';
%         A.dat = model_data.(pred_name{1}).(run_name).A_wei';
%         A.volInfo = atlas.volInfo;
% 
%         A_fdr_comb = threshold(A, p_combined_FDR, 'unc');
% 
%         close all
%         brain_activations_display(region(A_fdr_comb), 'all2', 'colorbar');
%         pagesetup(gcf);
%         saveas(gcf, fullfile(basedir, 'figures_brain/Activation/combined_fdr05', name_to_save_figures));
%     end
% end
% 
% %% ===== Part 3
% % Connectivity visualization
% 
% %% Circos multilayer
% % Local functions
% circos_plot = @(x) circos_multilayer(x, 'group',Schaefer_Net_Labels.dat(:,2),'region_names',Schaefer_Net_Labels.names, ...
%     'group_color',Schaefer_Net_Labels.ten_network_col, 'alpha_fun',  @(x) ones(size(x))*0.8);  % plot circos
% 
% thres_fun = @(x,y) x .* double(abs(x) > prctile(abs(x), y)); % threshold 
% 
% output_dir = fullfile(basedir, 'figures_brain/Connectivity/circos_multilayer');
% mkdir(fullfile(output_dir, 'FDR'));
% mkdir(fullfile(output_dir, 'FDR_thres01'));
% 
% mkdir(fullfile(output_dir, 'thres99'));
% mkdir(fullfile(output_dir, 'thres99_5'));
% mkdir(fullfile(output_dir, 'thres99_9'));
% mkdir(fullfile(output_dir, 'unc05'));
% 
%  
%  for con_idx = 1:length(predictors) 
%      for run_idx = 1:length(runs) 
%          if contains(predictors{con_idx}, 'connectivity')
% 
%              % Getting weights
%              [weights, name_to_save_figures] = HH_getting_weights_final_model(model_data, predictors{con_idx}, runs{run_idx});
%              C_wei_p = weights.C_wei_p;
%              C_wei = weights.C_wei;
% 
% 
%              if strcmp(runs{run_idx}, 'caps')  % nothing survived with caps only 
%                  % FDR correction + thresholding
%                  C_wei_p_FDR = FDR(C_wei_p, 0.05);
%                  folder_name_thres = 'FDR_thres01';
%                  folder_name = 'FDR';
% 
%                  C_wei_FDR = C_wei .* (C_wei_p <= C_wei_p_FDR);
%                  matrix_FDR_thres = reformat_r_new(thres_fun(C_wei_FDR, 99.9), 'reconstruct'); %top0.1%
% 
%                  close all;
%                  circos_plot(matrix_FDR_thres);
%                  set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
%                  pagesetup(gcf);
%                  saveas(gcf, fullfile(output_dir, folder_name_thres, name_to_save_figures));
% 
%                  % FDR correction
%                  close all;
%                  circos_plot(reformat_r_new(C_wei_FDR, 'reconstruct'));
%                  set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
%                  pagesetup(gcf);
%                  saveas(gcf, fullfile(output_dir, folder_name, name_to_save_figures));
%              end
% 
%              % Thresholding
%              thres_values = {99, 99.5, 99.9};
%              for thres_idx = 1:length(thres_values)
%                  threshold = thres_values{thres_idx};
%                  matrix_thres = reformat_r_new(thres_fun(C_wei, threshold), 'reconstruct');
%                  folder_name = strrep(['thres' num2str(threshold)], '.', '_');
% 
%                  close all;
%                  circos_plot(matrix_thres);
%                  set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
%                  pagesetup(gcf);
%                  saveas(gcf, fullfile(output_dir, folder_name, name_to_save_figures));
%              end
% 
%              % Uncorrected
%              matrix_weights_unc = reformat_r_new(C_wei .* (C_wei_p < 0.05), 'reconstruct');
%              folder_name = 'unc05';
% 
%              close all;
%              circos_plot(matrix_weights_unc);
%              set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
%              pagesetup(gcf);
%              saveas(gcf, fullfile(output_dir, folder_name, name_to_save_figures));
%          end
% %          catch 
% %             % Display warning and continue loop
% %             warning('An error occurred with predictor %s and run %s: %s', predictors{con_idx}, runs{run_idx});
% %         end
%      end 
%  end 
% 
% 
% %%
% C_wei_FDR = C_wei .* (C_wei_p <= C_wei_p_FDR);
% C_wei_FDR_thres = thres_fun(C_wei_FDR);
% matrix_FDR_thres = reformat_r_new(C_wei_FDR_thres, 'reconstruct');
% 
% close all;
% circos_plot(matrix_FDR_thres);
% set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
% pagesetup(gcf);
% saveas(gcf, fullfile(basedir, 'figures_brain/Connectivity/circos_multilayer/', folder_name_thres, [pred_name '_' run_name '.pdf']));
% 
% 
% % Thresholding
% C_wei_thres = thres_fun(C_wei, 99.5);
% matrix_thres = reformat_r_new(C_wei_thres, 'reconstruct');
% folder_name_thres = 'thres05';
% 
% close all;
% circos_plot(matrix_FDR_thres);
% set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
% pagesetup(gcf);
% saveas(gcf, fullfile(basedir, 'figures_brain/Connectivity/circos_multilayer/', folder_name_thres, [pred_name '_' run_name '.pdf']));
% 
% 
% 
% 
% 
% 
% %% Prep
% plot_options_all = {'top10_unc05', 'unc05'};
% plot_options = {'top10_unc05'};
% 
% matrix_weights = reformat_r_new(C_wei, 'reconstruct');
% 
% 
% 
% %% Viss corr (full)
% for plot_idx = 1:length(plot_options)
%     switch plot_options{plot_idx}
%         case 'top10_unc05'
%             % Top 10 positive & negative weights when P < 0.05
%             significant_indices = C_wei_p < 0.05;
%             significant_weights = C_wei .* significant_indices;
% 
%             [sorted_weights, sorted_idx] = sort(significant_weights(:), 'descend');
%             top_positive_weights = sorted_weights(1:10);
%             top_negative_weights = sorted_weights(end-9:end);
%             positive_indices = sorted_idx(1:10);
%             negative_indices = sorted_idx(end-9:end);
% 
%             top_significance_matrix = zeros(size(C_wei_p));
%             top_significance_matrix(positive_indices) = 1;
%             top_significance_matrix(negative_indices) = 1;
% 
%             matrix_top10_sig = reformat_r_new(top_significance_matrix, 'reconstruct');
% 
%             sig_to_plot = matrix_top10_sig;
%         case 'unc05'
%             % P < 0.05 weights
%             sig_to_plot = reformat_r_new(C_wei_p .* (C_wei_p < 0.05), 'reconstruct');
%     end
% 
%     close all;
%     vis_corr(matrix_weights, 'nolines', 'group',Schaefer_Net_Labels.dat(:,2), 'group_color',Schaefer_Net_Labels.ten_network_col, ...
%         'group_linewidth', 3, 'group_linecolor', 'k', ...
%         'colorbar', 'group_ticks', 'sig', sig_to_plot, 'triangle', 'sig_linewidth', 1, 'sig_color', [0 0 0]);
%     set(gcf, 'color', 'w', 'Position', [744 492 774 557]);
%     
%     % Set the y-axis with network names
%     axis on;
%     ytick_labels = {'VN', 'SMN', 'DAN', 'VAN', 'LN', 'FPN', 'DMN', 'SCTX', 'CB', 'BS/PAG'};
%     ytick_positions = [15, 46, 75, 100, 118, 139, 180, 220, 250, 265];
% 
%     set(gca, 'ytick', ytick_positions, 'yticklabels', ytick_labels, ...
%         'TickLabelInterpreter', 'none', 'fontsize', 12, 'YColor', 'k', 'xtick', []);
%     box off;
% 
%     % Increase the distance of ytick labels from the axis
%     ax = gca;
%     ax.YRuler.TickLabelGapOffset = +25;
% 
%     pagesetup(gcf);
%     saveas(gcf, fullfile(basedir, 'figures_brain/Connectivity/viss_corr', plot_options{plot_idx}, name_to_save_figures));
% end
% 
% %% Viss corr (group)
% % Mean
% close all;
% vis_corr(matrix_weights, 'nolines', 'group',Schaefer_Net_Labels.dat(:,2), 'group_color',Schaefer_Net_Labels.ten_network_col, ...
%     'group_linewidth', 3, 'group_linecolor', 'k', ...
%     'colorbar', 'group_ticks', 'triangle', 'group_mean');
% set(gcf, 'color', 'w', 'Position', [744 492 774 557]);
% 
% pagesetup(gcf);
% saveas(gcf, fullfile(basedir, 'figures_brain/Connectivity/viss_corr/group/mean', name_to_save_figures));
% 
% % Thresholded sum
% matrix_weights_thres = reformat_r_new(C_wei .* double(abs(C_wei) > prctile(abs(C_wei), 99.9)), 'reconstruct');
% close all;
% vis_corr(matrix_weights_thres, 'nolines', 'group',Schaefer_Net_Labels.dat(:,2), 'group_color',Schaefer_Net_Labels.ten_network_col, ...
%     'group_linewidth', 3, 'group_linecolor', 'k', ...
%     'colorbar', 'group_ticks', 'triangle', 'group_sum', 'clim', [-1 1]);
% set(gcf, 'color', 'w', 'Position', [744 492 774 557]);
% yticklabels('VN')
% 
% pagesetup(gcf);
% saveas(gcf, fullfile(basedir, 'figures_brain/Connectivity/viss_corr/group/sum/thres01', name_to_save_figures));
% 
% % Unc sum
% matrix_weights_unc = reformat_r_new(C_wei .* (C_wei_p < 0.05), 'reconstruct');
% close all;
% vis_corr(matrix_weights_unc, 'nolines', 'group',Schaefer_Net_Labels.dat(:,2), 'group_color',Schaefer_Net_Labels.ten_network_col, ...
%     'group_linewidth', 3, 'group_linecolor', 'k', ...
%     'colorbar', 'group_ticks', 'triangle', 'group_sum');
% set(gcf, 'color', 'w', 'Position', [744 492 774 557]);
% yticklabels('VN')
% 
% pagesetup(gcf);
% saveas(gcf, fullfile(basedir, 'figures_brain/Connectivity/viss_corr/group/sum/unc05', name_to_save_figures));
% 
% %% Circos multilayer
% close all;
% circos_multilayer(matrix_weights_thres, 'group',Schaefer_Net_Labels.dat(:,2),'region_names',Schaefer_Net_Labels.names, ...
%     'group_color',Schaefer_Net_Labels.ten_network_col);
% set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
% pagesetup(gcf);
% saveas(gcf, fullfile(basedir, 'figures_brain/Connectivity/circos_multilayer/thres01', name_to_save_figures));
% 
% close all;
% circos_multilayer(matrix_weights_unc, 'group',Schaefer_Net_Labels.dat(:,2),'region_names',Schaefer_Net_Labels.names, ...
%     'group_color',Schaefer_Net_Labels.ten_network_col);
% set(gcf, 'color', 'w', 'Position', [744 774 1200 800]);
% pagesetup(gcf);
% saveas(gcf, fullfile(basedir, 'figures_brain/Connectivity/circos_multilayer/unc05', name_to_save_figures));
% 
% 
% %% Check 
% rois_idx = atlas.dat;
% roi_names = Schaefer_Net_Labels.names;
% rois_idx_sig = unique(atlas.dat.*A_fdr.sig);
% roi_names(rois_idx_sig(2:end,:));
% 
% 
