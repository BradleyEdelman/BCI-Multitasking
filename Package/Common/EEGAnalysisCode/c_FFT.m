function [Sig, f] = c_FFT(sig,Ts,t0,Nf,dim)

if nargin < 5
	%dim = c_findFirstNonsingletonDimension(sig);
	dim = c_findLargestDimension(sig);
end
Nt = size(sig,dim);
if nargin < 4
	Nf = 2^nextpow2(Nt);
end
if nargin < 3
	t0 = 0;
end

Fs = 1/Ts;

Sig = fft(sig,Nf,dim)/Nt;

f = Fs/2*linspace(0,2,Nf); %TODO: double check this is correct

end