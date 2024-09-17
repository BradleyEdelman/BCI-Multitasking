function leaves = c_tree_getLeaves(tree)
	% assuming tree is defined by cell array, where first element of each array is node name
	leaves = {};
	for i=2:length(tree)
		if iscell(tree{i})
			leaves = [leaves, c_tree_getLeaves(tree{i})];
		else
			leaves = [leaves, tree(i)];
		end
	end
end