% Load and preprocess data
eeglab;

% Open file selection dialog to browse for dataset
[filename, filepath] = uigetfile({'*.set', 'EEGLAB (*.set)'}, 'Select EEG Dataset');
if filename == 0
    error('No file selected. Please select an EEG dataset.');
end

% Load EEG dataset
EEG = pop_loadset('filename', filename, 'filepath', filepath);
disp('EEG dataset loaded.');
% Extract dataset name (remove file extension)
[~, dataset_name, ~] = fileparts(EEG.filename);

% Remove non-EEG channels
valid_channels = ~ismember({EEG.chanlocs.labels}, {'x_dir', 'y_dir', 'z_dir'});
EEG.data = EEG.data(valid_channels, :, :);
EEG.chanlocs = EEG.chanlocs(valid_channels);
EEG.nbchan = sum(valid_channels);

% Update data after removing non-EEG channels
data = EEG.data; % EEG data (updated channels x samples x trials)

% Extract EEG data
data = EEG.data; % EEG data (channels x samples x trials)
fs = EEG.srate;  % Sampling rate

% Flatten trials into one time series per channel
data_flat = reshape(data, size(data, 1), []); % (channels x time)

% Normalize the EEG data
data_flat = (data_flat - mean(data_flat, 2)) ./ std(data_flat, 0, 2);

% Parameters for symbolic encoding and STE
num_bins = 3; % Number of symbols (bins)
m = 3;        % Embedding dimension
tau = 1;      % Time delay

% Symbolic encoding function
function symbols = permutation_encode(data, m, tau)
    % Symbolically encode data using patterns of length m with lag tau
    n = length(data);
    num_patterns = n - (m - 1) * tau;
    symbols = nan(1, num_patterns);
    for i = 1:num_patterns
        segment = data(i:tau:i + (m - 1) * tau);
        [~, order] = sort(segment); % Get ordinal pattern
        symbols(i) = sum((order - 1) .* (m .^ (0:(m - 1)))); % Convert to unique symbols
    end
end

% Number of EEG channels
num_channels = size(data, 1); 

% Initialize STE results matrix
STE_results = zeros(num_channels, num_channels); 

% Start parallel pool (adjust workers if needed)
if isempty(gcp('nocreate'))
    parpool('local'); % Start a parallel pool with default workers
end

% Compute STE in parallel
parfor i = 1:num_channels
    for j = 1:num_channels
        if i ~= j
            % Extract source and target data
            source = data_flat(i, :); % Source channel
            target = data_flat(j, :); % Target channel
            
            % Symbolic encoding
            symbols_source = permutation_encode(source, m, tau);
            symbols_target = permutation_encode(target, m, tau);
            
            % Compute joint probabilities
            joint_prob = histcounts2(symbols_source(1:end-1), symbols_target(2:end), ...
                num_bins, 'Normalization', 'probability');
            
            % Normalize joint probabilities
            joint_prob = joint_prob / sum(joint_prob(:), 'omitnan');
            
            % Compute conditional probabilities
            cond_prob = joint_prob ./ sum(joint_prob, 2, 'omitnan');
            cond_prob(cond_prob == 0) = eps; % Replace zeros with small constant
            
            % Compute marginal probabilities of the target
            marginal_prob_target = sum(joint_prob, 1); % Sum over rows
            
            % Handle zero marginal probabilities
            marginal_prob_target(marginal_prob_target == 0) = eps;
            
            % Compute the logarithmic term
            log_term = log2(cond_prob ./ marginal_prob_target);
            log_term(isnan(log_term) | isinf(log_term)) = 0; % Handle invalid logs
            
            % Compute Symbolic Transfer Entropy
            TE = sum(joint_prob .* log_term, 'all', 'omitnan');
            
            % Debugging outputs for a specific channel pair
            if i == 1 && j == 2 % Example: Debugging Fp1 -> Fp2
                disp('--- Debugging Fp1 -> Fp2 ---');
                disp('Joint Probabilities:');
                disp(joint_prob);
                
                disp('Conditional Probabilities:');
                disp(cond_prob);
                
                disp('Marginal Probabilities of Target:');
                disp(marginal_prob_target);
                
                disp('Logarithmic Term:');
                disp(log_term);
                
                disp(['Computed STE (Fp1 -> Fp2): ', num2str(TE)]);
            end
            
            % Store STE in results matrix
            STE_results(i, j) = TE;
        end
    end
end

% Display results
disp('Symbolic Transfer Entropy (STE) Matrix:');
disp(STE_results);

% Save STE results as a matrix file
output_filename = fullfile(EEG.filepath, [dataset_name, '_STE_matrix.mat']); % Save in the dataset's directory
save(output_filename, 'STE_results');
disp(['STE results saved as: ', output_filename]);

% Optionally, visualize STE matrix
figure;
imagesc(STE_results);
colorbar;
title('Symbolic Transfer Entropy (STE) Matrix');
xlabel('Source Channels');
ylabel('Target Channels');
xticks(1:num_channels);
yticks(1:num_channels);
xticklabels({EEG.chanlocs.labels});
yticklabels({EEG.chanlocs.labels});
xtickangle(45);
