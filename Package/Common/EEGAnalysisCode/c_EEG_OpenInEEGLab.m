function EEG = c_EEG_OpenInEEGLab(EEG,cmd,doBlock)
	if nargin < 3
		doBlock = false;
	end
	if nargin < 2
		cmd = '';
	end
	
	evalin('base','eeglab');

	assignin('base','EEG',EEG);

	evalin('base','[ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 ); eeglab redraw');

	origEEG = EEG;
	clearvars('EEG'); % to make it clear that current workspace variable is not what's being modified
	
	if ~isempty(cmd)
		evalin('base',cmd);
	end

	if doBlock
		c_say('Running EEGLab in base workspace. Use ''evalin(''base'', ''<command>'' )'' to run commands.');
		c_saySingle('Type <a href="matlab: dbcont">dbcont</a> to continue');
		keyboard
		c_sayDone();
	end
	
	EEG = evalin('base','EEG');
end