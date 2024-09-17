logFile='D:\Brad\__bci_ESI\EyeTrackerData\Brad2.etd';
doLog = true;

% Initalization
et = EyeTracker('doRecord',true,'doAutostart',false);

% Receiving data
et.startSendingData(); % start streaming data

et_isConnected = ~isempty(et) && et.isConnected();

startTrigger = 3;
stopTrigger = 4;
if ~et_isConnected()
    EyeTracker.sendUserData_oneShot(userData,...
        'IP',s.eyeTrackerIP);
else
    et.sendUserData(startTrigger);
    pause(0.2);
    et.sendUserData(stopTrigger);
end




et.close(); % close TCP/IP connection

et.writeLogTo(logFile); % save data to a log file

