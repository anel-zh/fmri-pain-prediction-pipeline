function [weights, name_to_save_figures] = HH_getting_weights_final_model(model_data, pred_name, run_name)
    weights = struct();
    
    % Filename for saving figures
    name_to_save_figures = [pred_name '_' run_name '.pdf'];
    
    % Extract weights and p-values for the specified condition from model_data
    if isfield(model_data.(pred_name).(run_name), 'C_wei')
        weights.C_wei = model_data.(pred_name).(run_name).C_wei;
        weights.C_wei_p = model_data.(pred_name).(run_name).C_wei_p;
    end
    
    if isfield(model_data.(pred_name).(run_name), 'A_wei')
        weights.A_wei = model_data.(pred_name).(run_name).A_wei;
        weights.A_wei_p = model_data.(pred_name).(run_name).A_wei_p;
    end
end
