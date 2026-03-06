%% Visualizing (specificity)
function HH_plot_specificity_mint(test_performance, dataset, brain_measure_all, runs_all, runs_all_names, savedir)
load(which('colormap_ggplot2.mat'), 'col10_ggplot2')
original_set_results = load(which('Final_table_full_Oct24.mat'));
original_set_results = original_set_results.result_table;
color_caps = col10_ggplot2(7,:);
color_quinine = col10_ggplot2(10,:);

close all;
%runs_all = {'caps','quinine'};
%runs_all = {'caps_rest','quinine_rest','caps', 'quinine'};
%runs_all_names = {'C', 'Q'};
stat_results = table();
figure;

session_colormap = [0.667, 0.329, 0.525; 0.988, 0.561, 0.329; 
    0.871, 0.675, 0.502; 0.145, 0.443, 0.502];

for brain_measure_idx = 1:length(brain_measure_all)
    brain_measure = brain_measure_all{brain_measure_idx};

    r_all = [];
    across_r = [];
    mean_r = [];
    for run_idx = 1:length(runs_all)
        % Specificity results
        run = runs_all{run_idx};
        r_all = [r_all, test_performance.(dataset).(brain_measure).(run).r'];
        across_r = [across_r; test_performance.(dataset).(brain_measure).(run).corr_y];
        mean_r = [mean_r; test_performance.(dataset).(brain_measure).(run).mean_r];
    end

    % T-test
    [h, p] = ttest(r_all(:,1), r_all(:,2)); % Test if caps & quinine significantly different

    % Store results in table
    stat_results = [stat_results; table({brain_measure}, mean(r_all(:,1)), mean(r_all(:,2)), p, h, ...
        'VariableNames', {'Brain_Measure', ['Mean:' runs_all_names{1}],['Mean:' runs_all_names{2}], 'p_value', 'Significant'})];



    % Original sessions results 
    temp_run = run;
    if contains(run,'quinine') 
        temp_run = replace(run, 'quinine', 'caps');
    end 
    mean_r_original = original_set_results.("Within-s. corr.")(strcmp(original_set_results.Predictors, [brain_measure ' | ' temp_run]));


    plot_specificity_box(r_all(:,1), r_all(:,2), 'colors', [color_caps; color_quinine]);
    hold on;

    xticks(1:2);
    xticklabels(categorical(strrep(runs_all_names, '_', ' & ')));
    
    plot(0:3, repmat(mean_r_original,1,4) , '--', 'LineWidth', 1.5, 'color', 'k'); % line for previous results

    set(gcf, 'Position', [680, 48, 1158, 914], 'color', 'w');
    box off;
    grid off;
    yticks(-1:0.2:1);
    set(gca, 'tickdir', 'out','ticklength', [.02, .02], 'FontSize', 20, 'LineWidth', 1.5, 'color', 'w')
    set(gcf, 'Position', [451   709   268   268], 'color', 'w'); % Adjust size for a 2x6 grid
    pagesetup(gcf);

   % Save the figure
    %savedir = fullfile(basedir, 'figures/', condition_dir, '/violin_plots/');
    if ~exist(savedir, 'dir')
        mkdir(savedir);
    end

    if contains(runs_all{1}, '_rest')
       saveas(gcf, fullfile(savedir, [brain_measure '_with_rest.pdf']));
    else 
       saveas(gcf, fullfile(savedir, [brain_measure '.pdf']));
    end 

end

