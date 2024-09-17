function Go=bci_ESI_CheckNormCalibration(bufferbci,flags)

v2struct(flags)

nargs=nargin;
if isequal(nargs,2)

%     Go=0;
    if isequal(fixnorm,1)
        Go=1;
    else

        if ismember(paradigm,[2:6,8])

            for i=dimused
                % IF AT LEAST ONE TRIAL IN EACH DIMENSION
                if sum(bufferbci.data.trialcount(i,:),2)>2 && sum(bufferbci.cs.trialcount(i,:),2)>2
                    Gotmp(i)=1;
                else
                    Gotmp(i)=0;
                end
            end
            
            if ismember(0,Gotmp(dimused))
                Go=0;
            else
                Go=1;
            end

        end

    end

    % NORMALIZER OFF - NO CALIBRATION TRIAL NEEDED
    if isequal(normonoff,0)
        for i=dimused
            Go=0;
            if ~isempty(bufferbci.data.trialcount(i,1)) && ~isempty(bufferbci.data.trialcount(i,2))
                Go=1;
            end
        end
    end

end


