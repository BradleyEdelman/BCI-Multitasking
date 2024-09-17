function exampleInitAndRun(logFile,doPlot,doPrintRaw,doNotCalibrate)
	% exampleInitAndRun Initalizes EyeTracker object and logs raw output
	

	%% Handle input arguments
	if nargin < 4
		doNotCalibrate = false;
	end
	if nargin < 3
		doPrintRaw = false;
	end
	if nargin < 2
		doPlot = false;
	end
	if nargin < 1 || isempty(logFile) % if no log file specified, we can't log. Just plot live data
		doLog = false;
		doPlot = true;
		logFile = '';
	else
		doLog = true;
	end
	
	%% Initalization
	et = EyeTracker('doRecord',doLog);
	
	%% Calibration
	if ~doNotCalibrate
		resp = input('Calibrate? (y/N?)','s')
		if strcmp(resp,'y')
			doLog = false;

			et.calibrate()

			doLog = true;
		end
	end

	%% Receiving data
	
	et.startSendingData(); % start streaming data

	disp('Collecting data...');

	function doStopCallback(h,e)
		doStop = true;
	end
	
	if doPlot
		h = figure;
		screenSize = get(0,'ScreenSize');
		maxX = screenSize(3); maxY = screenSize(4);

		% Stop reading data when: any key is pressed, the window is closed, or mouse
		% is clicked in the figure
		doStop = false;
		
		%set(h,'KeyPressFcn','doStop=true');
		%set(h,'DeleteFcn','doStop=true');
		%set(h,'WindowButtonDownfcn','doStop=true');
		set(h,'KeyPressFcn',@doStopCallback);
		set(h,'DeleteFcn',@doStopCallback);
		set(h,'WindowButtonDownfcn',@doStopCallback);
		
		while(~doStop)
			clf; 

			msg = et.latestMsg; % read last line of data sent from eye tracker
			if isempty(msg) 
				continue
			end

			[data, map] = EyeTracker.importLog(msg,false); % parse message
			x = data(1,map('BPOGX'));
			y = data(1,map('BPOGY'));
			v = data(1,map('BPOGV'));

			if v
				title('BPOG valid');
			else
				title('BPOG NOT valid!');
			end
			
			rectangle('Position',[x*maxX, (1-y)*maxY, 16, 16],...
				'Curvature',[1,1],...
				'FaceColor','r');
			rectangle('Position',[0 0 maxX maxY]); % draw screen bounding box

			axis equal;
			%axis([0 maxX 0 maxY]);
			axis([-maxX*0.5 maxX*1.5 -maxY*0.5 maxY*1.5]);
			pause(0.05);
		end
	else
		pause % if not plotting, just log data until a key is pressed
	end

	et.close(); % close TCP/IP connection

	if (et.doLog)
		disp('Writing log...');
		et.writeLogTo(logFile); % save data to a log file
	end

	disp('Done!');
end