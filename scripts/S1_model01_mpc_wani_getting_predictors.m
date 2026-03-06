%% Script Remarks
% Author: Anel Zhunussova (anelzhunussova08@gmail.com) 
% Last update: 16th Aprl 2024 -> 11thJun 2025 revised before project
% transfer
% Goal: 
%     - Dataset: MPC-Wani 
%     - Atlas: Schaefer_265 
%     - Extracting brain features for original and replication data

%% Content
% ====== Part 1 
% 1. Loading directories and configuration structure.
% 2. Dividing participants to different nodes.
% 3. Denoising and getting activation (HRF voxel) and connectivity (DCC) measures.
% 4. Moving previous rest run data to new folder.

% ====== Part 2 (specificity)
% Same as Part 1, but has an option for quinine and different nas
% directory.

% ====== Part 3
% Additional QC for comparison of specificity and original sessions

% ===== Part 4 
% Redoing specificity 

% ====== Part 5
% Trial using global mean as regressor in specificity 
clc
clear
%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset); 
% Now you can manually set up new directory (11th June Update)
% In case you change the main function to your dir and if I need to rerun
% base = '/home/anel/nas1/';
% HH_set_dir_mint(model, dataset, base); 

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
% can be also set (11th June Update)
% base = '/home/anel/nas1/';
% config_structure_all = HH_load_config_mint(dataset,'save',false, 'base', base);
% Can also be used like this:
% config_structure_all = HH_load_config_mint(dataset,'save',false, 'base', base, 'load_final_model'); % default dir of model wei
% config_structure_all = HH_load_config_mint(dataset,'save',false, 'base', base, 'load_final_model', model_wei_dir); set model wei dir

config_structure = config_structure_all.model01_mpc_wani;    

% Directories 
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;

%% 1.2 Participants allocation
config_structure.participants_to_analyze.first_batch = config_structure.participants_to_analyze.main(1:13);
config_structure.participants_to_analyze.second_batch = config_structure.participants_to_analyze.main(14:end);

config_structure.participants_to_analyze.temp = {'sub-mpc006'};
folder_name_suffix = 'test';
%% 1.3 Preprocessing
%% node02
participants_option = 'temp';

mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix);

%% node04
participants_option = 'second_batch';
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix);

%% 1.4 Moving DCC
dir_old = fullfile(basedir, '/results/mean_sig_Schaefer_265_combined_2mm/');
dir_new =  fullfile(basedir, '/results/mean_sig_Schaefer_265_combined_2mm_final/');
participants = config_structure.participants_to_analyze.main;
HH_move_dcc_boxcar_to_final(dir_old, dir_new, participants)



%% ===== Part 2
% Specificity 
clc
clear
%%  2.1 Directory details
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset);

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    

addpath(genpath('/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/functions')); 

basedir = '/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/model01_Schaefer_MPC_Wani';
nasdir = '/home/anel/nas1/data/MPC/MPC_wani/imaging/preprocessed/';
%% 2.2 Analysis details
% Changing variables
config_structure.basedir = basedir; % set basedir
config_structure.nasdir = nasdir;  

% Specificity
config_structure.participants_to_analyze.specificity34 = {'sub-mpc034'};
config_structure.participants_to_analyze.specificity36 = {'sub-mpc036'};
config_structure.participants_to_analyze.specificity37 = {'sub-mpc037'};
config_structure.participants_to_analyze.specificity38 = {'sub-mpc038'};

folder_name_suffix = 'specificity';

%% 2.3 Getting predictors
%% node02
participants_option = 'specificity34';

