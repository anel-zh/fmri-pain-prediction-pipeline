%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 30thMay 2025 -> 13 June 2025 - revised and checked before
% project transfer
% Goal: 
%     - Dataset: MPC-Wani 
%     - Atlas: Schaefer_265. 
%     - Variance decomposition on final models -> calculation and
%     visualizing 

%% Content
% ====== Part 1 
% 1. Loading directories and configuration structure.
% 2. Loading the model performance from S2_*_cross_testing.

% ====== Part 2 (Variance decomposition)
% 1. Calculating each cases variance (saving)
% 2. Visualizing variance distribution with stacked bar plot (saving).  

%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';

% Directories 
HH_set_dir_mint(model, dataset);

% Config structure
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;

%% 1.2 Loading final perfomance from S2_*_cross_testing
load(fullfile(basedir, 'model_development_results/9Jun2025_final_model/all_performance_including_cross_testing'), 'main_table_result')


%% Part 2 
% Variance decomposition 
%% 2.1 Calculating variance for each condition
models = {'caps_rest', 'caps', 'caps_rest', 'caps'};
tests  = {'caps_rest', 'caps', 'caps', 'caps_rest'};
% Initialize result table
num_cases = numel(models);
var_table = table('Size', [num_cases, 6], ...
    'VariableTypes', {'string', 'string', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Model', 'Test On', 'C_unique', 'A_unique', 'Shared', 'Unexplained'});

% Fill the table
for i = 1:num_cases
    model = models{i};
    test = tests{i};

    % For combined model
    CA = main_table_result.rsquare(...
        strcmp(main_table_result.("Brain Feature"), 'connectivity_and_hrf_voxel') & ...
        strcmp(main_table_result.Model, model) & ...
        strcmp(main_table_result.("Test on"), test));
    
    % For connectivity only
    C = main_table_result.rsquare(...
        strcmp(main_table_result.("Brain Feature"), 'connectivity') & ...
        strcmp(main_table_result.Model, model) & ...
        strcmp(main_table_result.("Test on"), test));
    
    % For activation only
    A = main_table_result.rsquare(...
        strcmp(main_table_result.("Brain Feature"), 'hrf_voxel') & ...
        strcmp(main_table_result.Model, model) & ...
        strcmp(main_table_result.("Test on"), test));

    % Calculating
    shared = (C + A) - CA;
    C_unique = C - shared;
    A_unique = A - shared;
    unexplained = 1 - CA;

    var_table.Model(i) = model;
    var_table.("Test On")(i) = test;
    var_table.C_unique(i) = C_unique;
    var_table.A_unique(i) = A_unique;
    var_table.Shared(i) = shared;
    var_table.Unexplained(i) = unexplained;
end

save(fullfile(basedir, 'model_development_results/9Jun2025_final_model/all_variance_decomposition_including_cross_testing'), 'var_table', '-v7.3')

%% 2.2 Visualizing results 
fig_ids = {'1', '2', '1(ct)', '2(ct)'}; 
fig_name = 'all_variance_decomposition_including_cross_testing.pdf';
fig_dir = fullfile(basedir,'figures/model/9Jun2025_final_model/variance_decomposition'); %mkdir(fig_dir)

% Stacked bar plot
close all
bar_data = [var_table.C_unique, var_table.A_unique, var_table.Shared, var_table.Unexplained]';  

% BLue
colors = [
    0.769    0.878    0.98;   % C_unique 
    0.608   0.741    0.976;   % A_unique
    0.404    0.667    0.976;   % Shared 
   0.990      0.990      1%1.0    0.7    0.7    % Unexplained
];

% Plot
figure;
h = bar(bar_data', 'stacked');
for i = 1:length(h)
    h(i).FaceColor = colors(i, :);
end
xticklabels(fig_ids);
ylabel('Variance Explained');
legend({'C Unique', 'A Unique', 'Shared', 'Unexplained'}, 'Location', 'northeastoutside');

hold on;
% Get center coordinates (based on
% https://www.mathworks.com/matlabcentral/answers/1755450-how-to-add-numerical-value-in-the-stacked-bar-chart)
xbarCnt = vertcat(h.XEndPoints); 
ybarTop = vertcat(h.YEndPoints); 
ybarCnt = ybarTop - bar_data/2;  

% Create text string
txt = compose('%.2f', bar_data); 

% Add text
text(xbarCnt(:), ybarCnt(:), txt(:), ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 9, 'FontWeight','bold');
yticks(0:0.2:1)

xlim([0.2,size(bar_data,2)+0.7])
% Add total explained variance label at the top of each bar
for case_j = 1:size(bar_data,2)
    total_variance = sum(bar_data(1:3, case_j));
    total_variance_position = sum(bar_data(1:3, case_j) .* (bar_data(1:3, case_j) > 0));  % Total variance for each column
    text(case_j+0.03, total_variance_position + 0.02, sprintf('Total: %.2f%', total_variance), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 9, 'FontWeight', 'bold', 'Color', 'blue');
end


box off;
set(gca, 'tickdir', 'out','ticklength', [.02, .02], 'FontSize', 20, 'LineWidth', 1.5, 'color', 'w')
legend({'C Unique', 'A Unique', 'Shared', 'Unexplained'}, 'Location', 'northeastoutside', 'FontSize', 10, 'Box','off');
set(gcf, 'Position', [451   692   538   270], 'color', 'w'); 
pagesetup(gcf);
saveas(gcf, fullfile(fig_dir,fig_name))


%% Other colors
% Diverse
% colors = [
%     1.0    0.7    0.7;   % C_unique 
%     0.8   0.7    1.0;   % A_unique
%     1.0    0.9    0.6;   % Shared 
%     0.95    0.95    0.95%1.0    0.7    0.7    % Unexplained
% ];

% % Purple
% colors = [
%     0.765    0.592    0.722;   % C_unique 
%     0.992   0.816    0.953;   % A_unique
%     0.871    0.537    0.749;   % Shared 
%     1      0.953      0.949%1.0    0.7    0.7    % Unexplained
% ];

