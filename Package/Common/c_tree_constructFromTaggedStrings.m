function tree = c_tree_constructFromTaggedStrings(dataFeatures, doKeepCategories)
	if nargin == 0
		% test
		out = c_tree_constructFromTaggedStrings({'(category1,category2) name1', '(category1,category3) name2', 'name3'});
		return;
	end
	if nargin < 2
		doKeepCategories = false;
	end
	% convert cell array of strings in format {'(category1, category2) name1', '(category1, category3) name2, name3'}
	%  to {{'category1',name1,name2},{'category2',name1},{'category3','name2'},name3}
	availableFeatures = dataFeatures;
	categories = {};
	parsedFeatures = cell(1,length(availableFeatures));
	for i=1:length(availableFeatures)
		name = availableFeatures{i};
		category = {};
		if name(1)=='('
			tmp = strfind(name,') ');
			if isempty(tmp)
				error('unclosed parentheses in %s',name);
			end
			category = strsplit(name(2:(tmp-1)),',');
			categories = [categories, category];
			if ~doKeepCategories
				name = name((tmp+2):end);
			end
		end
		parsedFeatures{i} = {category, name};
		availableFeatures{i} = ['Plot - ' availableFeatures{i}];
	end
	categories = unique(categories,'sorted');
	tree = categories;
	for i=1:length(parsedFeatures)
		name = parsedFeatures{i}{2};
		category = parsedFeatures{i}{1};
		if ~isempty(category)
			indices = find(ismember(categories,category));
			for j=1:length(indices)
				tree{indices(j)} = [tree{indices(j)}, {name}];
			end
		else
			tree = [tree, name];
		end
	end
	tree = [{'root node'},tree];
end