additional_inputs = {'caps_run_num', 11, 'quinine_run_num',10, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

% node07
% sub-mpc36
participants_option = 'specificity36';

additional_inputs = {'caps_run_num', 10, 'quinine_run_num',11, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_roi'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

% node09
% sub-mpc37
participants_option = 'specificity37';

additional_inputs = {'caps_run_num', 10, 'quinine_run_num',12, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_roi'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});
% node
% sub-mpc38
participants_option = 'specificity38';

additional_inputs = {'caps_run_num', 12, 'quinine_run_num',10, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_roi'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});



%% Additional QC 
%% ===== Part 3
% Specificity & Original runs without denoising activation
clc
clear
%%  2.1 Directory details
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset);

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    

addpath(genpath('/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/functions')); 

basedir = '/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/model01_Schaefer_MPC_Wani';
nasdir = '/home/anel/nas1/data/MPC/MPC_wani/imaging/preprocessed/';

% Changing variables
config_structure.basedir = basedir; % set basedir
config_structure.nasdir = nasdir;  

% Specificity
config_structure.participants_to_analyze.specificity34 = {'sub-mpc034'};
config_structure.participants_to_analyze.specificity36 = {'sub-mpc036'};
config_structure.participants_to_analyze.specificity37 = {'sub-mpc037'};
config_structure.participants_to_analyze.specificity38 = {'sub-mpc038'};

folder_name_suffix = 'specificity';

%% 2.3 Getting predictors
%% Replication
participants_option = 'specificity34';

additional_inputs = {'caps_run_num', 11, 'quinine_run_num',10, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'no_denoising_activation'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

%% Original sessions
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset);

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    

% Directories 
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;

config_structure.participants_to_analyze.temp = {'sub-mpc006'};
folder_name_suffix = 'final';
participants_option = 'temp';

mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'no_denoising_activation'}, ...
    'folder_name_suffix', folder_name_suffix);
%% Infor on Replication set
% ==== % for sub-mpc34
% caps_run_num = 11;
% quinine_run_num = 10; 

% ==== % for sub-mpc36 
% caps_run_num = 10;
% quinine_run_num = 11; 

% ==== % for sub-mpc37
% caps_run_num = 10;
% quinine_run_num = 12; 

% ==== % for sub-mpc38
% caps_run_num = 12;
% quinine_run_num = 10; 

%% ===== Part 4
% Specificity sessions after modifications 

%% New T1 option
%%  4.1 Directory details
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset);

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    

addpath(genpath('/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/functions')); 

basedir = '/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/model01_Schaefer_MPC_Wani';
nasdir = '/home/anel/nas1/projects/MINT/data/MPC_wani_specificity_different_T1/imaging/preprocessed';

% Changing variables
config_structure.basedir = basedir; % set basedir
config_structure.nasdir = nasdir;  

% Specificity
config_structure.participants_to_analyze.specificity34 = {'sub-mpc034'};


% 4.2 Getting predictors
% Normal approach
folder_name_suffix = 'specificity_new_T1';
participants_option = 'specificity34';
config_structure.denoising_method = 'mean_sig_';

