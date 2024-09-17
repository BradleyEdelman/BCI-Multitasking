function lambdaWrapped = c_wrapToPi(lambda)
	% from http://stackoverflow.com/questions/28830207/prevent-matlab-from-wrapping-phase-angles-to-0-2pi-in-complex-numbers
   lambdaWrapped = lambda - floor(lambda / (2*pi)) * 2*pi;
   lambdaWrapped(lambdaWrapped > pi) = lambdaWrapped(lambdaWrapped > pi) - 2*pi;
end