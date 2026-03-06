function HH_plot_violin_mint(test_performance_spec, dataset, brain_measure_all, runs_all, varargin)
% Visualizing the results
%colors = [0.545, 0.8, 0.722; 0.945, 0.718, 0.533; 0.643, 0.639, 0.769; 0.969, 0.745, 0.745; 0.482, 0.827, 0.918]
blue_colors = [0.027, 0.051, 0.612; 0.208, 0.447, 0.937; 0.227, 0.745, 0.976; 0.655, 0.902, 1];
close all;
figure;

session_colormap = [0.667, 0.329, 0.525; 0.988, 0.561, 0.329; 
    0.871, 0.675, 0.502; 0.145, 0.443, 0.502];
stat_results1 = table();

stat_results2 = table();
%session_colormap = [0.871, 0.675, 0.502; 0.145, 0.443, 0.502];

for brain_measure_idx = 1:length(brain_measure_all)
    brain_measure = brain_measure_all{brain_measure_idx};

    r_all = [];
    across_r = [];
    mean_r = [];
    r2 = [];
    for run_idx = 1:length(runs_all)
        run = runs_all{run_idx};
        r_all = [r_all, test_performance_spec.(dataset).(brain_measure).(run).r'];
        across_r = [across_r; test_performance_spec.(dataset).(brain_measure).(run).corr_y];
        mean_r = [mean_r; test_performance_spec.(dataset).(brain_measure).(run).mean_r];
        r2 = [r2; test_performance_spec.(dataset).(brain_measure).(run).rsquare];
    end

    main_color = blue_colors(brain_measure_idx, :);
    boxplot_wani_2016(r_all, 'violin', 'dots', 'box_trans', 0.05, 'samefig', ...
        'color', repmat(main_color, 4, 1), 'dot_alpha', 0.8, ...
        'mediancolor', main_color, 'boxlinecolor', main_color);
 % T-test
    [h, p] = ttest(r_all(:,1), r_all(:,2)); % Test if caps & quinine significantly different

    % Store results in table
    stat_results1 = [stat_results1; table({brain_measure}, mean(r_all(:,1)), mean(r_all(:,2)), p, h, ...
        'VariableNames', {'Brain_Measure', ['Mean:' runs_all{1}],['Mean:' runs_all{2}], 'p_value', 'Significant'})];

    [h, p] = ttest(r_all(:,3), r_all(:,4)); % Test if caps & quinine significantly different

    % Store results in table
    stat_results2 = [stat_results2; table({brain_measure}, mean(r_all(:,3)), mean(r_all(:,4)), p, h, ...
        'VariableNames', {'Brain_Measure', ['Mean:' runs_all{3}],['Mean:' runs_all{4}], 'p_value', 'Significant'})];


    % Connect dots across columns
    hold on;
    for row_idx = 1:size(r_all, 1)
        y_vals = r_all(row_idx, :);
        plot(1:2, y_vals(:, 1:2), '-o', 'Color', session_colormap(row_idx, :), ...
            'MarkerFaceColor', session_colormap(row_idx, :), 'LineWidth', 1.5);

        plot(3:4, y_vals(:, 3:4), '-o', 'Color', session_colormap(row_idx, :), ...
            'MarkerFaceColor', session_colormap(row_idx, :), 'LineWidth', 1.5);
    end
    hold off;

    % Add text annotations for mean_r
    for k = 1:length(mean_r)
        text(k, -1, sprintf('r = %.2f', mean_r(k)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 12, 'FontWeight', 'bold');
        text(k, -1.3, sprintf('r2 = %.2f', r2(k)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 12, 'FontWeight', 'bold');
    end

    xticks(1:4);
    xticklabels(categorical(strrep(runs_all, '_', ' & ')));
    set(gcf, 'Position', [680, 48, 1158, 914], 'color', 'w');
    box off;
    grid off;
    yticks(-1:0.5:1);
    ylim([-1.5,1.5]);
   % title(strrep(brain_measure, '_', ' '));

   % Save the figure
   if ~isempty(varargin)
       savedir = varargin{1};
       disp(['Saving image at ' savedir]);
       set(gca, 'tickdir', 'out','ticklength', [.02, .02], 'FontSize', 20, 'LineWidth', 1.5, 'color', 'w')
       set(gcf, 'Position', [451   709   359   268], 'color', 'w'); % Adjust size for a 2x6 grid
       pagesetup(gcf);
       if ~exist(savedir, 'dir')
           mkdir(savedir);
       end
       saveas(gcf, fullfile(savedir, [brain_measure, '.pdf']));
   end
end
disp(stat_results1);
disp(stat_results2);

end 