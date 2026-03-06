function HH_model_performance_plot_mint(result_table, predictors_names, plot_details, config_structure, input_option)
close all
plot_case = plot_details.plot_case;
TR_bin = plot_details.TR_bin;

dataset = strrep(config_structure.dataset, '_', '-');
atlas = strrep(config_structure.atlas_name, '_', ' ');

binning_option = strrep(config_structure.binning_conditions.main{1}, '_', ' ');
normalization_options = {'variance_normalized'};
print_header('Using default normalization option - variance normalized');
print_header('Using default binning option - same-time-window');

colors = lines(length(unique(extractBefore(predictors_names, ' |')))); % Set the color scheme based on the number of brain measures

% Dictionary for coloring and line style
brain_measure_color_map = dictionary(unique(extractBefore(predictors_names, ' |')), num2cell(colors,2));

for scale_idx = 1:length(normalization_options)
    normalization_name = normalization_options{scale_idx};
    brain_measure_case_name = result_table.Predictors;
    
    figure;
    [~, s] = title(strrep(sprintf('%s performance based on %s (%s)', input_option, plot_case, normalization_name),  '_', ' '), sprintf('%s | %s | %s | %s', dataset, atlas, TR_bin, binning_option));
    s.Color = 'b';

    hold on;
    for i = 1:length(result_table.(plot_case))
        % Get the brain measure name for this row
        brain_measure = brain_measure_case_name{i};
        
        % Determine the line style based on the brain measure name/model_input
        if contains(brain_measure, 'caps_rest')
            line_style = '-';
        else
            line_style = ':';
        end
        
        % Get the corresponding color
        dictionary_check = {extractBefore(brain_measure, ' |')};
%         if contains(dictionary_check, 'and')
%             dictionary_check = extractAfter(dictionary_check, '\_and\_');
%         end 
        color_idx = cell2mat(brain_measure_color_map(dictionary_check));
        
        % Plot with the appropriate color and line style
        plot([0, result_table.(plot_case)(i)], [length(result_table.(plot_case)) - i + 1, length(result_table.(plot_case)) - i + 1], ...
            line_style, 'Color', color_idx, 'MarkerFaceColor', color_idx, 'Marker', 'o', 'LineWidth', 1.5); 
    end
    hold off;

    % Reverse the order of yticks and labels
    yticks(1:length(brain_measure_case_name));
    yticklabels(flip(strrep(brain_measure_case_name, '_', '\_')));
    xlabel(sprintf('%s', strrep(plot_case, '_', '\_')));
    ylabel('Conditions');
    ylim([0.5, length(result_table.(plot_case)) + 0.5]);

    if min(result_table.(plot_case)) < 0
        xlim([min(result_table.(plot_case))-0.2, 1]);

    else
        xlim([0, 1]);
    end
    grid on;

    % Annotate exact Corr_Y values near the markers and PC numbers at the end of x-axis
    for i = 1:length(result_table.(plot_case))
        if min(result_table.(plot_case)(i)) < 0
            text(result_table.(plot_case)(i) - 0.07, length(result_table.(plot_case)) - i + 1, sprintf('%.2f', result_table.(plot_case)(i)), 'VerticalAlignment', 'middle', 'Color', 'k');
        else
            text(result_table.(plot_case)(i) + 0.01, length(result_table.(plot_case)) - i + 1, sprintf('%.2f', result_table.(plot_case)(i)), 'VerticalAlignment', 'middle', 'Color', 'k');
        end
        text(1.01, length(result_table.(plot_case)) - i + 1, sprintf('PCs: %d', result_table.PCs(i)), 'VerticalAlignment', 'middle', 'Color', 'k');

    end

    % Adjust figure size
    set(gcf, 'Position', [100, 100, 1200, 800]);
    set(gcf, 'Color', 'w');
end
end 