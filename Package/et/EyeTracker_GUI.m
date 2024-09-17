function EyeTracker_GUI(varargin)

	%% add dependencies
	persistent pathModified;
	if isempty(pathModified)
		mfilepath=fileparts(which(mfilename));
		addpath(fullfile(mfilepath,'.'));
		addpath(fullfile(mfilepath,'../Common'));
		addpath(fullfile(mfilepath,'../Common/ThirdParty/uisplitpane'));
		addpath(fullfile(mfilepath,'../Common/ThirdParty/findjobj'));
		addpath(fullfile(mfilepath,'../Common/GUI'));
		EyeTracker.addDependencies();
		pathModified = true;
	end

	%% inputs / settings
	p = inputParser();
	p.addParameter('defaultBaseDirectory','C:\Data',@ischar);
	p.addParameter('defaultDataFilename','EyeTracker_TIMESTAMP.etd',@ischar);
	p.addParameter('doDebug',false,@islogical);
	p.addParameter('doLivePlot',false,@islogical);
	p.addParameter('doAutosave',true,@islogical);
	p.addParameter('doAutoconnect',true,@islogical);
	p.addParameter('eyeTrackerIP','localhost',@ischar);
	p.addParameter('livePlotPeriod',0.1,@isscalar); % in s
	p.addParameter('autosavePeriod',30,@isscalar); % in s
	p.addParameter('resize','left-half',@ischar); % e.g. 'top-half' or 'maximize'. Set empty to not resize
	p.addParameter('resizeToMonitor',2,@isscalar);
	p.parse(varargin{:});
	s = p.Results;
	
	%% misc initialization
	
	et = []; % eyeTracker object
	
	c_sayResetLevel();
	
	s.timestamp = [];
	
	%% construct GUI

	global g_h; %TODO: make persistent
	if ~isempty(g_h) && ishandle(g_h)
		close(g_h);
	end
	g_h = figure('name','EyeTracker GUI',...
		'SizeChangedFcn',@(h,e) callback_GUI_setPositions(),...
		'CloseRequestFcn',@(h,e) callback_GUI_CloseFigure());
	guiH.fig = g_h;

	[guiH.controlsPanel, guiH.mainPanel, ~] = uisplitpane(guiH.fig,...
		'Orientation','horizontal',...
		'DividerLocation',0.4);
	guiH.tabgrp_controls = uitabgroup(guiH.controlsPanel,...
		'Position',[0 0 1 1],...
		'Units','normalized');
	guiH.tabgrp_main = uitabgroup(guiH.mainPanel,...
		'Position',[0 0 1 1],...
		'Units','normalized');
	
	guiH.activateOnlyWhenConnected = {};

	initialize_controls();
	initialize_livePlot();

	if ~isempty(s.resize)
		c_fig_arrange(s.resize,guiH.fig,'monitor',s.resizeToMonitor);	
	end
	
	if s.doAutosave
		callback_startAutosaving();
	end
	
	callback_et_updateConnectionStatus();
	
	if s.doAutoconnect
		callback_et_init();
	end

	%% general callbacks
	function callback_GUI_setPositions()

	end

	function callback_GUI_CloseFigure()
		c_say('Closing EyeTracker GUI');
		
		if ~c_isFieldAndNonEmpty(guiH,'livePlot_tmr')
			c_saySingle('Stopping live plot timer');
			tmp = timerfindall('Name','LivePlotTimer');
			if ~isempty(tmp)
				stop(tmp);
				delete(tmp);
			end
			guiH.livePlot_tmr = [];
		end
		
		callback_stopAutosaving();
		%callback_autosave();
		
		callback_et_close();
		
		closereq();
		c_sayDone();
	end

	%% controls
	function initialize_controls()
		guiH.tab_controls_main = uitab(guiH.tabgrp_controls,'Title','Main Controls');
		hp = guiH.tab_controls_main;
		
		vertLoc = 1;
		
		height = 0.1;
		vertLoc = vertLoc - height;
		guiH.ctrl_text_eyeTrackerIPContainer = uipanel(...
			'parent',hp,...
			'Title','EyeTracker IP',...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		guiH.ctrl_text_eyeTrackerIP = uicontrol(guiH.ctrl_text_eyeTrackerIPContainer,...
			'Style','edit',...
			'String',s.eyeTrackerIP,...
			'Callback',@(h,e) callback_updateEyeTrackerIP(),...
			'Units','normalized',...
			'Position',[0 0 1 1]);
		
		height = 0.05;
		
		vertLoc = vertLoc - height;
		guiH.ctrl_btn_et_connect = uicontrol(hp,...
			'Style','pushbutton',...
			'String','Connect EyeTracker',...
			'Callback',@(h,e) callback_et_toggleConnect(),...
			'Units','normalized',...
			'Position',[0.5 vertLoc 0.5 height]);
		
		guiH.ctrl_txt_et_connectionStatus = uicontrol(hp,...
			'Style','text',...
			'String','Status: Not connected',...
			'BackgroundColor',[1 0 0],...
			'Units','normalized',...
			'Position',[0 vertLoc 0.5 height]);
		
		jh = findjobj(guiH.ctrl_txt_et_connectionStatus);
		jh.setVerticalAlignment(javax.swing.JLabel.CENTER)
		
		height = 0.05;
		vertLoc = vertLoc - height;
		guiH.ctrl_btn_et_calibrateStart = uicontrol(hp,...
			'Style','pushbutton',...
			'String','Start calibration',...
			'Callback',@(h,e) callback_et_startCalibration(),...
			'Units','normalized',...
			'Position',[0 vertLoc 0.5 height]);
		guiH.activateOnlyWhenConnected{end+1} = guiH.ctrl_btn_et_calibrateStart;
		guiH.ctrl_btn_et_calibrateStop = uicontrol(hp,...
			'Style','pushbutton',...
			'String','Stop calibration',...
			'Callback',@(h,e) callback_et_stopCalibration(),...
			'Units','normalized',...
			'Position',[0.5 vertLoc 0.5 height]);
		guiH.activateOnlyWhenConnected{end+1} = guiH.ctrl_btn_et_calibrateStop;
		
		height = 0.05;
		vertLoc = vertLoc - height;
		guiH.ctrl_btn_et_calibrateShow = uicontrol(hp,...
			'Style','pushbutton',...
			'String','Show calibration test',...
			'Callback',@(h,e) callback_et_showCalibration(),...
			'Units','normalized',...
			'Position',[0 vertLoc 0.5 height]);
		guiH.activateOnlyWhenConnected{end+1} = guiH.ctrl_btn_et_calibrateShow;
		guiH.ctrl_btn_et_calibrateHide = uicontrol(hp,...
			'Style','pushbutton',...
			'String','Hide calibration test',...
			'Callback',@(h,e) callback_et_hideCalibration(),...
			'Units','normalized',...
			'Position',[0.5 vertLoc 0.5 height]);
		guiH.activateOnlyWhenConnected{end+1} = guiH.ctrl_btn_et_calibrateHide;
		
		height = 0.05;
		vertLoc = vertLoc - height;
		guiH.ctrl_btn_et_sendTrigger = uicontrol(hp,...
			'Style','pushbutton',...
			'String','Send trigger',...
			'Callback',@(h,e) callback_et_sendTrigger(),...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		guiH.activateOnlyWhenConnected{end+1} = guiH.ctrl_btn_et_sendTrigger;
		
		vertLoc = vertLoc - height;
		guiH.ctrl_et_doStream = uicontrol(hp,...
			'Style','checkbox',...
			'String','Stream EyeTracker data',...
			'Callback',@(h,e) callback_et_changeStreaming(h.Value),...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		guiH.activateOnlyWhenConnected{end+1} = guiH.ctrl_et_doStream;
		
		vertLoc = vertLoc - height;
		guiH.ctrl_et_doRecord = uicontrol(hp,...
			'Style','checkbox',...
			'String','Record EyeTracker data',...
			'Callback',@(h,e) callback_et_changeRecording(h.Value),...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		guiH.activateOnlyWhenConnected{end+1} = guiH.ctrl_et_doRecord;
		
		vertLoc = vertLoc - height;
		guiH.ctrl_et_doAutosave = uicontrol(hp,...
			'Style','checkbox',...
			'String','Autosave recorded data',...
			'Callback',@(h,e) callback_et_changeAutosave(h.Value),...
			'Value',s.doAutosave,...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		
		vertLoc = vertLoc - height;
		guiH.ctrl_et_doLivePlot = uicontrol(hp,...
			'Style','checkbox',...
			'String','Show live EyeTracker data',...
			'Value',s.doLivePlot,...
			'Callback',@(h,e) callback_changeLivePlotting(h.Value),...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		
		vertLoc = vertLoc - height;
		guiH.ctrl_et_doDebug = uicontrol(hp,...
			'Style','checkbox',...
			'String','Print debug output',...
			'Value',s.doDebug,...
			'Callback',@(h,e) callback_changeDoDebug(h.Value),...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		
		vertLoc = vertLoc - 0.05; % offset
		
		height = 0.1;
		vertLoc = vertLoc - height;
		guiH.filefield_baseDirectory = c_GUI_FilepathField(...
			'label','Data directory',...
			'mode','browse-only',...
			'path',s.defaultBaseDirectory,...
			'isDir',true,...
			'pathChangedCallback',@(~) callback_updateBaseDirectory(),...
			'doAllowManualEditing',true,...
			'parent',hp,...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		
		vertLoc = vertLoc - height;
		guiH.filefield_dataFile = c_GUI_FilepathField(...
			'label','Main data file',...
			'mode','save-browse',...
			'relativeTo',s.defaultBaseDirectory,...
			'relPath',s.defaultDataFilename,...
			'validFileTypes','*.etd',...
			'pathChangedCallback',@(~) callback_updateDataFilePath(),...
			'doAllowManualEditing',true,...
			'parent',hp,...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		
		height = 0.05;
		vertLoc = vertLoc - height;
		guiH.ctrl_btn_save = uicontrol(hp,...
			'Style','pushbutton',...
			'String','Save',...
			'Callback',@(h,e) callback_save(),...
			'Units','normalized',...
			'Enable','off',...
			'Position',[0 vertLoc 1 height]);
		
		vertLoc = vertLoc - height;
		guiH.ctrl_txt_lastSaved = uicontrol(hp,...
			'Style','text',...
			'String','Last saved: never',...
			'Units','normalized',...
			'Position',[0 vertLoc 1 height]);
		
% 		height = 0.05;
% 		vertLoc = vertLoc - height;
% 		guiH.ctrl_btn_keyboard = uicontrol(hp,...
% 			'Style','pushbutton',...
% 			'String','Debug',...
% 			'Callback',@(h,e) callback_keyboard(),...
% 			'Units','normalized',...
% 			'Position',[0 vertLoc 1 height]);
		
	end

	function callback_updateBaseDirectory()
		newPath = guiH.filefield_baseDirectory.path;
		c_saySingle('Base dir changed to %s',newPath);
		if ~exist(newPath,'dir')
			if c_dialog_verify(sprintf('Create directory at ''%s''?',newPath))
				mkdir(newPath);
			else
				warning('Base directory does not exist at %s',newPath);
			end
		end
		guiH.filefield_dataFile.relativeTo = newPath;
	end

	function callback_updateDataFilePath()
		newPath = guiH.filefield_dataFile.path;
		c_saySingle('Data filepath changed to %s',newPath);
	end

		
	%% Eye tracker
	
	function isConnected = et_isConnected()
		isConnected = ~isempty(et) && et.isConnected();
	end
	
	function callback_updateEyeTrackerIP()
		newIPStr = guiH.ctrl_text_eyeTrackerIP.String;
		s.eyeTrackerIP = newIPStr;
		
		c_saySingle('Changed EyeTracker IP to %s',newIPStr);
		
		if ~isempty(et)
			callback_et_init();
		end
	end
	
	function callback_et_init()
		c_say('Initializing EyeTracker');
		et = []; % clear previous
		
		callback_et_updateConnectionStatus(true);
		drawnow
		
		et = EyeTracker(...
			'IP',s.eyeTrackerIP,...
			'doDebug',s.doDebug,...
			'doRecord',guiH.ctrl_et_doRecord.Value > 0);
		
		if ~et.isConnected()
			errordlg('Could not connect to EyeTracker');
			callback_et_close(true);
		else
			callback_et_updateConnectionStatus();
		end
		
		c_sayDone();
	end

	function callback_et_updateConnectionStatus(isConnecting)
		if nargin < 1
			isConnecting = false;
		end
		persistent prevStatus;
		if isConnecting
			prevStatus = [];
			guiH.ctrl_btn_et_connect.String = 'Disconnect EyeTracker';
			guiH.ctrl_txt_et_connectionStatus.String = 'Status: Connecting';
			guiH.ctrl_txt_et_connectionStatus.BackgroundColor = [1 0.55 0];
			return;
		end
		
		newStatus = et_isConnected();
		if isempty(prevStatus) || prevStatus ~= newStatus
			if newStatus
				guiH.ctrl_btn_et_connect.String = 'Disconnect EyeTracker';
				guiH.ctrl_txt_et_connectionStatus.String = 'Status: Connected';
				guiH.ctrl_txt_et_connectionStatus.BackgroundColor = [0.3 1 0.3];
				guiH.ctrl_btn_save.Enable = 'on';
% 				keyboard
				for i = 1:length(guiH.activateOnlyWhenConnected)
					guiH.activateOnlyWhenConnected{i}.Enable = 'on';
				end
			else
				guiH.ctrl_btn_et_connect.String = 'Connect EyeTracker';
				guiH.ctrl_txt_et_connectionStatus.String = 'Status: Not connected';
				guiH.ctrl_txt_et_connectionStatus.BackgroundColor = [1 0.3 0.3];
				for i = 1:length(guiH.activateOnlyWhenConnected)
					guiH.activateOnlyWhenConnected{i}.Enable = 'off';
				end
			end
			prevStatus = newStatus;
		end
	end

	function callback_et_toggleConnect()
		if strcmpi(guiH.ctrl_btn_et_connect.String,'Connect EyeTracker')
			callback_et_init();
		else
			callback_et_close();
		end
	end

	function callback_et_close(doSilent)
		if nargin < 1
			doSilent = false;
		end
		if ~isempty(et)
			if ~doSilent
				c_say('Disconnecting EyeTracker');
			end
			et.close();
			et = [];
			if ~doSilent
				c_sayDone();
			end
		end
		callback_et_updateConnectionStatus();
	end

	function callback_et_startCalibration()
		if ~et_isConnected()
			callback_et_init();
			if ~et_isConnected()
				warning('Failure to connect, cannot continue with calibration');
				return;
			end
		end
		c_saySingle('Starting calibration');
		et.startCalibration();
	end

	function callback_et_stopCalibration()
		if et_isConnected()
			c_saySingle('Stopping calibration');
			et.stopCalibration();
		end
	end

	function callback_et_showCalibration()
		if ~et_isConnected()
			callback_et_init();
			if ~et_isConnected()
				warning('Failure to connect, cannot continue with calibration');
				return;
			end
		end
		c_saySingle('Showing calibration');
		et.showCalibration();
	end

	function callback_et_hideCalibration()
		if et_isConnected()
			c_saySingle('Hiding calibration');
			et.hideCalibration();
		end
	end

	function callback_et_sendTrigger()
		startTrigger = 1;
		stopTrigger = 2;
		if ~et_isConnected()
			EyeTracker.sendUserData_oneShot(userData,...
				'IP',s.eyeTrackerIP);
		else
			et.sendUserData(startTrigger);
			pause(0.2);
			et.sendUserData(stopTrigger);
		end
	end

	function callback_et_changeRecording(doRecord)
		if ~isequal(guiH.ctrl_et_doRecord.Value,doRecord)
			guiH.ctrl_et_doRecord.Value = doRecord;
		end
		
		if doRecord && isempty(et)
			errordlg('Not connected. Connect to eye tracker before starting recording');
			callback_et_changeRecording(false);
			return;
		end
		
		if doRecord
			s.timestamp = ''; % reset here to force new time (and new timestamped file) during next autosave
		end
		
		if ~isempty(et)
			et.doRecord = doRecord;
			
			if doRecord
				isStreaming = guiH.ctrl_et_doStream.Value;
				if ~isStreaming && c_dialog_verify('Start streaming?','defaultAnswer','Yes')
					callback_et_changeStreaming(true);
				end
			end
		end
	end

	function callback_et_changeAutosave(doAutosave)
		if ~isequal(guiH.ctrl_et_doAutosave.Value,doAutosave)
			guiH.ctrl_et_doAutosave.Value = doAutosave;
		end
		
		if doAutosave && ~s.doAutosave
			callback_startAutosaving();
		elseif ~doAutosave && s.doAutosave
			callback_stopAutosaving();
		end
		
		s.doAutosave = doAutosave;
	end

	function callback_et_changeStreaming(doStream)
		if doStream && ~et_isConnected()
			callback_et_init();
			if ~et_isConnected()
				warning('Failure to connect, cannot start streaming');
				guiH.ctrl_et_doStream.Value = false;
				return;
			end
		end
		
		if ~isequal(guiH.ctrl_et_doStream.Value,doStream)
			guiH.ctrl_et_doStream.Value = doStream;
		end
		
		if doStream
			c_saySingle('Starting streaming of data');
			et.startSendingData();
		elseif et_isConnected()
			c_saySingle('Stopping streaming of data');
			et.stopSendingData();
		end
	end
		
	%% Plotting

	function initialize_livePlot()
		guiH.tab_livePlot = uitab(guiH.tabgrp_main,'Title','Live plot');
		hp = guiH.tab_livePlot;
		
		guiH.livePlotAx = axes('parent',hp);
		
		s.screenSize = get(0,'ScreenSize');
		
		maxX = s.screenSize(3);
		maxY = s.screenSize(4);
		
		axis(guiH.livePlotAx,'equal');
		axis(guiH.livePlotAx,[-maxX*0.5 maxX*1.5 -maxY*0.5 maxY*1.5]);
		
		rectangle('Position',[0 0 maxX maxY],'parent',guiH.livePlotAx);
		
		guiH.livePosH = [];
	end


	function callback_changeLivePlotting(doPlot)
		if ~isequal(guiH.ctrl_et_doLivePlot.Value,doPlot)
			guiH.ctrl_et_doLivePlot.Value = doPlot;
		end
		prevDoPlot = s.doLivePlot;
		s.doLivePlot = doPlot;
		
		if doPlot && ~prevDoPlot
			if s.doDebug
				c_saySingle('Starting live plot timer');
			end
			guiH.livePlot_tmr = timer(...
				'BusyMode','drop',...
				'ExecutionMode','fixedSpacing',...
				'Name','LivePlotTimer',...
				'Period',s.livePlotPeriod,...
				'TimerFcn',@(h,e) callback_updateLivePlot());
			
			start(guiH.livePlot_tmr);
		elseif ~doPlot && prevDoPlot
			if s.doDebug
				c_saySingle('Stopping live plot timer');
			end
			tmp = timerfindall('Name','LivePlotTimer');
			if ~isempty(tmp)
				stop(tmp);
				delete(tmp);
			end
			guiH.livePlot_tmr = [];
		end
	end
	
	function callback_updateLivePlot()
		if isempty(et) || isempty(et.latestMsg)
			%c_saySingle('No data, not plotting.');
			clearLivePlotMarker();
			return;
		end
		
		msg = et.latestMsg;
		
		[data, map] = EyeTracker.importLog(msg,false);
		
		if ~all(ismember({'BPOGX','BPOGY','BPOGV'},map.keys));
			% necessary data not available in this message
			return;
		end
		
		x = data(1,map('BPOGX'));
		y = data(1,map('BPOGY'));
		v = data(1,map('BPOGV'));
		
		persistent prevUserData;
		if ismember('USER_DATA',map.keys)
			userData = data(1,map('USER_DATA'));
			if userData ~= prevUserData
				c_saySingle('User data changed from %s to %s',prevUserData,userData);
				prevUserData = userData;
			end
		end
		
		maxX = s.screenSize(3);
		maxY = s.screenSize(4);
		
		if v
			title(guiH.livePlotAx,'BPOG valid');
		else
			title(guiH.livePlotAx,'BPOG NOT valid!');
		end
		
		if ~isempty(guiH.livePosH)
			delete(guiH.livePosH);
		end
		guiH.livePosH = rectangle(...
			'Position',[x*maxX, (1-y)*maxY, 64, 64],...
			'Curvature',[1 1],...
			'FaceColor','r');
	end

	function clearLivePlotMarker()
		if ~isempty(guiH.livePosH)
			delete(guiH.livePosH);
			guiH.livePosH = [];
		end
	end

	%% autosave
	function callback_startAutosaving()
		c_saySingle('Starting autosave timer');
			guiH.autosave_tmr = timer(...
				'BusyMode','drop',...
				'ExecutionMode','fixedSpacing',...
				'Name','AutosaveTimer',...
				'Period',s.autosavePeriod,...
				'TimerFcn',@(h,e) callback_autosave());
			
			start(guiH.autosave_tmr);
	end

	function callback_stopAutosaving()
		tmp = timerfindall('Name','AutosaveTimer');
		if ~isempty(tmp)
			if s.doDebug
				c_saySingle('Stopping autosave timer');
			end
			stop(tmp);
			delete(tmp);
		end
		guiH.autosave_tmr = [];
	end

	function callback_autosave()
		callback_save();
	end

	function callback_save()
		if ~isempty(et) && ~isempty(et.log)
			exportPath = guiH.filefield_dataFile.path;
			exportPath = timestampStringIfNeeded(exportPath);
			if s.doDebug
				c_say('Saving recent data to %s',exportPath);
			end
			et.writeLogTo(exportPath);
			guiH.ctrl_txt_lastSaved.String = sprintf('Last saved: %s',datestr(datetime('now'),'HH:MM:ss'));
			if s.doDebug
				c_sayDone();
			end
		end
	end

	function str = timestampStringIfNeeded(str)
		if isempty(s.timestamp)
			s.timestamp = datestr(now,'yymmddHHMMSS');
		end
		str = strrep(str,'TIMESTAMP',s.timestamp);
	end
	
	%% Debug
	
	function callback_changeDoDebug(doDebug)
		s.doDebug = doDebug > 0;
		if ~isempty(et)
			et.doDebug = doDebug;
		end
	end

	function callback_keyboard()
		keyboard
	end

end