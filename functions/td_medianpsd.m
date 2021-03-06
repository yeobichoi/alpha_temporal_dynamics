function p = td_medianpsd(eeg, windowLength, windowOverlap,frequencyLimits)
% Calculates log10 power spectral density using the median values of
% a Hanning-tapered short-time Fast Fourier Transform ("median Welch").
% PSD is obtained bydividing power by the ENBW of the Hann window.
%
% INPUTS
% - eeg: FieldTrip raw data structure
% - windowLength: length of slinding window in seconds (default = 2)
% - windowOverlap: overlap of slinding windows as a proportion between 0,1 
%   (default = 0.5)
% - frequencyLimits: two-element vector, lower and upper bound of frequency
%   range (default = [2 24])
%
% OUTPUTS
% - PSD in FieldTrip "freq" data format
%
% DEPENDENCIES
% - FieldTrip
%
% USAGE
% >>  psd = td_medianpsd(eeg_clean,2,0.5,[2 24]);
%
%--------------------------------------------------------------------------
% (c) Eugenio Abela, MD / Richardson Lab
%
% Version history:
%
% 19/01/13 Corrected error in PSD scaling
% 19/01/12 Added description, improved readability
% 18/11/09 Initial version


%% Check inputs
%==========================================================================
if nargin < 1
    error('No data!');
elseif nargin <2
    windowLength    = 2;
    windowOverlap   = 0.5;
    frequencyLimits = [2 24];
end

%% Calculate short-time Fast Fourier Transform
%==========================================================================
% Obtain "sliding windows" in FieldTrip. Effectively, cut a continous
% data set into overlapping segments.
cfg         = [];
cfg.length  = windowLength;
cfg.overlap = windowOverlap;
seg         = ft_redefinetrial(cfg, eeg);

% Define frequencies of interest (foi)
foi = frequencyLimits(1):1/windowLength:frequencyLimits(2); 

% Calculate power using single Hanning taper. Remove linear trend, and pad
% to next power of two.
cfg             = [];
cfg.output      = 'pow';
cfg.method      = 'mtmfft';  
cfg.taper       = 'hanning';  
cfg.foi         = foi;   
cfg.polyremoval = 0;         
cfg.pad         = 'nextpow2'; 
cfg.keeptrials  = 'yes';       
tmp = ft_freqanalysis(cfg, seg);

%% Obtain power spectral density over channels
%==========================================================================
% Prepare basic loop parameters
nChan = length(seg.label);
nFoi  = length(cfg.foi);

% Preallocate output matrix
psd   = zeros(nChan, nFoi);

% Calculate equivalent noise bandwidth of a single Hanning taper with
% length "windowLength" and sampling rate eeg.fsample.
bw  = enbw(hann(windowLength), eeg.fsample);

% Loop over channels
for chani = 1:nChan
    
    % Take median over windows ('trials') to mitigate influence of
    % outliers. This is colloqiually referred to as "median Welch".
    tmppow       = squeeze(median(tmp.powspctrm(:,chani,:),1));  
    
    % Divide by equivalent noise bandwidth and take log10 to convert power
    % to PSD.
    psd(chani,:) = log10(tmppow/bw);
    
end

%% Save Output
%==========================================================================
% Organise results as a FieldTrip "freq" data structure
p           = struct();
p.dimord    = 'chan_freq';
p.powspctrm = psd;
p.label     = tmp.label;
p.freq      = tmp.freq;
p.cfg       = tmp.cfg;
%% END
