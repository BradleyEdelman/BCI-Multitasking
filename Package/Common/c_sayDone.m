function c_sayDone(varargin)

global sayNestLevel;
if isempty(sayNestLevel)
	sayNestLevel = 0;
end

global saySilenceLevel;
if ~isempty(saySilenceLevel) && sayNestLevel-1 >= saySilenceLevel
	% don't print anything
	sayNestLevel = max(sayNestLevel-1,0);
	return
end

if verLessThan('matlab','8.4')
	fprintf('%s ',datestr(now,13));
else
	fprintf('%s ',datestr(datetime,'HH:MM:ss'));
end

sayNestLevel = max(sayNestLevel-1,0);
for i=1:sayNestLevel
	if mod(i,2)==0
		fprintf(' ');
	else
		fprintf('|');
	end
end
fprintf('^ ');
if ~isempty(varargin)
	fprintf(varargin{:});
end
fprintf('\n');

end