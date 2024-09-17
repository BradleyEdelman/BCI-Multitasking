function resp = c_dialog_verify(varargin)
	p = inputParser();
	p.addOptional('msg','Are you sure?',@ischar);
	p.addParameter('defaultAnswer','No',@ischar);
	p.parse(varargin{:});
	s = p.Results;
	
	c_say('Waiting for user input: %s',s.msg);
	resp = questdlg(s.msg,s.msg,'Yes','No',s.defaultAnswer);
	c_sayDone();
	
	if isempty(resp)
		error('Dialog cancelled by user');
	end
	
	if strcmp(resp,'Yes')
		resp = 1;
	else
		resp = 0;
	end
end