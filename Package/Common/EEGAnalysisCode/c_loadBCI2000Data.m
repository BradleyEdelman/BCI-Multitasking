function EEG = c_loadBCI2000Data(datPath,bci2000Events)

if nargin < 2
	% BCI2000 useful events
	bci2000Events = {'SourceTime','TargetCode','ResultCode','Feedback','CursorPosX','CursorPosY','CursorPosZ','StimulusTime'};
	  % excluding events that are not valid in EEGLab: Running,
	  % NeuroscanEvent1, Recording, and PauseApplication
end

if ~exist('pop_loadBCI2000','file')
	c_EEG_openEEGLabIfNeeded();
end

if 0
	EEG = pop_loadBCI2000(datPath,bci2000Events);
else
	% wrap command in evalc to suppress text output
	[strOutput, EEG] = evalc('pop_loadBCI2000(datPath,bci2000Events)');
	% remove specific messages that seem to always be printed
	strOutput = strrep(strOutput,...
		'eeg_checkset note: upper time limit (xmax) adjusted so (xmax-xmin)*srate+1 = number of frames',...
		'');
	strOutput = strrep(strOutput,...
		'Event resorted by increasing latencies.',...
		'');
	strOutput = strrep(strOutput,...
		'eeg_checkset note: creating the original event table (EEG.urevent)',...
		'');
	% print anything that still remains
	strOutput = strtrim(strOutput);
	if ~isempty(strOutput)
		disp(strOutput);
	end
end