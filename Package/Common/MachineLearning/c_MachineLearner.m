classdef c_MachineLearner < handle
	%% Instance variables
	properties
		inputPredictors;
		inputLabels;
		doUsePredictor;
		predictorLabels;
		method;
		classifier = [];
		isTrained = false;
		uniqueClassLabels;
		numClasses;
	end

	%% internal instance methods
	methods (Access=protected)

	end

	%% instance methods
	methods
		%% constructor
		function o = c_MachineLearner(varargin)
			p = inputParser();
			p.addParameter('inputPredictors',[],@ismatrix); % rows = samples, columns = features
			p.addParameter('inputLabels',[],@(x) isvector(x) || iscell(x)); % "correct" classification labels, one for each sample
			p.addParameter('predictorLabels',{},@iscell); % string label for each predictor
			p.addParameter('method','SVM',@ischar);
			p.parse(varargin{:});

			fieldsToCopy = {'inputPredictors', 'inputLabels','predictorLabels','method'};
			for i=1:length(fieldsToCopy)
				o.(fieldsToCopy{i}) = p.Results.(fieldsToCopy{i});
			end
			o.uniqueClassLabels = unique(o.inputLabels);
			o.numClasses = length(o.uniqueClassLabels);
			o.doUsePredictor = true(1,size(o.inputPredictors,2));
		end
		%%
		function train(o)
			% train on inputPredictors and inputLabels
			inputFeatures = o.inputPredictors(:,o.doUsePredictor);
			inputFeatureLabels = o.predictorLabels(o.doUsePredictor);
			switch(lower(o.method))
				case 'lda'
					o.classifier = fitcdiscr(inputFeatures,o.inputLabels,...
						'PredictorNames',inputFeatureLabels);
				case 'svm'
					if o.numClasses <= 2
						o.classifier = fitcsvm(inputFeatures,o.inputLabels,...
							'Standardize',true,...
							'PredictorNames',inputFeatureLabels);
					else
						templ = templateSVM('Standardize',1);
						o.classifier = fitcecoc(inputFeatures,o.inputLabels,...
							'Learners',templ,...
							'PredictorNames',inputFeatures,...
							'Coding','onevsone');
					end
				otherwise
					error('Unsupported method: %s',o.method);
			end
			o.isTrained = true;
		end

		function setPredictorsToIgnore(o,predictorsToIgnore)
			assert(iscell(predictorsToIgnore));
			o.doUsePredictor = ~ismember(o.predictorLabels,predictorsToIgnore);
			o.isTrained = false; % if predictors changed, we need to retrain
		end

		function err = crossvalidate(o)
			assert(o.isTrained);

			cvclassifier = crossval(o.classifier);

			err = kfoldLoss(cvclassifier);
		end

		function openInClassificationLearner(o)
			% we can't pass data directly to classification learner in script
			% instead, export relevant data to "trainingTable" in base workspace to allow import from within GUI
			table = array2table(o.inputPredictors(:,o.doUsePredictor),'VariableNames',o.predictorLabels(o.doUsePredictor));
			table = [table, cell2table(o.inputLabels,'VariableNames',{'response'})];
			assignin('base','trainingTable',table);

			classificationLearner;

			keyboard
		end

		function plotVisualization(o,varargin)
			assert(o.isTrained);

			p = inputParser();
			p.addParameter('doPlotDecisionRegions',true,@islogical);
			p.addParameter('doPlotScatter',true,@islogical);
			p.addParameter('decisionRegionRelativeBounds',1,@isscalar);
			p.parse(varargin{:});
			s = p.Results;

			numPredictors = size(o.inputPredictors,2);
			assert(numPredictors==2); % current code below assumes only two dimensions

			dimsToVisualize = 1:numPredictors;
			pts = o.inputPredictors(:,dimsToVisualize);
			xlims = extrema(pts(:,1));
			ylims = extrema(pts(:,2));
			DRxlims = diff(xlims)*s.decisionRegionRelativeBounds*[-1 1]/2 + mean(xlims);
			DRylims = diff(ylims)*s.decisionRegionRelativeBounds*[-1 1]/2 + mean(ylims);

			colors = c_getColors(o.numClasses);

			if s.doPlotDecisionRegions
				N = 100*s.decisionRegionRelativeBounds;
				x = linspace(DRxlims(1),DRxlims(2),N);
				y = linspace(DRylims(1),DRylims(2),N);
				[xx,yy] = meshgrid(x,y);
				gridPts = [reshape(xx,[],1), reshape(yy,[],1)];
				gridClassLabels = o.predict(gridPts);
				% convert string labels to indices into labels list
				gridClassIndices = nan(length(gridClassLabels),1);
				for iC=1:o.numClasses
					indices = ismember(gridClassLabels,o.uniqueClassLabels(iC));
					gridClassIndices(indices) = iC;
				end
				hi = imagesc(DRxlims,DRylims,reshape(gridClassIndices,N,N));
				hi.AlphaData = 0.2;
				set(gca,'ydir','normal');
				hold(gca,'on')
				colormap(colors);
				set(hi,'XLimInclude','off','YLimInclude','off');
			end

			if ((strcmpi(o.method,'LDA') && strcmpi(o.classifier.DiscrimType,'linear')) ...
					|| (strcmpi(o.method,'SVM') && strcmpi(o.classifier.KernelParameters.Function,'linear'))) ...
					&& all(o.doUsePredictor)
				% can draw line (or hyperplane) dividing classes

				if strcmpi(o.method,'LDA')
					% from documentation, the equation of the boundary is:
					%	const + linear * x + x' * quadratic * x = 0
					coeffs = o.classifier.Coeffs(1,2);
					f = @(x1,x2) coeffs.Const + coeffs.Linear(dimsToVisualize(1))*x1 + coeffs.Linear(dimsToVisualize(2))*x2;
					h = ezplot(f,[DRxlims, DRylims]);

				elseif strcmpi(o.method,'SVM')
					Beta = o.classifier.Beta(dimsToVisualize);
					if ~isempty(o.classifier.Mu)
						% was standardized
						mu = o.classifier.Mu(dimsToVisualize);
						sigma = o.classifier.Sigma(dimsToVisualize);
					else
						mu = zeros(1,length(dimsToVisualize));
						sigma = ones(1,length(dimsToVisualize));
					end
					%f = @toDelete;
					f = @(x1,x2) c_dot(bsxfun(@rdivide,bsxfun(@minus,[x1, x2],mu),sigma),Beta') / o.classifier.KernelParameters.Scale + o.classifier.Bias;
					h = ezplot(f,[DRxlims, DRylims]);
					%TODO: verify that decision boundary is plotted correctly

					%TODO: add background plot of decision regions using grid of points and [~,score]=o.classifier.predict(gridPts) as in documentation
					% (this will support more than just linear SVMs)
				else
					error('Unsupported');
				end
				
				set(h,'XLimInclude','off','YLimInclude','off');
			else
				if ~s.doPlotDecisionRegions
					error('Unsupported method for visualization');
				end
			end

			if s.doPlotScatter
				hold(gca,'on');
				gscatter(pts(:,1),pts(:,2),o.inputLabels,colors);
			end
			
			xlabel(o.predictorLabels{dimsToVisualize(1)});
			ylabel(o.predictorLabels{dimsToVisualize(2)});
				
			%title(sprintf('%s vs. %s',o.predictorLabels{dimsToVisualize}));
			title('Classification visualization');

			caxis([1 o.numClasses]);
			
			axis('auto');

		end


		function labels = predict(o,newPredictors)
			% classify new input not in training set

			assert(o.isTrained);
			assert(ismatrix(newPredictors));

			labels = o.classifier.predict(newPredictors(:,o.doUsePredictor));
		end
	end
	
	methods(Static)
		function err = calculateError(trueLabels,predictedLabels)
			assert(isvector(trueLabels) && isvector(predictedLabels));
			assert(length(trueLabels)==length(predictedLabels));
			assert(iscellstr(trueLabels) && iscellstr(predictedLabels)); %TODO: could add support for other label types (e.g. scalars)
			matches = cellfun(@isequal,trueLabels,predictedLabels);
			err = sum(~matches)/length(trueLabels);
		end
		
	end
end

function out = toDelete(x1,x2)
	c_saySingle('Size: %s, %s',c_toString(size(x1)),c_toString(size(x2)));
	out = x1+x2;
end