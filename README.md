EMCS Study: SOP Data Analysis 

Requirement: 
•	Software: Matlab 
•	Add-ons:
o		Signal Processing Toolbox 
o		Simulink 
o		Statistic and Machine Learning Toolbox 
o		Parallel Computing 
o		Optimization Toolbox 
o		Image Processing Toolbox 
o		EntropyHub
•	Toolboxes: 
o		EEGLAB
o		EEGLAB Plugins: 
			Biosig 
			BrainBeats
			EEG-Beats
o		EEGLAB functions 
			SempEn (https://matlab.mathworks.com/open/fileexchange/v1?id=124326)
			Calc_lz_complexity (https://matlab.mathworks.com/open/fileexchange/v1?id=38211)
•	Codes: 
o		EDA
o		IC
o		HR
o		SampEn
o		LZC
o		STE

EDA 

1.	Open Matlab 
2.	Run EDA code 
3.	Select “YourData.vhdr”: data from BrainVision (vhdr)
4.	Save output 

IC and HR

1.	Open Matlab 	
2.	Run EEGLAB  	
3.	Import Data 	 
4.	Open EEG-Beat 	 
5.	Set output directories 
Name ekgChannelLabel: “ECG”
	 
6.	Run CI_ECG code	
7.	Select file “YourData_ekgPeaks.mat”	
8.	Save output and figures 	
9.	Run HR code 	
10.	Select file “YourData_ekgPeaks.mat”	
11.	Save output and figures	

Entropies

1.	Open Matlab 	
2.	Run EEGLAB  	
3.	Import Data 	 
4.	Open BrainBeats 	 
5.	Analysis to run: select “extract EEG & HRV features”
Heart type channel select “ECG”	
	Browse “ECG” channel 	 
6.	Set parameters 
•	Power line 50 Hz
•	Highpass filter: 1
•	Lowpass filter: 50
•	EEG Freq. Option: lowpass 50 Hz
•	Untick parallel computing and GPU	 
7.	Save Dataset (don’t overwrite in memory)  	
8.	Flag component as artifacts 	  
9.	Manually check for other artifacts: inspect/label components by map -> manually select artifacts -> remove component from data -> overwrite in memory	
10.	Save dataset as .set file 	
11.	Run SampEn code	
12.	Select .set file	
13.	Save output 	
14.	Run LZC code 	
15.	Select .set file	
16.	Save output	
17.	Run STE code	
18.	Select .set file	
19.	Save output	





