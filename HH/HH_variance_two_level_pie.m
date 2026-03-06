function HH_variance_two_level_pie(var_table)
    %%%%%%%%%%%%%%%
    % Creates a radial plot for variance decomposition
    %%%%%%%%%%%%%%%

    % Extract data
    data = nan(4, 2);
    model_input_condition = {'caps', 'caps_rest'};
    for input = 1:length(model_input_condition)
        in = model_input_condition{input};
        R2.(in).C_temp = var_table.(in)(contains(var_table.(in).Predictors, 'connectivity') & ~contains(var_table.(in).Predictors, 'connectivity_and'), :);
        R2.(in).A_temp = var_table.(in)(contains(var_table.(in).Predictors, 'hrf_voxel') & ~contains(var_table.(in).Predictors, 'connectivity_and'), :);
        R2.(in).CA_temp = var_table.(in)(contains(var_table.(in).Predictors, 'connectivity_and_hrf_voxel'), :);
        
        R2.(in).C = R2.(in).C_temp.R2;
        R2.(in).A = R2.(in).A_temp.R2;
        R2.(in).CA = R2.(in).CA_temp.R2;
        
        R2.(in).C_unique = R2.(in).CA - R2.(in).A;
        R2.(in).A_unique = R2.(in).CA - R2.(in).C;
        R2.(in).shared = R2.(in).CA - (R2.(in).C_unique + R2.(in).A_unique);
        R2.(in).unexplained = 1 - R2.(in).CA;
        
        data(:, input) = [R2.(in).shared;
                          R2.(in).C_unique;
                          R2.(in).A_unique;
                          R2.(in).unexplained];
    end

    % Labels and colors
    labels = {'Shared', 'C Unique', 'A Unique', 'Unexplained'};
    colors = [0.4 0.8 0.4;  % Shared - green
              0.3 0.6 1.0;  % C Unique - blue
              0.8 0.6 1.0;  % A Unique - purple
              1.0 0.6 0.6]; % Unexplained - red

    % Create radial axes
    theta = linspace(0, 2 * pi, 100); % Full circle
    num_conditions = size(data, 2);

    % Plot
    figure;
    hold on;
    set(gcf, 'Color', 'w');
    title('Variance Decomposition (Radial Plot)', 'FontSize', 16, 'FontWeight', 'bold');
    max_radius = 1.2 * max(data(:)); % Set max radius for scaling

    % Loop through each variance component
    for i = 1:size(data, 1)
        % Extract variance data for all conditions for the current component
        r = [data(i, :), data(i, 1)]; % Repeat first point to close the circle
        theta_points = linspace(0, 2 * pi, num_conditions + 1); % Angles for conditions
        
        % Plot radial data
        polarplot(theta_points, r, 'LineWidth', 2, 'Color', colors(i, :));
    end

    % Add legend and customize
    legend(labels, 'Location', 'southoutside', 'Orientation', 'horizontal', 'FontSize', 12, 'Box', 'off');
    hold off;
end
