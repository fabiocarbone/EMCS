%% Load peakFrames from the .mat file
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

% Define sampling rate
samplingRate = 500;  

% Compute recording duration
totalDuration = (peakFrames(end) - peakFrames(1)) / samplingRate;
disp(['Total recording duration: ', num2str(totalDuration), ' seconds']);

% Convert frames to time (seconds)
timeStamps = peakFrames / samplingRate;

% Compute RR intervals
RR_intervals = diff(timeStamps); 

% Display first 10 RR intervals
disp('First 10 RR Intervals (seconds):');
disp(RR_intervals(1:10));

% Filter unrealistic RR intervals
RR_intervals = RR_intervals(RR_intervals > 0.3 & RR_intervals < 2.0);

% Check again after filtering
disp(['Filtered RR - Min: ', num2str(min(RR_intervals)), ', Max: ', num2str(max(RR_intervals))]);

% Compute HR
HR = 60 ./ RR_intervals; 

% Display HR range
disp(['Min HR: ', num2str(min(HR)), ', Max HR: ', num2str(max(HR))]);

% Compute time vector for plotting
time = timeStamps(1:length(HR)); 

% Plot HR over time
figure;
plot(time, HR, 'b', 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('Heart Rate (bpm)');
title('Heart Rate Over Time');
grid on;
