%% Function: Model building
% Author: Anel Zhunussova
% Last update date: 26th March 2025
% Details:
%     - Preparing data for model training 
% Process: Bin data -> split (or split -> bin) -> normalize ->  reshape for the model
classdef MINT_prepare_data
    methods (Static)
        % Part 1: Bin & Split
        
        % ------ Bin data
        %  Actual Pain Ratings
        function binned_behavioral = bin_behavioral_data(config_structure, option, window_size_TR)
            behavioral_data.caps = config_structure.behavioral_data.(option).caps;
            behavioral_data.rest = config_structure.behavioral_data.(option).rest;

            binned_behavioral = struct();

            input_name_behavioral = {'behavioral'};
            main_input_behavioral = {'input_name', input_name_behavioral};
            additional_caps = {'cut_duration'};

            binned_behavioral.caps = MINT_prepare_data.support_func_binning(behavioral_data.caps, window_size_TR, main_input_behavioral{:}, additional_caps{:});
            binned_behavioral.rest = MINT_prepare_data.support_func_binning(behavioral_data.rest, window_size_TR, main_input_behavioral{:});
            % For replication sessions
            fields = fieldnames(config_structure.behavioral_data.(option));
            if any(contains(fields, 'quinine'))
               behavioral_data.quinine = config_structure.behavioral_data.(option).quinine;
               binned_behavioral.quinine = MINT_prepare_data.support_func_binning(behavioral_data.quinine, window_size_TR, main_input_behavioral{:}, additional_caps{:}); %same cut as in caps
            end 
        end

        % Bin connectivity (activation is already binned after HRF GLM)
        function binned_brain = bin_connectivity(connectivity, window_size_TR)

            if isstruct(connectivity) % just for flexibility of input
                binned_brain = struct();
            else
                print_header('Connectivity was not given in structure form, default order will be assigned:', ...
                    '1st row: caps | 2nd: rest | 3rd: quinine'); 
                connectivity_struct.caps =  connectivity(1,:);
                connectivity_struct.rest = connectivity(2,:);
                if size(connectivity, 1) == 3 % replication sessions
                    connectivity_struct.quinine = connectivity(3,:);
                end
                connectivity = connectivity_struct;
            end

            input_name_connectivity = {'connectivity'};
            main_input_connectivity = {'input_name', input_name_connectivity};
            additional_caps = {'cut_duration'};
            binned_brain.connectivity_caps = MINT_prepare_data.support_func_binning(connectivity.caps, window_size_TR, main_input_connectivity{:}, additional_caps{:});
            binned_brain.connectivity_rest = MINT_prepare_data.support_func_binning(connectivity.rest, window_size_TR, main_input_connectivity{:});
            
            % For replication sessions
            fields = fieldnames(connectivity);
            if any(contains(fields, 'quinine'))
               binned_brain.connectivity_quinine = MINT_prepare_data.support_func_binning(connectivity.quinine, window_size_TR, main_input_connectivity{:}, additional_caps{:});
            end 
        end 

        % ------ Split data into training, testing, validation
        function split_data = divide_data_by_split(config_structure, binned_brain, binned_behavioral) % binned_brain CAN have unbinned connectivity
            % Get participant splits
            participants_to_analyze = config_structure.participants_to_analyze.main; %main can be changed later 
    
            % List of behavioral fields to extract (dynamic)
            fields = fieldnames(binned_behavioral); % caps, run, quinine
            fields_brain = fieldnames(binned_brain); % connectivity, activation

            sets= {'train', 'valid', 'test'};
            split_data = struct();

            % Loop through sets 
            for s = 1:length(sets)

                set_name = sets{s};
                indices.(set_name) = ismember(participants_to_analyze, config_structure.model_split.main.([set_name '_id']));

                % Loop through runs (e.g., caps, rest, quinine) for
                % behavioral data
                for f = 1:numel(fields)
                    field_name = fields{f};

                    % Behavioral data
                    this_data = binned_behavioral.(field_name);
                    split_data.(set_name).(['behavioral_', field_name]) = this_data(indices.(set_name), :);
                end

                % Loop through brain measures
                for f_br = 1:numel(fields_brain)
                    field_name_brain = fields_brain{f_br};
                    this_data_br = binned_brain.(field_name_brain);
                    split_data.(set_name).(field_name_brain) = this_data_br(:,indices.(set_name));
                end
            end
        end 

        % ------ Normalizing the data  (2 options, without split for replication set or after
        % split for original dataset that uses training set STD)
        % Without split
        function [vn_dat, std_rep] = variance_normalization_independent_set(rep_dat, varargin)
            include_behavioral = false;
            if ~isempty(varargin)
                print_header('Assuming behavioral data was input as the 2nd variable');
                behavioral_binned = varargin{1};
                include_behavioral = true;
            end 
            % Done separately for capsaicin and resting; 
            % Done separately for connectivity and activation.
            % Done across time
            brain_inputs = fieldnames(rep_dat);
            runs = fieldnames(rep_dat.(brain_inputs{1}));
            for br = 1:length(brain_inputs)
                br_name = brain_inputs{br};
                for r = 1:length(runs)
                    r_name = runs{r};
                    std_rep.([br_name '_' r_name]) = std(cat(2, rep_dat.(br_name).(r_name){:}), 0, 2);
                    vn_dat.independent_set.([br_name '_' r_name]) = cellfun(@(x) x./std_rep.([br_name '_' r_name]), rep_dat.(br_name).(r_name), 'un', false);
                    if include_behavioral
                        vn_dat.independent_set.(['behavioral_', r_name]) = behavioral_binned.(r_name);
                    end 
                end
            end
            % vn_dat.comment = 'Variance normalization is applied across time separately for capsaicin and resting and separately for activation and connectivity. Behavioral data was not normalized.';
        end

        % After split
        function [vn_split_data, std_all] = variance_normalize_after_split(split_data, normType)
            print_header('Applying variance normalization');
            % Done separately for capsaicin and resting; 
            % Done separately for connectivity and activation.

            fields = fieldnames(split_data.train);
            fields = fields(~contains(fields, 'behavioral'));

            sets = {'train', 'test', 'valid'};
            vn_split_data = struct();
            for f = 1:length(fields)
                field_name = fields{f};

                % Getting training set std
                train_data = split_data.train.(field_name); 
                if normType == "voxelwise"
                    data_std = std(cat(2, train_data{:}), 0, 2); % voxel x 1 or edges x 1
                    std_all.(field_name) = data_std;
                elseif normType == "wholebrain"
                    all_data = data_stdcat(2, train_data{:}); % Concatenate all timepoints
                    data_std = std(all_data(:)); % Calculate single std across all voxels and timepoints
                    std_all.(field_name) = data_std;
                end

                % Applying training set std on train, valid, testing
                for s = 1:length(sets)
                    set_name = sets{s};
                    data = split_data.(set_name).(field_name);
                    vn_split_data.(set_name).(field_name) = cellfun(@(x) x ./ data_std, data, 'UniformOutput', false);

                    % Adding behavioral data 
                    vn_split_data.(set_name).behavioral_caps = split_data.(set_name).behavioral_caps;
                    vn_split_data.(set_name).behavioral_rest = split_data.(set_name).behavioral_rest;
                end 
            end 
            vn_split_data.comment = 'Variance normalization is applied across time separately for capsaicin and resting and separately for activation and connectivity. Behavioral data was not normalized.';

        end 

        % ------ Combine connectivity and activation
        function vn_split_data_final = combine_connectivity_and_activation(vn_data, activation_name)
            sets = fieldnames(vn_data);
            sets = sets(~contains(sets, 'comment'));

            vn_split_data_final = vn_data;
            for s = 1:length(sets)
                set_name = sets{s};
                temp_data = vn_data.(set_name);
                if ~isempty(temp_data) % case of replication sessions just inputing test field
                    for sess = 1:length(temp_data.connectivity_caps)
                        if any(contains(fieldnames(temp_data), 'caps'))
                            vn_split_data_final.(set_name).(['connectivity_and_' activation_name '_caps']){sess} = [temp_data.connectivity_caps{sess}; temp_data.([activation_name '_caps']){sess}];
                        end
                        if any(contains(fieldnames(temp_data), 'rest'))
                            vn_split_data_final.(set_name).(['connectivity_and_' activation_name '_rest']){sess} = [temp_data.connectivity_rest{sess}; temp_data.([activation_name '_rest']){sess}];
                        end
                        if any(contains(fieldnames(temp_data),'quinine'))
                            vn_split_data_final.(set_name).(['connectivity_and_' activation_name '_quinine']){sess} = [temp_data.connectivity_quinine{sess}; temp_data.([activation_name '_quinine']){sess}];
                        end
                    end
                end
            end
        end
        
        % ------ Reshape for model input
        function [n_case, model_input_data] = reshape_for_model_input(vn_split_data_final, brain_measure, set_name, model_input_condition)
            % Extracting data
            case_run = model_input_condition;
            if contains(model_input_condition, '_rest')
                case_run = extractBefore(model_input_condition, '_rest');
                binned_brain.rest = vn_split_data_final.(set_name).([brain_measure '_rest']);
                binned_behavioral.rest = vn_split_data_final.(set_name).behavioral_rest;
                n_case.n_bins_rest =  size(binned_behavioral.rest, 2);
            end 
            
            binned_brain.(case_run) = vn_split_data_final.(set_name).([brain_measure '_' case_run]);
            binned_behavioral.(case_run) = vn_split_data_final.(set_name).(['behavioral_' case_run]);
            n_case.(['n_bins_' case_run]) = size(binned_behavioral.(case_run), 2);
            n_case.n_subj = size(binned_behavioral.(case_run), 1);
            n_case.case_run = case_run;
            switch set_name 
                case 'train'
                    % Reshaping data

                    model_input_data.dat_brain = cat(2, binned_brain.(case_run){:});
                    model_input_data.dat_behavioral = reshape(binned_behavioral.(case_run)', [], 1); % caps

                    if contains(model_input_condition, '_rest') % caps_rest
                        model_input_data.dat_brain = cat(2, binned_brain.(case_run){:}, binned_brain.rest{:});
                        model_input_data.dat_behavioral = [reshape(binned_behavioral.(case_run)', [], 1); reshape(binned_behavioral.rest', [], 1)];
                    end

                    % Check
                    if size( model_input_data.dat_brain, 2) ~= size(model_input_data.dat_behavioral, 1)
                        error('Mismatch in the size of dat behavioral and brain');
                    end
                case {'valid', 'test', 'independent_set'}
                    % Chosing needed binned data 
                    model_input_data.binned = binned_brain;
                    model_input_data.binned.behavioral = binned_behavioral;
            end
        end



        % ------ Main function: preparing input data fo the cv-pcr
        function [binned, n_case, dat_brain, dat_behavioral] = get_model_input_data(config_structure_raw, data_to_process)
            % Step 1: Extract Parameters
            [window_size_TR, config_structure] = MINT_prepare_data.extract_parameters(config_structure_raw);

            % Step 2: Load data from config
            [brain_data, behavioral_data] = MINT_prepare_data.load_data(config_structure, data_to_process);
           
            % Step 3: Bin Data
            binned_behavioral =  MINT_prepare_data.bin_behavioral_data(behavioral_data, window_size_TR);
            binned_brain = MINT_prepare_data.bin_brain_data(config_structure, brain_data, window_size_TR);
            binned.behavioral = binned_behavioral;
            binned.caps = binned_brain.caps; binned.rest = binned_brain.rest;
            % Step 4: Reshape
            [n_case, dat_brain, dat_behavioral] = MINT_prepare_data.reshape_data(binned_behavioral, binned_brain);

        end
        
        


 

       
      


        %% ---- Supporting function : Binning
        function binned_data = support_func_binning(data_cell, window_size, varargin)
            %% Function: Binning with DCC and Behavioral Data
            % Last update: 21st October 2024
            % Details:
            %     - Convolution of DCC (connectivity) is the default.
            %         * Binning starts 5 seconds after the data for.
            %     - Binning starts from the beginning for behavioral data.
            %     - If 'cut_duration' is enabled, handle first bin differently:
            %         * For connectivity, first bin lasts until 34.6 seconds, followed by a 5-second delay.
            %         * For behavioral, first bin lasts until 34.6 seconds, followed by normal binning.

            %% Content
            % 1. Input check and defining duration paratemers
            % 2a.Bin connectivity data (w/ and w/out cut duration)
            % 2b.Bin behavioral data
            % 3. Supporting function for binning process.

            %% 1.1 Input data
            cut_duration = false;
            input_name = [];
            % Check for varargin options
            for i = 1:length(varargin)
                if ischar(varargin{i})
                    switch varargin{i}
                        case 'cut_duration'
                            cut_duration = true;
                        case 'input_name'
                            input_name_cell = varargin{i+1};
                            input_name = input_name_cell{1};
                    end
                end
            end


            % Parameters
            TR = 0.46;  % Repetition time
            delay_sec = 5;  % Delay in seconds for DCC binning
            first_bin_duration_sec = 34.6;  % Duration for the first bin if 'cut_duration' is enabled
            first_bin_TRs = round(first_bin_duration_sec / TR)- 1; %-1 because 34.6sec was removed inclusively in preprocessing
            delay_TRs = round(delay_sec / TR);
            num_participants = size(data_cell, 2);

            % Logic:
            % If cut duration, the input size of connectivity caps should be 1422 TR and after convolution it should be 1411TR.
            % If cut duration, behavioral output data should be 1422TR.

            % Preallocate cell for the binned data
            binned_data = cell(1, num_participants);

            %% 2.1a Binning
            % Connectivity
            if strcmp(input_name , 'connectivity')
                for participant_i = 1:num_participants
                    participant_data = data_cell{1, participant_i};

                    if cut_duration
                        % Defining data
                        first_bin_data = participant_data(:, 1:first_bin_TRs); % First bin up to 34.6 seconds
                        remaining_data = participant_data(:, (first_bin_TRs + delay_TRs + 1):end); % Rest of the data after a 5-second delay

                        % Binning
                        binned_participant_data= inside_func_bin_remaining_data(remaining_data, window_size);

                        % Final result combined with the 1st bin
                        binned_data{1, participant_i} = [mean(first_bin_data, 2, 'omitnan'), binned_participant_data];

                    else
                        % Defining data
                        remaining_data = participant_data(:, (delay_TRs + 1):end); % Start binning after the 5-second delay

                        % Binning & final result
                        binned_data{1, participant_i}= inside_func_bin_remaining_data(remaining_data, window_size);
                    end
                end

            %% 2.1b Binning
            % Behavioral
            elseif strcmp(input_name, 'behavioral')
                if cut_duration

                    % Defining data
                    removed_TR = round(74.6/0.46); % 88TR removed
                    first_bin_data = data_cell(:, 1:first_bin_TRs); % First bin up to 34.6 seconds
                    remaining_data = data_cell(:, (removed_TR + 1):end); % Rest of the data after 74.6 sec

                    % Binning
                    binned_participant_data= inside_func_bin_remaining_data(remaining_data, window_size);

                    % Final result combined with the 1st bin
                    binned_data = [mean(first_bin_data, 2, 'omitnan'), binned_participant_data];
                else

                    % Defining data
                    remaining_data = data_cell;

                    % Binning & the final result
                    binned_data= inside_func_bin_remaining_data(remaining_data, window_size);

                end
            end


            % Binning process
            function binned_participant_data= inside_func_bin_remaining_data(remaining_data, window_size)
                % Calculate the number of bins
                num_bins = floor(size(remaining_data, 2) / window_size);
                remaining_data_trimmed = remaining_data(:, 1:num_bins * window_size);  % Trim extra TRs
                binned_participant_data = zeros(size(remaining_data, 1), num_bins);

                % Mean within bin
                for bin_i = 1:num_bins
                    bin_range = (bin_i - 1) * window_size + 1 : bin_i * window_size;
                    binned_participant_data(:, bin_i) = mean(remaining_data_trimmed(:, bin_range), 2, 'omitnan'); % mean among specified columns
                end
            end

        end

    end
end


