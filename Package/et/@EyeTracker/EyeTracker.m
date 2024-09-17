classdef EyeTracker < handle
	%EyeTracker TODO: summary
	%  TODO: detailed explanation

	%% Class methods
	properties (Constant)
		fullFeatureSet = {...% COMMAND, KEY(s), Description
					{'COUNTER',{'CNT'},'Message counter'},...
					{'TIME',{'TIME'},'Internal time since startup'},...
					{'POG_FIX',{'FPOGX','FPOGY','FPOGS','FPOGD','FPOGID','FPOGV'},'Point of gaze as determined by internal fixation filter'},...
					{'POG_LEFT',{'LPOGX','LPOGY','LPOGV'},'Left POG as fraction of screen size'},...
					{'POG_RIGHT', {'RPOGX','RPOGY','RPOGV'},'Right POG as fraction of screen size'},...
					{'POG_RIGHT', {'RPOGX','RPOGY','RPOGV'},'Right POG as fraction of screen size'},...
					{'POG_BEST', {'BPOGX','BPOGY','BPOGV'},'Best POG (average of left or right, or whichiver is available) as fraction of screen size'},...
					{'PUPIL_LEFT',{'LPCX','LPCY','LPD','LPS','LPV'},'Left pupil data (sensitive to distance between device and user)'},...
					{'PUPIL_RIGHT',{'RPCX','RPCY','RPD','RPS','RPV'},'Right pupil data (sensitive to distance between device and user)'},...
					{'EYE_LEFT',{'LEYEX','LEYEY','LEYEZ','LPUPILD','LPUPILV'},'Left eye 3D data (incl. pupil diameter in m)'},...
					{'EYE_RIGHT',{'REYEX','REYEY','REYEZ','RPUPILD','RPUPILV'},'Right eye 3D data (incl. pupil diameter in m)'},...
					{'CURSOR',{'CX','CY','CS'},'Position of mouse cursor'},...
					{'USER_DATA',{'USER'},'Custom user data'},...
					};
			defaultFeatures = {'COUNTER','TIME','POG_FIX','POG_BEST','EYE_LEFT','EYE_RIGHT','USER_DATA'};
			minimalFeatures = {'POG_BEST'};
	end

	methods (Static)
		[data, labels, descriptions] = importLog(log, useParallel, showProgress) % code in separate file

		function featureList = listOfKeys()
			featureList = '';
			for i=1:length(EyeTracker.fullFeatureSet)
				for j=1:length(EyeTracker.fullFeatureSet{i}{2})
					featureList = [featureList; EyeTracker.fullFeatureSet{i}{2}(j)];
				end
			end
		end

		function [data, labels, descriptions] = importLogFile(filename)
			log = fileread(filename);
			[data, labels, descriptions] = EyeTracker.importLog(log);
		end

		function data = convertLogToMat(logFileName, matFileName)
			disp('Importing log...');
			[data, map, descriptions] = EyeTracker.importLogFile(logFileName);
			disp('Saving mat...');
			save(matFileName,'data','map','descriptions');
			disp('Loading mat...');
			data = load(matFileName);
			disp('Done!');
		end

		%% Examples
		exampleInitAndRun(logFile,doPlot,doPrintRaw,doNotCalibrate)
		exampleAnalyzeLog(logFile)

	end


	%% Instance variables
	properties
		% Live data
		latestMsg = '';
		log = '';
		
		printPrefix = 'EyeTracker: ';
		doDebug;
		doRecord;
	end
	
	properties(SetAccess=protected)
		IP
		port
		pollPeriod;
	end
	
	properties(Access=protected)
		tmr;
		lineBuffer;
		ni = []; % network interfacer
	end

	%% Instance methods
	methods
		%% Constructor, destructor
		function o = EyeTracker(varargin)
			p = inputParser();
			p.addParameter('IP','127.0.0.1',@ischar);
			p.addParameter('port',4242,@isscalar);
			p.addParameter('pollPeriod',0.01,@isscalar);
			p.addParameter('doDebug',true,@islogical);
			p.addParameter('doRecord',true,@islogical);
			p.addParameter('doAutostart',true,@islogical);
			p.parse(varargin{:});
			s = p.Results;
			
			% copy parameters to class properties with the same names
			for iP = 1:length(p.Parameters)
				if isprop(o,p.Parameters{iP})
					o.(p.Parameters{iP}) = s.(p.Parameters{iP});
				end
			end
			
			c_say('%sConnecting...',o.printPrefix);
			
			o.ni = c_NetworkInterfacer(...
				'IP',o.IP,...
				'port',o.port,...
				'isServer',false,...
				'jtcpDoUseHelperClass',true,...
				'connectionTimeout',5e3);
			
			if ~o.ni.isConnected()
				c_sayDone('Could not connect.');
				return;
			end
			
			c_sayDone('%sConnected.',o.printPrefix);

			if s.doAutostart
				o.enableDefaultData(); % tell the eye tracker to transmit default features
				o.startPollTimer();
			end
		end

		function delete(o)
			if o.doDebug
				c_saySingle('%sDeleting',o.printPrefix);
			end
			o.close();
		end
		
		%% Higher level methods
		
		function enableDefaultData(obj)
			for i=1:length(EyeTracker.defaultFeatures)
				obj.setState(['ENABLE_SEND_' EyeTracker.defaultFeatures{i}], 1);
			end
		end
		function startSendingData(obj)
			obj.setState('ENABLE_SEND_DATA',1);
		end
		function stopSendingData(obj)
			obj.setState('ENABLE_SEND_DATA',0);
		end
		
		function sendUserData(obj,val,delayedVal,delayTime)
			% store data in eye tracker's "user data" field, which can only remember a single value a time
			%  Changes in the value are required to reconstruct "events" in the recorded data. I.e. consecutive
			%   identical values will be lost. 
			%  Can specify optional delayedVal to send a different value a fixed time later, to make sure consecutive
			%   events are not lost.
			
			assert(ischar(val) || isscalar(val));
			obj.setValue('USER_DATA',val);
			
			if nargin >= 3
				% set up timer to send delayedVal after a delay, while still returning immediately
				if nargin < 4
					delayTime = 0.2; 
				end
				ht = timer(...
					'BusyMode','queue',...
					'ExecutionMode','singleShot',...
					'Name','ET_DelayedUserSend',...
					'StartDelay',delayTime,...
					'TimerFcn',@(h,e) obj.sendUserData(delayedVal));
				start(ht);
			end
		end

		function calibrate(obj)
			obj.setState('TRACKER_DISPLAY',1);
			c_saySingle('Press any key to start calibration');
			pause
			c_say('Calibrating.');
			obj.startCalibration();
			c_saySingle('Press any key to stop calibration');
			pause
			obj.stopCalibration();
			c_sayDone();
			obj.setState('TRACKER_DISPLAY',1);
		end
		
		function startCalibration(obj)
			%obj.setValue('CALIBRATE_TIMEOUT', 2)
			%obj.setValue('CALIBRATE_DELAY',1.0)
			obj.setState('CALIBRATE_SHOW', 1)
			pause(5);
			obj.setState('CALIBRATE_START',1)
		end
		
		function stopCalibration(obj)
			obj.setState('CALIBRATE_START',0)
			obj.setState('CALIBRATE_SHOW',0);
		end
		
		function showCalibration(obj)
			obj.setState('CALIBRATE_SHOW',1);
		end
		
		function hideCalibration(obj)
			obj.setState('CALIBRATE_SHOW',0);
		end

		%% timer-related methods
		function startPollTimer(o)
			o.clearTimers();
			o.tmr = timer(...
				'BusyMode','drop',...
				'ExecutionMode','fixedSpacing',...
				'Name','EyeTrackerPollingTimer',...
				'Period',o.pollPeriod,...
				'TimerFcn',@(h,e)o.pollInputCallback);
			start(o.tmr);
		end
		
		function clearTimers(o)
			if o.doDebug
				c_say('%sClearing timers',o.printPrefix);
			end
			tmp = timerfindall('Name','EyeTrackerPollingTimer');
			if ~isempty(tmp)
				if o.doDebug
					c_saySingleMultiline('%sStopping timer(s) %s',o.printPrefix,c_toString(tmp));
				end
				stop(tmp);
				delete(tmp);
			end
			o.tmr = [];
			pause(o.pollPeriod*2);
			if o.doDebug
				c_sayDone('%sDone clearing timers',o.printPrefix);
			end
		end

		%% Lower level IO methods
		
		function iscon = isConnected(o)
			iscon = o.ni.isConnected();
		end

		function close(o)
			didClose = false;
			if ~isempty(o.tmr)
				o.clearTimers();
				didClose = true;
				pause(0.5); % wait for timer(s) to finish
			end
			
			if o.doDebug
				c_say('%sClosing network client',o.printPrefix);
			end
			if o.isConnected()
				didClose = true;
			end
			o.ni.close();
			if o.doDebug
				c_sayDone('%sDone closing network client',o.printPrefix);
			end
			
			if didClose
				c_saySingle('%sClosed',o.printPrefix);
			end
		end

		% parseLine
		%  Called by the callback functions below
		function parseLine(obj,rcvd)
			time = sprintf('%4d.%02d.%02d.%02d.%02d.%09.6f ',clock);
			if obj.doRecord
				obj.log = [obj.log time rcvd];
			end
			if obj.doDebug
				c_saySingle('Received: %s',rcvd);
			end
			
			obj.latestMsg = [time rcvd];
		end

		% pollInputCallback
		%  Called at a regular polling rate to read
		%  in new data. Not guaranteed to read a whole line at a time
		function pollInputCallback(obj)
			
			numBytesAvailable = obj.ni.numBytesAvailable;
			
			if (numBytesAvailable > 0)
				% read in bytes, concatenating on to any previous message
				%	in obj.lineBuffer
			
				obj.lineBuffer = [obj.lineBuffer ...
					char(obj.ni.tryRead('maxNumBytes',numBytesAvailable))];
					
				% search for CR/LF
				% tokenize into lines
				lines = strsplit(obj.lineBuffer,'\n');
				% call parseLine for each complete line

				for i=1:(length(lines)-1)
					% insert newline back in to string after it was stripped by
					% strsplit
					lines{i} = sprintf('%s\n\n',lines{i});
					obj.parseLine(lines{i});
				end
				% store the last unparsed half-message (or empty string)
				% for next time
				obj.lineBuffer = lines{end};
			end
		end


		function str = readAvailable(obj)
			str = char(obj.ni.tryRead());
		end

		function write(obj,strToWrite)
			obj.ni.sendBytes(convertString([strToWrite '\r\n']));
		end

		function get(obj,id)
			obj.write(['<GET ID="' id '" />']);
		end

		function set(obj,id,etc)
			obj.write(['<SET ID="' id '" ' etc ' />']);
		end

		function setValue(obj,id,val)
			if ischar(val)
				obj.set(id,['VALUE="' val '"']);
			else
				obj.set(id,['VALUE="' num2str(val) '"']);
			end
		end
		function setState(obj,id,val)
			obj.set(id,['STATE="' num2str(val) '"']);
		end

		function writeLogTo(obj, filename)
			if isempty(obj.log)
				return;
			end
			
			fileID = fopen(filename,'a'); % append to file
			if fileID==-1
				warning('Unable to open file at %s',filename);
				return;
			end
			fprintf(fileID,'%s',obj.log);
			fclose(fileID);
			obj.log = []; % clear log after writing out, since appending to file above
		end
	end
	
	%% class static methods
	methods(Static)
		function addDependencies()
			persistent pathModified;
			if isempty(pathModified)
				mfilepath=fileparts(fileparts(which(mfilename)));
				addpath(fullfile(mfilepath,'../Common'));
				addpath(fullfile(mfilepath,'../Common/Network'));
				c_NetworkInterfacer.addDependencies();
				pathModified = true;
			end
		end
		
		function sendUserData_oneShot(data, varargin)
			et = EyeTracker('doAutostart',false,varargin{:});
			if ~et.isConnected()
				warning('Failed to connect, cannot send user data.');
				return;
			end
			if ischar(data)
				str = data;
			else
				str = c_toString(data);
			end
			et.sendUserData(['Start_' str]);
			pause(0.1);
			et.sendUserData(['Stop_' str]);
			et.close();
		end
	end
end



function int8arr = convertString(str)
	i=1; j=1;
	while i<=length(str)
		if str(i)~='\'
			int8arr(j) = int8(str(i));
		else % parse control characters
			%TODO: switch to using sprintf to handle entire string with
			%control characters
			i = i+1;
			switch(str(i))
				case 'r' % carriage return
					int8arr(j) = int8(13);
				case 'n' % newline
					int8arr(j) = int8(10);
				case '\' % escaped \
					int8arr(j) = int8('\');
			end
		end
		i = i+1;
		j = j+1;
	end
end