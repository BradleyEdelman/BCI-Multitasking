function [Sig, f] = c_FFTSingleSided(sig,Ts,t0,Nf,dim)

if length(size(sig)) > 2
	error('signals of dimensionality greater than 2 not currently supported');
end

if nargin < 5
	%dim = c_findFirstNonsingletonDimension(sig);
	dim = c_findLargestDimension(sig);
end
Nt = size(sig,dim);

sig = shiftdim(sig,dim-1); % shift dim into 1st dimension

if nargin < 4
	Nf = 2^nextpow2(Nt);
end
if nargin < 3
	t0 = 0;
end

Fs = 1/Ts;

Sig = fft(sig,Nf,1)/Nt;

Sig = 2*Sig(1:Nf/2+1,:); % restrict to single side

Sig = shiftdim(Sig,length(size(sig))-(dim-1)); % shift dim back into original position

f = Fs/2*linspace(0,1,Nf/2+1);

end