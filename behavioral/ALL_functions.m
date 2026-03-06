% MPC Class Functions
% 
% 
% This MATLAB file contains a class definition for MPC (Midnight Pain Club) Behavioral data analysis. (https://github.com/leedh/MPC100)
% The class includes static methods for loading continuous ratings data, interpolating data, plotting assessments, calculating time checks for the assesment of the experimental
% consistenty, generating plots, calculating mean ratings per period, and plotting using wani_plot_shading.
% The purpose of the class functions lies in the creation of more neat and optimized workflow with two datasets. 
% 
% Usage:
%   1. Load continuous ratings data:
%      [data_rating, errors, D] = mpc.loadContinuousRatings(folderdir, filename_pattern, prev_errors)
%   2. Interpolate data to TR:
%      [data_rating_adjusted, ratings_tr] = mpc.interpolate(data_rating, TR, exceptions)
%   3. Plot assessments (visualization of all or one plots):
%      mpc.plotAssessment(ParticipantName, folderdir, ratings_tr, varargin)
%   4. Calculate time checks for time interval consistency within experiments:
%      [data_time, time_check] = mpc.calculateTimeCheck(folderdir, data_rating)
%   5. Generate plots (e.g., boxplots, heatmaps, all at once):
%      mpc.generate_plots(time_check, column_names, main_title, ylabel_name, plot_types)
%   6. Calculate mean ratings per each experimental sub-period:
%      folder_name_and_ratings = mpc.calculateMeanRatings(data_rating, data_time, folderdir)
%   7. Get mean, standard deviation, and standard error:
%      [meanVal, stdVal, steVal] = mpc.getMeanStdSte(data)
%   8. Plot with WANI plot shading:
%      mpc.plotWaniShading(titleStr, meanVal, std_or_ste_val, pain_scale, col_n, addGreyArea)
% 
% For detailed information about each function, refer to the comments within the function definitions.
% 
% Author: Anel Zhunussova
% Last update: 9th May 2024
% Version: 1st (Preliminary) - may not work on different datasets.
% Contact: anelzhunussova08@gmail.com or anelyazh@g.skku.edu
%
% Dependencies:
%   - MATLAB R2022b or later
%   - CocoanCore (Visualization) (https://github.com/cocoanlab/cocoanCORE) 
%   - CanlabCore (Filename_tools) (https://github.com/canlab/CanlabCore)
%
% Notes:
%   - This class is designed for analyzing multi-participant capsaicin
%   conitnious ratings.
%   - For usage examples and additional information, refer to the comments within each function definition.
%
% 
% Script with sample analysis on MPC-datasets: 
%   - Behavioral_MPC.mlx (consists workflow remakrs)



classdef ALL_behavioral_mint % mpc_caps previously
    methods (Static = true)
        % LOADING 
        function [data_rating, errors, D] = loadContinuousRatings(folderdir, filename_pattern, prev_errors)
            data_rating = {};
            if nargin < 3
                errors = {};
            else
                errors = prev_errors;
            end

            for i = 1:numel(folderdir)
                try
                    filedir = filenames(fullfile(folderdir{i}, filename_pattern));
                    D = load(filedir{:});
                    data_rating{i} = D.data.dat.continuous_rating;
                catch
                    errors(end+1,:) = {i, 'Error occurred during loading', fullfile(folderdir{i}, filename_pattern)};
                end
            end
        end

        % INTERPOLATION
        function [data_rating_adjusted, ratings_tr] = interpolate(data_rating, TR, exceptions)
            if nargin < 3
                exceptions = false;
            end
            data_rating_adjusted = cell(size(data_rating));
            ratings_tr = cell(size(data_rating));

            for i = 1:numel(data_rating)
                try
                    time_difference = data_rating{i}(:, 1) - data_rating{i}(1, 1);
                    data_rating_adjusted{i} = [time_difference, data_rating{i}(:, 2)];
                    num_TRs = ceil(max(time_difference) / TR);
                    ratings_tr{i} = zeros(num_TRs, 1);

                    for t = 1:num_TRs
                        time_start = TR * (t - 1);
                        time_end = TR * t;
                        idx = find(time_difference >= time_start & time_difference < time_end);
                        ratings_tr{i}(t) = mean(data_rating{i}(idx, 2));
                    end
                    data_rating_adjusted{i}(:, 2) = interp1((0:num_TRs-1)*TR, ratings_tr{i}, time_difference, 'linear');

                    if exceptions && i < 5
                        ratings_tr{i}(1:round(30/TR)) = [];
                        ratings_tr{i}(end-round(120/TR):end) = [];
                    end
                catch
                end
            end
        end

        % PLOTTING ALL or ONE
        function plotAssessment(ParticipantName, folderdir, ratings_tr, varargin)
            includeParticipantStats = false;
            includePopulationStats = false;
            setYLim = false;
            qcFilePath = '';

            if ~isempty(varargin)
                includeParticipantStats = varargin{1};
                if numel(varargin) > 1
                    includePopulationStats = varargin{2};
                    if numel(varargin) > 2
                        setYLim = varargin{3};
                        if numel(varargin) > 3
                            qcFilePath = varargin{4};
                        end
                    end
                end
            end

            num_participants = numel(ratings_tr);
            all_ratings = vertcat(ratings_tr{:});

            if strcmpi(ParticipantName, 'all')
                num_rows = ceil(sqrt(num_participants));
                num_cols = ceil(num_participants / num_rows);

                figure('Position', [100, 100, 1200, 800]);
                sgtitle('Continuous Capsaicin Ratings for Each Participant');

                for i = 1:num_participants
                    subplot(num_rows, num_cols, i);
                    mpc.plotParticipantData(ratings_tr{i}, folderdir{i}, includeParticipantStats, includePopulationStats, all_ratings, setYLim, qcFilePath);
                end

            else
                participantIndex = find(contains(folderdir, ParticipantName));
                if isempty(participantIndex)
                    disp('Participant not found.');
                    return;
                end
                figure;
                mpc.plotParticipantData(ratings_tr{participantIndex}, ParticipantName, includeParticipantStats, includePopulationStats, all_ratings, setYLim, qcFilePath);
            end
        end

        function plotParticipantData(ratings, participantName, includeParticipantStats, includePopulationStats, all_ratings, setYLim, qcFilePath)
            plot(ratings, 'LineWidth', 1);
            set(gcf,'color','w');
            [~, folder_name, ~] = fileparts(participantName);
            legendEntries = {'Ratings'};
            if isempty(ratings)
                title(folder_name, 'color', 'r')
            else
                title(folder_name)
            end
            xlabel('Time (TR)');
            ylabel('Ratings');
            grid on;

            if includeParticipantStats
                ratings_mean = mean(ratings);
                ratings_std = std(ratings);
                hold on;
                plot(1:numel(ratings), ones(size(ratings))*ratings_mean, 'c', 'LineWidth', 1);
                plot(1:numel(ratings), ones(size(ratings))*(ratings_mean + ratings_std), 'c--', 'LineWidth', 1);
                plot(1:numel(ratings), ones(size(ratings))*(ratings_mean - ratings_std), 'c--', 'LineWidth', 1);
                legendEntries = [legendEntries, 'Par:Mean', 'Par:Mean + Std', 'Par:Mean - Std'];
                disp(['Participant ', folder_name, ' Mean: ', num2str(ratings_mean)]);
                disp(['Participant ', folder_name, ' Std: ', num2str(ratings_std)]);
            end

            if includePopulationStats
                population_mean = mean(all_ratings);
                population_std = std(all_ratings);
                hold on;
                plot(1:numel(ratings), ones(size(ratings))*population_mean, 'r', 'LineWidth', 1);
                plot(1:numel(ratings), ones(size(ratings))*(population_mean + population_std), 'r--', 'LineWidth', 1);
                plot(1:numel(ratings), ones(size(ratings))*(population_mean - population_std), 'r--', 'LineWidth', 1);
                legendEntries = [legendEntries, 'Pop:Mean', 'Pop:Mean + Std', 'Pop:Mean - Std'];
                disp(['Population Mean: ', num2str(population_mean)]);
                disp(['Population Std: ', num2str(population_std)]);
            end

            if nargin == 7 && ~isempty(qcFilePath)
                qc = readtable(qcFilePath, 'VariableNamingRule', 'preserve');
                outlier_rows = ~strcmp(qc.caps, '-');
                outlier_participants = qc.proj_num(outlier_rows);
                outlier_comments = qc.caps(outlier_rows);

                if ismember(folder_name, outlier_participants)
                    idx = find(ismember(outlier_participants, folder_name));
                    comment = outlier_comments{idx};
                    text(0.5, 0.95, ['Outlier Comment: ', comment], ...
                        'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 8, 'Color', 'red');
                end
            end

            if setYLim
                ylim([min(all_ratings(:)), max(all_ratings(:))]);
            end

            if includeParticipantStats || includePopulationStats
                legend(legendEntries);
            end
        end

        % TIME-CHECKING 
        function [data_time, time_check] = calculateTimeCheck(folderdir, data_rating)
            time_check = zeros(numel(folderdir), 6);
            data_time = cell(size(folderdir));

            for i = 1:numel(folderdir)
                try
                    [~, ~, D] = mpc.loadContinuousRatings({folderdir{i}}, '*_010_*');
                    data = D.data.dat;

                    data_time{i} = {data.continuous_rating_start, ...
                        data.caps_stim_deliver_start, data.caps_stim_deliver_end, ...
                        data.caps_stim_remove_start, data.caps_stim_remove_end, ...
                        data.continuous_rating_end};
                    for j = 1:5
                        time_check(i,1) = data_rating{i}(1,1) - data_time{i}{1};
                        time_check(i,1+j) = data_time{i}{1+j} - data_time{i}{j};
                    end
                catch
                end
            end
        end

        % GENERATING VISUAL ASSESSMENT PLOTS
        function generate_plots(time_check, column_names, main_title, ylabel_name, plot_types)
            if ismember('heatmap', plot_types)
                figure;
                set(gcf,'color','w');
                sgtitle(main_title);
                heatmap(time_check, 'XLabel', 'Time Difference', 'YLabel', ylabel_name, ...
                    'XDisplayLabels', column_names);
            end

            if ismember('histogram', plot_types)
                figure;
                set(gcf,'color','w');
                sgtitle(main_title);
                for i = 1:size(time_check, 2)
                    try
                        subplot(2, 3, i);
                        histogram(time_check(:,i), 'FaceColor','cyan', 'NumBins', 20);
                        title(column_names{i});
                        xlabel('Time Difference');
                        ylabel('Frequency');
                        colormap("turbo");
                    catch
                    end
                end
            end


            if ismember('boxplot', plot_types)
                boxplot_wani_2016(time_check, 'color', jet(size(time_check, 2)), 'fontsize', 10);
                set(gcf,'color','w');
                set(gca, 'XTickLabel', column_names, 'XTickLabelRotation', 45); % Set custom x-axis labels
                ylabel('Time Difference');
                title(main_title);
            end


            if ismember('violin', plot_types)
                figure;
                set(gcf,'color','w');
                sgtitle(main_title);
                for i = 1:size(time_check, 2)
                    try
                        subplot(2, 3, i);
                        violinplot(time_check(:, i));
                        xlabel(column_names{i});
                        ylabel('Time Difference');
                    catch
                    end
                end
            end
        end

        % CALCULATING MEAN RATINGS PER PERIOD
        function folder_name_and_ratings = calculateMeanRatings(data_rating, data_time, folderdir)
            mean_ratings_subperiod = cell(size(data_rating));
            for i = 1:numel(data_rating)
                try
                    time_info = data_time{i};

                    for j = 1:size(time_info, 2)-1
                        start_idx = find(data_rating{i}(:,1) >= time_info{j});
                        end_idx = find(data_rating{i}(:,1) <= time_info{j+1});
                        subperiod_idx = intersect(start_idx, end_idx);

                        mean_ratings_subperiod{i}(j) = mean(data_rating{i}(subperiod_idx, 2));
                    end
                catch
                end
            end

            max_subperiods = numel(mean_ratings_subperiod{1});
            num_participants = numel(mean_ratings_subperiod);
            mean_ratings_double = zeros(num_participants, max_subperiods);
            folder_name_and_ratings = cell(num_participants, max_subperiods);

            for i = 1:num_participants
                if ~isempty(mean_ratings_subperiod{i})
                    [~, folder_name, ~] = fileparts(folderdir{i});
                    folder_name_and_ratings{i,1} = folder_name;
                    folder_name_and_ratings(i, 2:numel(mean_ratings_subperiod{i})+1) = num2cell(mean_ratings_subperiod{i});
                end
            end
        end

        % GETTING MEAN, STD, STE
        function [meanVal, stdVal, steVal] = getMeanStdSte(data)
            meanVal = mean(data, 'omitnan');
            stdVal = std(data);
            steVal = stdVal / sqrt(length(stdVal));
        end

  
        function plotWaniShading(titleStr, meanVals, std_or_ste_vals, pain_scale, col_ns, legend_labels, addGreyArea, inSeconds, addAllArea)
            load(which('colormap_ggplot2.mat'));
            figure('Position', [744 492 774 557]);
            set(gcf,'color','w');
            sgtitle(titleStr);
            TR = 0.46;
            if inSeconds
                xaxis = (1:size(meanVals{1}, 2))*TR;
                xlabel('Time (sec)', 'FontSize', 14);
                upper_limit = 70;
                lower_limit = 30;
                xlines = [lower_limit upper_limit];
                xticks([0 30 50 70 690]);
                xlines_all = [30, 50, 70];
            else 
                xaxis = 1:size(meanVals{1}, 2);
                xlabel('Time (TR)', 'FontSize', 14);
                upper_limit = round(70/TR);
                lower_limit = round(30/TR);
                xlines = [lower_limit upper_limit];
                xlines_all = [round(30/TR), round(50/TR), round(52/TR), round(70/TR)];
            end 
            ylabel('Pain intensity', 'FontSize', 14);


            hold on; 

            for i = 1:length(meanVals)
                wani_plot_shading(xaxis, meanVals{i}, std_or_ste_vals{i}, 'color', col10_ggplot2(col_ns(i),:), 'alpha', 0.5);
            end

            yline(pain_scale, ':');
            ylim([0, 0.7]);
            yticks(0:0.1:0.7);

            text(xaxis(end), pain_scale(1) + 0.005, 'Week');
            text(xaxis(end), pain_scale(2) + 0.005, 'Moderate');
            text(xaxis(end), pain_scale(3) + 0.005, 'Strong');
            text(xaxis(end), pain_scale(4) + 0.005, 'Very Strong');
            

            if addGreyArea
                for i = 1:length(xlines)
                    xline(xlines(i), 'color', [0.5, 0.5, 0.5], 'linestyle', '--');
                end

                patch([xlines(1), xlines(1), xlines(2), xlines(2)], [0, 0.7, 0.7, 0], [0.617 0.617 0.617], 'EdgeColor', 'none', 'FaceAlpha', 0.2);
                text(((upper_limit+lower_limit)/2), 0.1, 'Not included ratings: Co-founded by movement of experimental set-up', 'Color', 'k', 'Rotation', 90, 'FontWeight', 'bold');
            end


            if addAllArea
                ylim = get(gca, 'ylim');
                patch([xlines_all(1), xlines_all(1), xlines_all(2), xlines_all(2)], [0, 0.7, 0.7, 0], [0.8 0.8 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.2);
                patch([xlines_all(3), xlines_all(3), xlines_all(4), xlines_all(4)], [0, 0.7, 0.7, 0], [0.6 0.6 0.6], 'EdgeColor', 'none', 'FaceAlpha', 0.2);
                text(40, ylim/2, 'Stimulus delivery', 'Color', 'k', 'Rotation', 90, 'FontWeight', 'bold');
                text(61, ylim/2, 'Stimulus removal', 'Color', 'k', 'Rotation', 90, 'FontWeight', 'bold');
                %text(((xlines_all(4)+xlines_all(3))/2), 0.1, 'Continuous ratings', 'Color', 'k', 'Rotation', 90, 'FontWeight', 'bold');
            end


            legend(legend_labels, 'Location', 'best'); % Add legend for each data set

        end


        % BINNING DATA
        function binned_data = binning(all_ratings, n_bin)
            binned_data = zeros(size(all_ratings, 1), n_bin);
            for div_i = 1:n_bin
                div_range = ceil(size(all_ratings, 2) / n_bin * (div_i - 1) + 1) : ceil(size(all_ratings, 2) / n_bin * div_i);
                binned_data(:, div_i) = mean(all_ratings(:, div_range), 2);
            end
        end

        % BINNING DATA
        function tr_binned_data = binning_tr(all_ratings, window_size_TR)
            % Calculate the number of bins based on the window size
            num_bins = floor(size(all_ratings, 2) / window_size_TR);

            % Discard extra TRs
            all_ratings_trimmed = all_ratings(:, 1:num_bins * window_size_TR);

            % Perform binning based on the window size
            tr_binned_data = zeros(size(all_ratings, 1), num_bins);
            for bin_i = 1:num_bins
                bin_range = (bin_i - 1) * window_size_TR + 1 : bin_i * window_size_TR;
                tr_binned_data(:, bin_i) = mean(all_ratings_trimmed(:, bin_range), 2);
            end
        end


        function plotBinnedRatings(mean_ratings, col_ns, n_bin, time_bins, pain_scale, legend_labels, addGreyArea)
            load(which('colormap_ggplot2.mat'));
            figure('Position', [744 492 774 557]);
            sgtitle(sprintf('Capsaicin Mean Ratings: %d bins (%d sec)', n_bin, time_bins), 'FontSize', 16);
            xaxis = 1:size(mean_ratings{1}, 2);

            hold on;

            for i = 1:length(mean_ratings)
                plot(mean_ratings{i}, 'color', col10_ggplot2(col_ns(i),:), 'Marker', 'o', 'LineWidth', 1);
            end

            yline(pain_scale, ':');
            xlim([-1, (n_bin + 0.5)]);
            ylim([0, 0.7]);
            yticks(0:0.1:0.7);
            ylabel('Pain intensity', 'FontSize', 14);
            xlabel('Time points', 'FontSize', 14);
            set(gcf,'color','w');

            if addGreyArea
                upper_limit = 70/time_bins;
                lower_limit = 30/time_bins;
                xlines = [(lower_limit/n_bin) upper_limit];
                xlines = [lower_limit upper_limit];
                for i = 1:length(xlines)
                    xline(xlines(i), 'color', [0.5, 0.5, 0.5], 'linestyle', '--');
                end

                patch([xlines(1), xlines(1), xlines(2), xlines(2)], [0, 0.7, 0.7, 0], [0.617 0.617 0.617], 'EdgeColor', 'none', 'FaceAlpha', 0.2);
                text(((upper_limit+lower_limit)/2), 0.075, 'Not included ratings: Co-founded by movement of experimental set-up', 'Color', 'k', 'Rotation', 90, 'FontWeight', 'bold');
            end


            text(xaxis(end), pain_scale(1) + 0.005, 'Week');
            text(xaxis(end), pain_scale(2) + 0.005, 'Moderate');
            text(xaxis(end), pain_scale(3) + 0.005, 'Strong');
            text(xaxis(end), pain_scale(4) + 0.005, 'Very Strong');

            legend(legend_labels, 'Location', 'best');
            box off;
        end

    end
end
