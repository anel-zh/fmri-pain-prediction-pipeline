function data = HH_variance_simple(var_table, varargin)
%%%%%%%%%
% Validation option should be included to optimize
%%%%%%%%%
% Getting table
data = nan(5,2);
model_input_condition = {'caps', 'caps_rest'};
for input = 1:length(model_input_condition)
    in = model_input_condition{input};
    R2.(in).C_temp = var_table.(in)(contains(var_table.(in).Predictors, 'connectivity') & ~ contains(var_table.(in).Predictors, 'connectivity_and'), :);
    R2.(in).A_temp = var_table.(in)(contains(var_table.(in).Predictors, 'hrf_voxel') & ~ contains(var_table.(in).Predictors, 'connectivity_and'), :);
    R2.(in).CA_temp = var_table.(in)(contains(var_table.(in).Predictors, 'connectivity_and_hrf_voxel'), :);
    
    R2.(in).C =  R2.(in).C_temp.R2;
    R2.(in).A =  R2.(in).A_temp.R2;
    R2.(in).CA =  R2.(in).CA_temp.R2;

%  ----- Previous approach ( I think wrong (Anel)) -> May 29
%     R2.(in).C_unique = R2.(in).CA - R2.(in).A;
%     R2.(in).A_unique = R2.(in).CA - R2.(in).C;
%     R2.(in).shared = R2.(in).CA - (R2.(in).C_unique + R2.(in).A_unique);
%     R2.(in).unexplained = 1 - R2.(in).CA;
%     R2.(in).total_explained = R2.(in).CA;
% ---- Updated approach (29 May)
    R2.(in).shared = (R2.(in).C_unique + R2.(in).A_unique) - R2.(in).CA;
    R2.(in).C_unique = R2.(in).A - R2.(in).shared;
    R2.(in).A_unique = R2.(in).C - R2.(in).shared;
    R2.(in).unexplained = 1 - R2.(in).CA;
    R2.(in).total_explained = R2.(in).CA;


    data(:, input) = [R2.(in).shared;
            R2.(in).C_unique; 
            R2.(in).A_unique;
            R2.(in).unexplained;
            R2.(in).total_explained];
end 


%% Visualizing
plot_names = {'Shared', 'C Unique', 'A Unique', 'Unexplained'};
if ~isempty(varargin)
    colors = varargin{1};
else
        colors = [ 1.0    0.9    0.6 % soft peach
            0.6    0.8    1.0 % pastel blue
            0.8   0.7    1.0 % pastel purple
            1.0    0.7    0.7]; % light coral
end

close all;
data_to_plot = data(1:(end-1), :);

xLabels =  strrep(model_input_condition, '_', '\_');


figure;
b = bar(data_to_plot', 'stacked', 'EdgeColor', 'none', 'BarWidth', 0.6);
for k = 1:length(b)
    b(k).FaceColor = colors(k, :);
end

xticks(1:4);
xticklabels(xLabels);
xlabel('Condition', 'FontSize', 12);
ylabel('Total Explained Variance (%)', 'FontSize', 12);
title([strrep('Connectivity and HRF voxel: testing set', '_', '\_')], 'FontSize', 14);

legend(plot_names, 'Location', 'eastoutside', 'FontSize', 10);
%legend({'C Unique', 'A Unique', 'Shared', 'Unexplained'}, 'Location', 'eastoutside', 'FontSize', 10);

ylim([min(data, [],'all')-0.1 1]);
yticklabels(0:10:100);

%data labels
hold on;
for model_i = 1:size(data_to_plot, 1)
    for case_j = 1:size(data_to_plot, 2)
        if model_i == 1
            y = sum(data_to_plot(1:model_i, case_j));
        elseif data_to_plot(model_i, case_j) < 0
            if model_i == 1
                y = data_to_plot(model_i, case_j);
            else 
                y = sum(data_to_plot((data_to_plot(1:model_i,case_j) <0), case_j));
            end 
        else
            y = sum(data_to_plot(1:model_i, case_j) .* (data_to_plot(1:model_i, case_j) > 0));
        end
        text(case_j, y - data_to_plot(model_i,case_j)/2, sprintf('%.1f%', data_to_plot(model_i,case_j)*100), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', 9, 'FontWeight', 'bold');
    end
end


% Add total explained variance label at the top of each bar
for case_j = 1:size(data_to_plot, 2)
    total_variance = sum(data_to_plot(1:3, case_j));
    total_variance_position = sum(data_to_plot(1:3, case_j) .* (data_to_plot(1:3, case_j) > 0));  % Total variance for each column
    text(case_j, total_variance_position + 0.02, sprintf('Total: %.1f%', total_variance*100), ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 8, 'FontWeight', 'bold', 'Color', 'r');
end

grid on;
box off;
set(gca, 'FontSize', 12, 'LineWidth', 1.5);
set(gcf, 'color', 'w', 'Position', [ 675 54 1060 908]);
hold off;
