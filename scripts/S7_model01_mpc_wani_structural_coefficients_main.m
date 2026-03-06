%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 6th Jan 2024 -> 16th Jun 2025 revised and updated before
% project transfer
% Goal: 
%     - Dataset: MPC- Wani. 
%     - Atlas: Schaefer_265. 
%     - Calculation of structural coefficients for final model. On original
%     data and replication data. For hrf_voxel model. 

%% Content
% ====== Part 1 
% 1. Loading directories and configuration structure.
% 2. Loading brain data (original and replication).
% 3. Loading testing results from original model development from S2 (for model weights and yfit).
% 4. Loading atlas information (for visualization)

% ====== Part 2 (structural coefficients)
% 1. Defining looping parameters.
% 2. Calculating structural coefficients. 

clc
clear
%% === Part 1 
% Loading
%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';

% Directories
HH_set_dir_mint(model, dataset);
% % HH_set_dir_mint(model, dataset,'/home/anel/nas1/');

% Config structure
config_structure_all = HH_load_config_mint(dataset,'save',false);
% config_structure_all = HH_load_config_mint(dataset,'save',false,'base', '/home/anel/nas1/');

config_structure = config_structure_all.model01_mpc_wani;
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;
figure_dir = fullfile(basedir, '/figures/model/9Jun2025_final_model/structural_coeff/hrf_voxel');
%% 1.2 Loading brain data
% Original data 
load(fullfile(basedir,'optimized_data_files/for_model_dev_diff_vn_step_final_ver/', 'vn_split_data_mpc_wani_binned_C'), 'vn_split_data')

% Replication sessions data
load(fullfile(basedir, 'optimized_data_files', 'replication_data_diff_vn_step'), "vn_dat"); 

% Combining to one structure for looping convinience
vn_split_data.independent_set = vn_dat.independent_set;
%% 1.3 Loading testing results from original model development (S2)
% Performance on the original data
load(fullfile(basedir, '/model_development_results/9Jun2025_final_model/results_structure_full.mat'), 'testing')
 
% Performance on the replication data
load(fullfile(basedir,'/model_development_results/9Jun2025_final_model/final_model_on_replication_including_cross_testing.mat'), 'main_table_result');

%% 1.4 Loading atlas details
load('Schaefer_Net_Labels_r265.mat'); % Schaefer_Net_Labels
atlas_dat = fmri_data((which('Schaefer_265_combined_2mm.nii')), which('gray_matter_mask.nii'));

%% ==== Part 2 
% Calculating structural coefficients
% - -> This part SHOULD be run twice: by changing dataset option (1) for original and (2) for replication
% sessions
%% 2.1 Choosing case 

feature_case = 'hrf_voxel';
model_used = 'caps_rest';
% for data saving 
savedir = fullfile(basedir, 'model_development_results/9Jun2025_final_model/structural_coefficients/');
% for figures saving
figure_savedir = fullfile(basedir, 'figures/model/9Jun2025_final_model/structural_coefficients/');

dataset = 'replication';
switch dataset 
    case 'original'
        dataset_name = 'original_data';
        runs = {'caps'};
        field_name = 'test'; 
    case 'replication'
        dataset_name = 'replication_data';
        runs = {'caps','quinine'};
        field_name = 'independent_set';
end 

