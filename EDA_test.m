% ==============================
% Extract and Analyze GSR Data from BrainVision (vhdr) using EEGLAB
% ==============================

clear; close all; clc;

% Initialize EEGLAB
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

% -----------------------------
% 1. Load BrainVision Data
% -----------------------------

% Open file selection dialog to browse for dataset
[filename, filepath] = uigetfile({'*.vhdr', 'EEGLAB (*.vhdr)'}, 'Select EEG Dataset');
if filename == 0
    error('No file selected. Please select an EEG dataset.');
end

% Load EEG dataset
EEG = pop_loadbv(filepath, filename);
disp('EEG dataset loaded.');

% Store the dataset in EEGLAB
[ALLEEG, EEG, CURRENTSET] = eeg_store(ALLEEG, EEG, 0);

% Display available channels
disp('Available Channels:');
disp({EEG.chanlocs.labels});

% -----------------------------
% 2. Extract GSR Channel
% -----------------------------
% Find the GSR channel (modify channel name if needed)
gsr_channel = find(strcmp({EEG.chanlocs.labels}, 'EDA'));

if isempty(gsr_channel)
    error('GSR channel not found! Check channel names.');
end

% Extract GSR signal
gsr_data = EEG.data(gsr_channel, :);
fs = EEG.srate;  % Sampling rate
time_vector = linspace(0, EEG.xmax, EEG.pnts); % Time in seconds

% Plot raw GSR signal
figure;
plot(time_vector, gsr_data);
xlabel('Time (s)');
ylabel('GSR (µS or arbitrary units)');
title('Raw GSR Signal');
grid on;

% -----------------------------
% 3. Preprocess GSR Signal
% -----------------------------
% 3.1 Low-pass filter (cutoff 1 Hz)
fc = 1; % Cutoff frequency (Hz)
[b, a] = butter(2, fc / (fs / 2), 'low'); % 2nd-order Butterworth filter
gsr_filtered = filtfilt(b, a, gsr_data);

% Plot filtered signal
figure;
plot(time_vector, gsr_filtered);
xlabel('Time (s)');
ylabel('GSR (µS)');
title('Filtered GSR Signal (Low-pass <1 Hz)');
grid on;

% 3.2 Downsample to 100 Hz if needed
fs_new = 100; % Target sampling rate
if fs > fs_new
    gsr_downsampled = resample(gsr_filtered, fs_new, fs);
    time_vector_down = linspace(0, EEG.xmax, length(gsr_downsampled));
else
    gsr_downsampled = gsr_filtered;
    time_vector_down = time_vector;
end

% -----------------------------
% 4. Extract Skin Conductance Response (SCR) Features
% -----------------------------
% 4.1 Compute Basic GSR Metrics
scl_mean = mean(gsr_filtered); % Mean Skin Conductance Level (SCL)
scl_std = std(gsr_filtered);   % Standard deviation of SCL
disp(['Mean SCL: ', num2str(scl_mean), ' µS']);
disp(['SCL Standard Deviation: ', num2str(scl_std), ' µS']);

% 4.2 Detect SCR Peaks
[peaks, locs] = findpeaks(gsr_filtered, 'MinPeakHeight', scl_mean + 0.05, 'MinPeakDistance', fs * 1); 
peak_times = time_vector(locs); % Convert indices to time

% Plot SCR peaks
figure;
plot(time_vector, gsr_filtered);
hold on;
plot(peak_times, peaks, 'ro'); % Mark peaks
xlabel('Time (s)');
ylabel('GSR (µS)');
title('Skin Conductance Responses (SCR Peaks)');
legend('GSR Signal', 'SCR Peaks');
grid on;
hold off;

% -----------------------------
% 5. Event-Related GSR Analysis
% -----------------------------
% Extract event markers
event_times = [EEG.event.latency] / EEG.srate; % Convert latencies to seconds
event_types = {EEG.event.type}; % Event types

disp('Event Times (s):');
disp(event_times);
disp('Event Types:');
disp(event_types);

% Define epoch window (-2s to +5s)
tmin = -2; % Time before event (s)
tmax = 5;  % Time after event (s)
epoch_length = (tmax - tmin) * fs; 

% Extract epochs around each event
epochs = [];
for i = 1:length(event_times)
    event_idx = round(event_times(i) * fs);
    
    % Compute start and end indices
    start_idx = event_idx + round(tmin * fs);
    end_idx = event_idx + round(tmax * fs);
    
    % Ensure indices are within valid range
    if start_idx < 1 || end_idx > length(gsr_filtered)
        warning(['Skipping event at ', num2str(event_times(i)), ...
                 's because it is out of bounds.']);
        continue;
    end
    
    % Store epoch
    epochs(:, i) = gsr_filtered(start_idx:end_idx);
end


% Compute average event-related GSR response
gsr_evoked = mean(epochs, 2);
time_epoch = linspace(tmin, tmax, size(epochs, 1));

% Plot average event-related GSR response
figure;
plot(time_epoch, gsr_evoked, 'k', 'LineWidth', 2);
xlabel('Time (s)');
ylabel('GSR (µS)');
title('Average Event-Related GSR Response');
grid on;

% -----------------------------
% 6. Export GSR Data
% -----------------------------
% Save MATLAB variables
save('gsr_data.mat', 'gsr_filtered', 'time_vector');

% Export as CSV file
T = table(time_vector', gsr_filtered', 'VariableNames', {'Time', 'GSR'});
writetable(T, 'gsr_data.csv');

disp('GSR data successfully extracted and saved!');
