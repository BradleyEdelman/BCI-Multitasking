function index = c_tree_getIndexOfNode(tree,nodeName,recursiveIndex)

	if nargin == 0
		% test
		tree = {'root','Test 1',{'Test 2','2.1','2.2'},'Test 3',{'Test 4','4.1','4.2',{'4.3','4.3.1','4.3.2'}}};
		out = c_tree_getIndexOfNode(tree,'root')
		keyboard
		return;
	end

	if nargin < 3
		recursiveIndex = [];
	end

	assert(iscell(tree));
	assert(ischar(nodeName));
	
	index = [];
	
	for n=1:length(tree)
		if iscell(tree{n})
			newIndex = c_tree_getIndexOfNode(tree{n},nodeName,[recursiveIndex n]);
			if ~isempty(newIndex)
				% node found
				index = newIndex;
				return
			end
		else
			if strcmp(nodeName,tree{n})
				% node found
				index = [recursiveIndex n];
				return;
			end
		end
	end
end