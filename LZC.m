% Add paths for EEGLAB and calc_lz_complexity function
%addpath('your/path/to/eeglab2024.2.1'); % Replace with EEGLAB path
%addpath('your/path/to//calc_lz_complexity'); % Replace with the function's path

% Start EEGLAB
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

% Extract EEG data
data = EEG.data; % EEG data (channels x samples x trials)
fs = EEG.srate;  % Sampling rate

% Remove non-EEG channels
valid_channels = ~ismember({EEG.chanlocs.labels}, {'x_dir', 'y_dir', 'z_dir'});
EEG.data = EEG.data(valid_channels, :, :);
EEG.chanlocs = EEG.chanlocs(valid_channels);
EEG.nbchan = sum(valid_channels);

% Update data after removing non-EEG channels
data = EEG.data; % EEG data (updated channels x samples x trials)

% Initialize parameters
[num_channels, num_samples, num_epochs] = size(EEG.data); % Check if data is epoched
epoch_length = 10 * EEG.srate; % 10 seconds per epoch
num_epochs = floor(num_samples / epoch_length);

% Initialize array for LZC values
lzc_values = zeros(num_channels, num_epochs);

% Parallel processing setup
if isempty(gcp('nocreate'))
    parpool; % Create a parallel pool
end

% Process data in segments (epochs)
parfor epoch = 1:num_epochs
    for ch = 1:num_channels
        % Extract segment (epoch) data
        signal = EEG.data(ch, (epoch-1)*epoch_length + 1 : epoch*epoch_length); 
        % Binarize signal (using thresholding method, can adjust as needed)
        binary_signal = signal > mean(signal); % Example binarization
        % Compute LZC for the segment
        lzc_values(ch, epoch) = calc_lz_complexity(binary_signal, 'exhaustive', 1); 
    end
end

% Save results
save('lzc_values.mat', 'lzc_values');
disp('LZC computation completed and saved.');

% Optional: Plot SampEn values with channel names
figure;
imagesc(lzc_values);
xlabel('Epochs');
ylabel('Channels');
title('Lempel-Ziv Complexity Across Epochs and Channels');
colorbar;

% Extract channel names from EEG data
channel_names = {EEG.chanlocs.labels}; % Get channel labels

% Add channel names as y-axis labels
yticks(1:length(channel_names)); % Set y-ticks
yticklabels(channel_names);      % Set y-tick labels to channel names

% Adjust for better visualization
xticks(1:size(lzc_values, 2)); % Set x-ticks for each epoch
grid off;
