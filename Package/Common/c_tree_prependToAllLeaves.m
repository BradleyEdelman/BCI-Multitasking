function tree = c_tree_prependToAllLeaves(tree,prefix)
	% assuming tree is defined by cell array, where first element of each array is node name
	for i=2:length(tree)
		if iscell(tree{i})
			tree{i} = c_tree_prependToAllLeaves(tree{i},prefix);
		else
			tree{i} = [prefix tree{i}];
		end
	end
end