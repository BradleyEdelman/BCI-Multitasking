function proceduresToRun = c_insertProcedure(varargin)
	p = inputParser();
	p.addRequired('newProcedure',@(x) iscell(x) || ischar(x));
	p.addRequired('proceduresToRun',@iscell);
	p.addRequired('index',@isscalar);
	p.addParameter('doCheckRedundant',true,@islogical);
	p.addParameter('doPrintIfRedundant',true,@islogical);
	p.parse(varargin{:});
	s = p.Results;

	newProcedure = s.newProcedure;
	proceduresToRun = s.proceduresToRun;
	index = s.index;
	
	if ~iscell(newProcedure)
		newProcedure = {newProcedure};
	end
	if s.doCheckRedundant && ...
			length(proceduresToRun((index+1):end))>=length(newProcedure) && ...
			isequal(proceduresToRun((index+1):(index+1+length(newProcedure)-1)),newProcedure)
		if s.doPrintIfRedundant
			c_saySingle('Procedure ''%s'' is already next, not adding',c_toString(newProcedure));
		end
		return;
	end
	if length(proceduresToRun)==index
		proceduresToRun = [proceduresToRun(1:index), newProcedure];
	else
		proceduresToRun = [proceduresToRun(1:index),newProcedure,proceduresToRun((index+1):end)];
	end
end