%% Complexity Index (CI) from RR Intervals


%% Step 1: Load peakFrames from the .mat file
% Open file selection dialog to browse for the .mat file
[filename, filepath] = uigetfile({'*.mat', 'MAT-files (*.mat)'}, 'Select EKG Peaks File');
if filename == 0
    error('No file selected. Please select a valid .mat file.');
end

% Load the selected .mat file
data = load(fullfile(filepath, filename));

% Extract the peakFrames field
if isfield(data, 'ekgPeaks') && isfield(data.ekgPeaks, 'peakFrames')
    peakFrames = data.ekgPeaks.peakFrames; % Adjust field names if necessary
else
    error('peakFrames field not found in the selected .mat file. Please verify the structure.');
end


% Step 2: Define sampling rate (adjust as per your dataset)
samplingRate = 500; 

% Step 3: Compute RR intervals
% Convert frame indices to time (in seconds)
timeStamps = peakFrames / samplingRate;

RR_intervals = diff(peakFrames) / samplingRate; % RR intervals in seconds
disp(['Min RR: ', num2str(min(RR_intervals)), ', Max RR: ', num2str(max(RR_intervals))]);

% Comment out the filtering temporarily to see if it works without removing outliers
% RR_intervals = RR_intervals(RR_intervals > 0.3 & RR_intervals < 2.0);


disp(RR_intervals);
disp(['Number of intervals: ', num2str(length(RR_intervals))]);

% Step 4: Define parameters for entropy calculation
m = 2; % Embedding dimension
r = 0.2 * std(RR_intervals); % Tolerance (20% of the standard deviation)
max_scale = 20; % Number of scales for Multiscale Entropy (MSE)

% Step 5: Compute Sample Entropy (SampEn)
sampen_value = sampen(RR_intervals, m, r);

% Step 6: Compute Multiscale Entropy (MSE)
mse_values = multiscale_entropy(RR_intervals, m, r, max_scale);
CI = sum(mse_values); % Complexity Index as the sum of MSE values

% Step 7: Visualize and display results
figure;

% Plot RR intervals
subplot(2, 1, 1);
plot(RR_intervals);
xlabel('Interval Index');
ylabel('RR Interval (s)');
title('RR Intervals');

% Plot Multiscale Entropy (MSE)
subplot(2, 1, 2);
plot(1:max_scale, mse_values, '-o');
xlabel('Scale');
ylabel('Entropy');
title('Multiscale Entropy');

% Display results in the command window
disp(['Sample Entropy (SampEn): ', num2str(sampen_value)]);
disp(['Complexity Index (CI): ', num2str(CI)]);

%% Supporting Functions

% SampEn Function
function SE = sampen(data, m, r)
    N = length(data);
    % Construct embedding vectors
    X = zeros(N - m + 1, m);
    for i = 1:m
        X(:, i) = data(i:N - m + i);
    end
    % Count matches within tolerance r
    count = zeros(1, 2);
    for k = 0:1
        for i = 1:size(X, 1) - k
            for j = i + 1:size(X, 1) - k
                if max(abs(X(i, :) - X(j, :))) < r
                    count(k + 1) = count(k + 1) + 1;
                end
            end
        end
    end
    % Compute SampEn
    SE = -log(count(2) / count(1));
end

% Multiscale Entropy Function
function MSE = multiscale_entropy(data, m, r, max_scale)
    MSE = zeros(1, max_scale);
    for scale = 1:max_scale
        % Coarse-grain the data
        cg_data = arrayfun(@(i) mean(data(i:i + scale - 1)), 1:scale:length(data) - scale + 1);
        % Compute Sample Entropy on coarse-grained data
        MSE(scale) = sampen(cg_data, m, r);
    end
end