%% 2.2 Calculating structural coefficients
for r = 1:length(runs)
    run_case = runs{r};
    figure_name = ['run_' run_case '_model_' model_used '_' feature_case];

    % Getting data
    brain_input_x = vn_split_data.(field_name).([feature_case '_' run_case]);
    if strcmp(dataset, 'original')
        test_yfit = testing.hrf_voxel.(model_used).ratings_all.plot.(run_case).yfit;
    else
        test_yfit_ratings = main_table_result.ratings_all(strcmp(main_table_result.("Brain Feature"), feature_case) & ...
            strcmp(main_table_result.Model, model_used) & strcmp(main_table_result.("Test on"), run_case));
        test_yfit = test_yfit_ratings.plot.(run_case).yfit;
    end 

    n_sessions_test = size(test_yfit,1);

    % Getting structural coefficients
    tic %-> 2-3 minutes for 5 sessions
    st_coef = cell(1,n_sessions_test);
    for sess_idx = 1:n_sessions_test
        dat = fmri_data;
        dat.dat = brain_input_x{sess_idx};
        dat.Y = test_yfit(sess_idx,:)'; %not used
        dat.X = dat.Y; % event regressor -> encoding map
        regress_out = regress(dat,'brainony','nodisplay','robust','noverbose');
        st_coef{sess_idx} = regress_out;
    end
    toc

    % saving encoding map
    sc_img = statistic_image;
    sc_img.volInfo = atlas_dat.volInfo;
    sc_img.removed_voxels = st_coef{1}.b.removed_voxels;
    for sess_idx = 1:n_sessions_test
        sc_img.dat(:,sess_idx) = st_coef{sess_idx}.b.dat(:,1);
        sc_img.p(:,sess_idx) = st_coef{sess_idx}.b.p(:,1);
    end
    sc_img.fullpath = fullfile(savedir,dataset_name, [figure_name '.nii']);
    write(sc_img,'overwrite');


    % visualization (CAN be re-loaded from here)
    imgdir = filenames(fullfile(savedir, dataset_name, [figure_name '.nii']));
    sc_img = fmri_data(imgdir{1}, which('gray_matter_mask.nii'));

    close all;
    tt_img = ttest(sc_img);
    tt_thres = threshold(tt_img,0.05,'unc');
    brain_activations_display(region(tt_thres), 'all2', 'colorbar');
    pagesetup(gcf);
    saveas(gcf, fullfile(figure_savedir ,dataset_name, [figure_name '_unc.pdf']))
    close all;
end




