function [doesMatch, matchingStrs] = c_str_matchRegex(varargin)
% c_str_matchRegex: find strings matching regular expression(s)
%
% Example usage:
%     [matchingIndices, matchingStrings] = c_str_matchRegex({'Test string 1','Test string 2','String 3'},'^Test*');

	if nargin == 0
		testfn(); return;
	end
	
	p = inputParser();
	p.addRequired('strs',@(x) iscellstr(x) || ischar(x));
	p.addRequired('regex',@(x) iscellstr(x) || ischar(x));
	p.addParameter('multiRegexOperation','or',@ischar); % if multiple regex strings are supplied, how should they be combined?
	p.parse(varargin{:});
	s = p.Results;
	
	strs = s.strs;
	regex = s.regex;
	
	if ~iscell(strs)
		strs = {strs};
	end
	if ~iscell(regex)
		regex = {regex};
	end
	
	doesMatch = false(length(regex),length(strs));
	
	for iR = 1:length(regex)
		for iS = 1:length(strs)
			startIndex = regexp(strs{iS},regex{iR},'once','emptymatch');
			doesMatch(iR,iS) = ~isempty(startIndex);
		end
	end
	
	if length(regex) > 1
		% combine results from multiple regexes
		switch(s.multiRegexOperation)
			case 'and'
				doesMatch = all(doesMatch,1);
			case 'or'
				doesMatch = any(doesMatch,1);
			otherwise
				error('Invalid multiRegexOperation: %s',s.multiRegexOperation);
		end
	end
			
	if nargout > 1
		matchingStrs = strs(doesMatch);
	end
	
end


function testfn()
	indices = c_str_matchRegex({'Test_a','Test_b','A test'},'^T.*')
end