additional_inputs = {'caps_run_num', 11, 'quinine_run_num',10, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'boxcar_roi_and_dcc', 'hrf_voxel'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

% Before ICA nuisance
folder_name_suffix = 'specificity_new_T1_nuisance_after_ICA';
participants_option = 'specificity34';
config_structure.denoising_method = 'after_ica_mean_sig_';

additional_inputs = {'caps_run_num', 11, 'quinine_run_num',10, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'boxcar_roi_and_dcc', 'hrf_voxel'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

%% ==== Rescaled to 16 bit option
%%  4.1 Directory details
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset);

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    

addpath(genpath('/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/functions')); 

basedir = '/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/model01_Schaefer_MPC_Wani';
% Main change
nasdir = '/home/anel/nas1/projects/MINT/data/MPC_wani_specificity_rescaled_to_16bit/imaging/preprocessed';

% Changing variables
config_structure.basedir = basedir; % set basedir
config_structure.nasdir = nasdir;  

% Specificity
config_structure.participants_to_analyze.specificity34 = {'sub-mpc034'};


% 4.2 Getting predictors
% Normal approach
folder_name_suffix = 'specificity_rescaled_to16bit'; %main change
participants_option = 'specificity34';
config_structure.denoising_method = 'mean_sig_';

additional_inputs = {'caps_run_num', 11, 'quinine_run_num',10, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'boxcar_roi_and_dcc', 'hrf_voxel'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

%% === Redoing preprocessing for specificity
%%  4.1 Directory details
tic
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset);

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    

addpath(genpath('/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/functions')); 

basedir = '/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/model01_Schaefer_MPC_Wani';
% Main change
nasdir = '/home/anel/nas1/projects/MINT/data/MPC_wani_specificity_rerun/imaging/preprocessed';

% Changing variables
config_structure.basedir = basedir; % set basedir
config_structure.nasdir = nasdir;  

% Specificity
config_structure.participants_to_analyze.specificity34 = {'sub-mpc034'};
config_structure.participants_to_analyze.specificity36 = {'sub-mpc036'};
config_structure.participants_to_analyze.specificity37 = {'sub-mpc037'};
config_structure.participants_to_analyze.specificity38 = {'sub-mpc038'};

% 4.2 Getting predictors
% Normal approach
folder_name_suffix = 'specificity_rerun'; %main change
config_structure.denoising_method = 'mean_sig_';

% participants_option = 'specificity34';
% caps_run = 11;
% quinine_run = 10;
% 
% additional_inputs = {'caps_run_num', caps_run, 'quinine_run_num',quinine_run, ...
%     'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
% mint_a1_predictors_extraction(config_structure, participants_option, ...
%     'extract_values', {'boxcar_roi_and_dcc', 'hrf_voxel'}, ...
%     'folder_name_suffix', folder_name_suffix, additional_inputs{:});
% 
% participants_option = 'specificity36';
% caps_run = 10;
% quinine_run = 11;
% additional_inputs = {'caps_run_num', caps_run, 'quinine_run_num',quinine_run, ...
%     'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
% mint_a1_predictors_extraction(config_structure, participants_option, ...
%     'extract_values', {'boxcar_roi_and_dcc', 'hrf_voxel'}, ...
%     'folder_name_suffix', folder_name_suffix, additional_inputs{:});

participants_option = 'specificity37';
caps_run = 10;
quinine_run = 12;

additional_inputs = {'caps_run_num', caps_run, 'quinine_run_num',quinine_run, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'boxcar_roi_and_dcc', 'hrf_voxel'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

toc

%% === 17 sec onsets
nasdir = '/home/anel/nas1/data/MPC/MPC_wani/imaging/preprocessed/';

% Changing variables
config_structure.basedir = basedir; % set basedir
config_structure.nasdir = nasdir;  

folder_name_suffix = 'specificity_17sec_onset'; %main change
config_structure.denoising_method = 'mean_sig_';

participants_option = 'specificity34';
caps_run = 11;
quinine_run = 10;

additional_inputs = {'caps_run_num', caps_run, 'quinine_run_num',quinine_run, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

participants_option = 'specificity36';
caps_run = 10;
quinine_run = 11;
additional_inputs = {'caps_run_num', caps_run, 'quinine_run_num',quinine_run, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

participants_option = 'specificity37';
caps_run = 10;
quinine_run = 12;

additional_inputs = {'caps_run_num', caps_run, 'quinine_run_num',quinine_run, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});

participants_option = 'specificity38';
caps_run = 12;
quinine_run = 10;

additional_inputs = {'caps_run_num', caps_run, 'quinine_run_num',quinine_run, ...
    'run_to_analyze', {'caps', 'rest', 'quinine'}, 'specificity', true};
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel'}, ...
    'folder_name_suffix', folder_name_suffix, additional_inputs{:});




%% Part 4
% Running ROI level hrf to possibly get new model
%% 1.1 Details
% Case
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset);

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false);
config_structure = config_structure_all.model01_mpc_wani;    

% Directories 
config_structure.nasdir = nasdir;
config_structure.basedir = basedir;

%% 1.2 Participants allocation
config_structure.participants_to_analyze.first_batch = config_structure.participants_to_analyze.main(1:13);
config_structure.participants_to_analyze.second_batch = config_structure.participants_to_analyze.main(14:end);

config_structure.participants_to_analyze.temp = {'sub-mpc006'};
folder_name_suffix = 'test';

%% 1.3 Preprocessing
%% node02
participants_option = 'main';
folder_name_suffix = 'roi_hrf'; 
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_roi'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix);




%% ==== Part 5 
% Specificity (Global mean signal
clc
clear
%%  5.1 Directory details
dataset = 'mpc_wani';
model = 'model01_Schaefer';
HH_set_dir_mint(model, dataset);

% Config
config_structure_all = HH_load_config_mint(dataset,'save',false, 'load_final_model', false);
config_structure = config_structure_all.model01_mpc_wani;    

addpath(genpath('/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/functions')); 

basedir = '/home/anel/nas1/projects/MINT/analysis/imaging/connectivity/model01_Schaefer_MPC_Wani';
nasdir = '/home/anel/nas1/data/MPC/MPC_wani/imaging/preprocessed/';
%% 5.2 Analysis details
% Changing variables
config_structure.basedir = basedir; % set basedir
config_structure.nasdir = nasdir;  

% Specificity
config_structure.participants_to_analyze.specificity34 = {'sub-mpc034'};
config_structure.participants_to_analyze.specificity36 = {'sub-mpc036'};
config_structure.participants_to_analyze.specificity37 = {'sub-mpc037'};
config_structure.participants_to_analyze.specificity38 = {'sub-mpc038'};


%% 5.3 Getting predictors
%% Global mean for replication sesssions 
extract = {'hrf_voxel_global_mean'};
folder_name_suffix = 'specificity_global_mean';

participants_data = {
    'specificity34', 11, 10, extract;       % sub-mpc34
    'specificity36', 10, 11, extract;       % sub-mpc36
    'specificity37', 10, 12, extract;       % sub-mpc37 
    'specificity38', 12, 10, extract        % sub-mpc38
};

for i = 1:size(participants_data, 1)
    participants_option = participants_data{i, 1};
    caps_run_num = participants_data{i, 2};
    quinine_run_num = participants_data{i, 3};
    extract_values = participants_data{i, 4};

    additional_inputs = {
        'caps_run_num', caps_run_num, ...
        'quinine_run_num', quinine_run_num, ...
        'run_to_analyze', {'caps', 'rest', 'quinine'}, ...
        'specificity', true
    };

    mint_a1_predictors_extraction(config_structure, participants_option, ...
        'extract_values', extract_values, ...
        'cut_duration_activation', true, ...
        'folder_name_suffix', folder_name_suffix, ...
        additional_inputs{:});
end

% Rescale 25 times data after ICA-Aroma 
% Global mean for replication sesssions 
extract = {'hrf_voxel_rescale_25'};
folder_name_suffix = 'specificity_rescale25';

participants_data = {
    'specificity34', 11, 10, extract;       % sub-mpc34
    'specificity36', 10, 11, extract;       % sub-mpc36
    'specificity37', 10, 12, extract;       % sub-mpc37 
    'specificity38', 12, 10, extract        % sub-mpc38
};

for i = 1:size(participants_data, 1)
    participants_option = participants_data{i, 1};
    caps_run_num = participants_data{i, 2};
    quinine_run_num = participants_data{i, 3};
    extract_values = participants_data{i, 4};

    additional_inputs = {
        'caps_run_num', caps_run_num, ...
        'quinine_run_num', quinine_run_num, ...
        'run_to_analyze', {'caps', 'rest', 'quinine'}, ...
        'specificity', true
    };

    mint_a1_predictors_extraction(config_structure, participants_option, ...
        'extract_values', extract_values, ...
        'cut_duration_activation', true, ...
        'folder_name_suffix', folder_name_suffix, ...
        additional_inputs{:});
end




%% - temporary extraction of global mean 
participants_option = 'main';
folder_name_suffix = 'main_global_mean';
mint_a1_predictors_extraction(config_structure, participants_option, ...
    'extract_values', {'hrf_voxel_global_mean'}, ...
    'cut_duration_activation', true, ...
    'folder_name_suffix', folder_name_suffix);