%% Previous code
% %% 1.2 Loading data
% % ========= Model weights
% model_data.(dataset) = HH_loading_final_models(basedir, model, dataset, 'normal_wei'); % 'boot_wei' - another option 
% 
% % ========= Brain Data
% input_load_parameters = {config_structure.participants_to_analyze.main, ...
%                          config_structure.denoising_method, config_structure.atlas_name, ...
%                          [config_structure.task_runs.caps,config_structure.task_runs.rest], config_structure.dataset};
% 
% 
% % Pattern Activation (Voxel)
% hrf_voxel = mint_a2_load_predictors(savedir,input_load_parameters{:}, 'hrf_voxel');
% 
% 
% %  ========= Split 
% z_scaling = false;
% vn_scaling = true; % variance normalization
% 
% [train_data, valid_data, test_data] = HH_extract_split_data_with_normalization_mint(config_structure, 'main', ...
%                                                                  z_scaling, vn_scaling, ...   
%                                                                  hrf_voxel);
% %% 1.3 Loading atlas details (for visualizations)
% load('Schaefer_Net_Labels_r265.mat'); % Schaefer_Net_Labels
% atlas_dat = fmri_data((which('Schaefer_265_combined_2mm.nii')), which('gray_matter_mask.nii'));
% 
% %% ==== Part 2 
% % Calculating structural coefficients
% % 
% % %% 2.1 Preparing input from testing set
% % % Case
% % feature_case = 'hrf_voxel';
% % run_case = 'rest';
% % switch run_case
% %     case 'rest'
% %         n_bin = 8; % for future convenience
% %     otherwise
% %         n_bin = 15;
% % end
% % mask_weigths = false;
% % 
% % model_used = 'caps_rest';
% % figure_name = ['run_' run_case '_model_' model_used '_' feature_case];
% % 
% % % Behavioral data (actual and predicted)
% % load('Final_model_best_5Dec2024.mat', 'results_structure_best');
% % test_model_results = results_structure_best.(feature_case).(['results_' model_used '_same_time_window']).testing.variance_normalized;
% % test_yfit = test_model_results.test_yfit.test_yfit.(run_case)'; 
% % 
% % % Brain data 
% % brain_input_x = cellfun(@transpose, test_data.variance_normalized.(['hrf_voxel_' run_case]), 'un', false); % X 
% % n_sessions_test = length(brain_input_x); % for future convenience 
% % n_voxels = size(brain_input_x{1}, 2);
% % 
% % 
% % % Getting structural coefficients
% % tic %-> 140 sec for 5 sessions
% % st_coef = cell(1,n_sessions_test);
% % for sess_idx = 1:n_sessions_test
% %     dat = fmri_data;
% %     dat.dat = brain_input_x{sess_idx}';
% %     dat.Y = test_yfit(:,sess_idx); %not used
% %     dat.X = dat.Y; % event regressor -> encoding map 
% %     regress_out = regress(dat,'brainony','nodisplay','robust','noverbose');
% %     st_coef{sess_idx} = regress_out;
% % end 
% % toc 
% % % saving encoding map
% % 
% % sc_img = statistic_image;
% % sc_img.volInfo = atlas_dat.volInfo;
% % sc_img.removed_voxels = st_coef{1}.b.removed_voxels;
% % for sess_idx = 1:n_sessions_test
% %     sc_img.dat(:,sess_idx) = st_coef{sess_idx}.b.dat(:,1);
% %     sc_img.p(:,sess_idx) = st_coef{sess_idx}.b.p(:,1);
% % end
% % sc_img.fullpath = fullfile(basedir,'structural_coeff',[figure_name '.nii']);
% % write(sc_img,'overwrite');
% % 
% % save(fullfile(basedir,'structural_coeff/', [figure_name '.mat']),'st_coef','-v7.3')
% % 
% % % visualization
% % imgdir = filenames(fullfile(basedir,'structural_coeff',[figure_name '.nii']));
% % sc_img = fmri_data(imgdir{1}, which('gray_matter_mask.nii'));
% % close all;
% % 
% % tt_img = ttest(sc_img);
% % tt_thres = threshold(tt_img,0.05,'unc');
% % brain_activations_display(region(tt_thres), 'all2', 'colorbar');
% % pagesetup(gcf);
% % saveas(gcf, fullfile(basedir,'structural_coeff/', [figure_name '_unc.pdf']))
% % close all;
% % 
% % 
% % 
% % %% Previous scripts 
% % % %% ploting networks
% % % colors_new = [            0    0.4470    0.7410
% % %     0.8500    0.3250    0.0980
% % %     0.9290    0.6940    0.1250
% % %     0.4940    0.1840    0.5560
% % %     0.4660    0.6740    0.1880
% % %     0 0.761 1
% % %     0.6000    0.3450    0.2240 
% % %     0.502    0.071    0.071
% % %      0.059 0.467 0.478
% % %     0.769, 0.282, 0.569];
% % % 
% % % figure;
% % % hold on;
% % % for i = 1:length(network_names)
% % %     plot([0, 1], [i, i], 'Color', colors_new(i,:), 'LineWidth', 5); % line for each network
% % % end
% % % hold off;
% % % 
% % % % Customize the plot
% % % axis off;
% % % % Create a label for each network
% % % for i = 1:length(network_names)
% % %     text(1.01, i, strrep(network_names{i}, '_', '&'), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'middle');
% % % end
% % % 
% % % set(gca, 'tickdir', 'out', 'ticklength', [.02, .02], 'FontSize', 20, 'LineWidth', 1.5, 'color', 'w');
% % % set(gcf, 'Position', [466   769   738   193], 'color', 'w'); % Adjust size for a 2x6 grid
% % % pagesetup(gcf);
% % % %saveas(gcf, fullfile(figure_dir, 'color_scheme_network.pdf'));
% % % 
% % %                                   
