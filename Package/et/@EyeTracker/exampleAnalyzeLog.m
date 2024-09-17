function exampleAnalyzeLog(logFile)
	%% Handle input arguments
	if nargin<1 || isempty(logFile)
		error('No log file specified');
	end

	if (strcmp(logFile(end-3:end),'.txt'))
		matFile = [logFile(1:end-4) '.mat'];
	else
		matFile = [logFile '.mat'];
		logFile = [logFile '.txt'];
	end
	
	%% Import data 
	%if ~exist(matFile) || 1 %% convert the raw log file to a .mat if it hasn't already been done
		tic
		d = EyeTracker.convertLogToMat(logFile,matFile); %% this is (unfortunately) slow
		toc
% 	else
% 		d = load(matFile); % this is much faster, so ideal to store most data in this format
% 	end

	%% 
	% d.map contains labels for features and their corresponding column numbers
	% to index into d.data
	availableFeatures = d.map.keys

	% Features are accessed by referencing their label through the map
	bpogx_columnIndex = d.map('BPOGX')
	bpogx = d.data(:,bpogx_columnIndex);

	% The first six numbers in each row are a log time stamp (added by matlab 
	% when it received the message, not the same as the eyetracker's own
	% internal timestamps). These can be converted to seconds, relative to a
	% given reference time (eg the beginnning of recording):
	refTime = d.data(1,1:6);
	for i=1:size(d.data,1)
		t(i) = etime(d.data(i,1:6), refTime);
	end


	%%
	bpogx = d.data(:,d.map('BPOGX'));
	bpogy = d.data(:,d.map('BPOGY'));

	figure;
	subplot(3,1,1);
	plot(t, d.data(:,d.map('BPOGX')));
	ylim([-0.1 1.1])
	title('Best POG X');
	subplot(3,1,2);
	plot(t,d.data(:,d.map('BPOGY')))
	ylim([-0.1 1.1]);
	title('Best POG Y');
	subplot(3,1,3);
	plot(t,d.data(:,d.map('BPOGV')))
	title('POG Valid');

	figure;
	dist = sqrt((bpogx - 0.5).^2 + (bpogy - 0.5).^2);
	plot(t,dist);
	title('Best POG distance from center');
	ylim([-0.1, 1.5]);

	figure;
	subplot(3,1,1);
	plot(t,d.data(:,d.map('LPUPILD')));
	title('Left Pupil Diameter');
	subplot(3,1,2);
	plot(t,d.data(:,d.map('RPUPILD')))
	title('Right Pupil Diameter');
	subplot(3,1,3);
	plot(t,[d.data(:,d.map('LPUPILV')) d.data(:,d.map('RPUPILV'))])
	title('Pupil D Valid');




end