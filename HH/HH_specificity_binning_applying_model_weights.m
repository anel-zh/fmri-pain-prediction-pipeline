function [pain_score, binned] = HH_specificity_binning_applying_model_weights(model_data, behavioral_test, connectivity_test, activation_test, brain_measure, run, varargin)
% Duration
window_size = 90;
input_name_behavioral = {'behavioral'};
main_input_behavioral = {'input_name', input_name_behavioral};

input_name_connectivity = {'connectivity'};
main_input_connectivity = {'input_name', input_name_connectivity};
additional = {'cut_duration'};

% ========= Behavioral Data
binned.behavioral_caps = mint_b2_bin_data(behavioral_test.caps, window_size, main_input_behavioral{:}, additional{:});
if isfield(behavioral_test, 'quinine')
    binned.behavioral_quinine = mint_b2_bin_data(behavioral_test.quinine, window_size, main_input_behavioral{:}, additional{:});
end
binned.behavioral_rest = mint_b2_bin_data(behavioral_test.rest, window_size, main_input_behavioral{:}); % no cut regardless

if ~isempty(varargin) && any(strcmp(varargin{:}, 'combined_model_hyperalignment'))
    binned_input = varargin{1}{2};
    binned.caps = binned_input.caps;
    binned.rest = binned_input.rest;
    binned.quinine = binned_input.quinine;
     wei_name = 'CA_wei';
else 
% Connectivity and/or activation
switch brain_measure
    case {'connectivity_and_hrf_voxel', 'connectivity_and_hrf_roi', 'connectivity_and_boxcar_roi'}
        % ========= Brain Data
        binned.connectivity_caps = mint_b2_bin_data(connectivity_test.caps, window_size, main_input_connectivity{:}, additional{:});
        if isfield(connectivity_test, 'quinine')
            binned.connectivity_quinine = mint_b2_bin_data(connectivity_test.quinine, window_size, main_input_connectivity{:}, additional{:});
        end
        binned.connectivity_rest = mint_b2_bin_data(connectivity_test.rest, window_size, main_input_connectivity{:});

        binned.activation_caps = activation_test.caps;
        binned.activation_rest = activation_test.rest;
        if isfield(activation_test, 'quinine')
            binned.activation_quinine = activation_test.quinine;
        end

        % Combining by participant/session
        for i = 1:length(binned.connectivity_caps)
            binned.caps{i} = [binned.connectivity_caps{i}; binned.activation_caps{i}];
            binned.rest{i} = [binned.connectivity_rest{i}; binned.activation_rest{i}];
            if isfield(binned, 'connectivity_quinine') && isfield(binned, 'activation_quinine')
                binned.quinine{i} = [binned.connectivity_quinine{i}; binned.activation_quinine{i}];
            end
        end
        wei_name = 'CA_wei';

    case 'connectivity'
        binned.caps = mint_b2_bin_data(connectivity_test.caps, window_size, main_input_connectivity{:}, additional{:});
        if isfield(connectivity_test, 'quinine')
            binned.quinine = mint_b2_bin_data(connectivity_test.quinine, window_size, main_input_connectivity{:}, additional{:});
        end
        binned.rest = mint_b2_bin_data(connectivity_test.rest, window_size, main_input_connectivity{:});
        wei_name = 'C_wei';

    case {'hrf_voxel', 'hrf_roi', 'boxcar_roi'}
        binned.caps = activation_test.caps;
        binned.rest = activation_test.rest;
        if isfield(activation_test, 'quinine')
            binned.quinine = activation_test.quinine;
        end
        wei_name = 'A_wei';
end
end 
%2.3 Apply model weights
if ~isempty(varargin) && strcmp(varargin, 'only_combined_model_wei')
    print_header('Only using combined model weights');
    brain_measure = 'connectivity_and_hrf_voxel';
end
% %
%     if ~isempty(varargin) && strcmp(varargin, 'masked_weights') % virtual lesion or isolation
%         print_header('Using masked weights');
%         if contains(brain_measure, 'and')
%             wei_name = 'A_wei'; % combined model, only using Activation.
%         end
%     end

if strcmp(run, 'quinine_rest')
    model_weights = model_data.(brain_measure).caps_rest.(wei_name);
    intercept = model_data.(brain_measure).caps_rest.intercept;
elseif strcmp(run, 'quinine')
    model_weights = model_data.(brain_measure).caps.(wei_name);
    intercept = model_data.(brain_measure).caps.intercept;
else
    model_weights = model_data.(brain_measure).(run).(wei_name);
    intercept = model_data.(brain_measure).(run).intercept;
end


n_subj = size(binned.caps, 2);
for i = 1:n_subj
    pain_score.caps{i} = sum(binned.caps{1, i} .* model_weights, 'omitnan')' + intercept;
    pain_score.rest{i} = sum(binned.rest{1, i} .* model_weights, 'omitnan')' + intercept;
    if isfield(binned, 'quinine')
        pain_score.quinine{i} = sum(binned.quinine{1, i} .* model_weights, 'omitnan')' + intercept;
    end
end

if ~isempty(varargin) && strcmp(varargin, 'cosine') % virtual lesion or isolation
clear pain_score
    n_subj = size(binned.caps, 2);
    for i = 1:n_subj
        % Caps condition
        for bin_idx = 1:size(binned.caps{1, i}, 2)
            feature_vector = binned.caps{1, i}(:, bin_idx);
            similarity = (feature_vector' * model_weights) / ... % open dot commentary
                (norm(feature_vector) * norm(model_weights)); 
            if isnan(similarity)  % Handle cases where norm is 0
                similarity = 0;
            end
            pain_score.caps{i}(bin_idx) = similarity; 
        end

        % Rest condition
        for bin_idx = 1:size(binned.rest{1, i}, 2)
            feature_vector = binned.rest{1, i}(:, bin_idx);
            similarity = (feature_vector' * model_weights) / ... % open dot
                (norm(feature_vector) * norm(model_weights)); 
            if isnan(similarity)  % Handle cases where norm is 0
                similarity = 0;
            end
            pain_score.rest{i}(bin_idx) = similarity;
        end

        % Quinine condition 
        if isfield(binned, 'quinine')
            for bin_idx = 1:size(binned.quinine{1, i}, 2)
                feature_vector = binned.quinine{1, i}(:, bin_idx);
                 similarity = (feature_vector' * model_weights) / ... % open dot
                (norm(feature_vector) * norm(model_weights)); 
%                 similarity = dot(feature_vector, model_weights, 'omitnan') / ...
%                     (norm(feature_vector, 'omitnan') * norm(model_weights, 'omitnan'));
                if isnan(similarity)  % Handle cases where norm is 0
                    similarity = 0;
                end
                pain_score.quinine{i}(bin_idx) = similarity;
            end
        end
    end
end
end
