function [bufferbci,varargout]=bci_ESI_Buffer(action,bufferbci,varargin)


nargs=nargin;
if nargs<2
else
    
    %% EXTRACT INPUT ARGS
    if ~(round((nargs-2)/2) == (nargs-2)/2)
        error('Odd number of input arguments??')
    end
    
    str=cell(0); val=cell(0);
    for i=1:2:length(varargin)
        str{end+1}=varargin{i};
        val{end+1}=varargin{i+1};
    end
    
    if ismember('trial',str)
        trial=val{strcmp(str,'trial')};
    else
        error('Need trial structure to use buffer\n');
    end
        
    if ismember('signal',str)
        signal=val{strcmp(str,'signal')};
    else
        error('Need signal type to use buffer\n');
    end
    
    if ismember('event',str)
        event=val{strcmp(str,'event')};
    else
        error('Need event structure to use buffer\n');
    end
    
    if ismember('flags',str)
        flags=val{strcmp(str,'flags')};
    else
        error('Need flags to normalize control signal\n');
    end
    v2struct(flags)
    v2struct(trial.(signal))

    if strcmp(action,'store')
        %% STORE DATA IN BUFFERS
        
        if ismember('data',str)
            data=val{strcmp(str,'data')};
        else
            error('Data needed to store in buffer\n');
        end
        
        if ismember('control',str)
            control=val{strcmp(str,'control')};
        else
            error('Control signal needed to store in buffer\n');
        end
        
        storage=struct('dim',[],'targidx',[],'limit',[],'data',[],'datatype',[],'buffertype',[],'win',[]);
        currentwindow=cell(3,1);
        for i=dimused
            storage.dim=i;

            % Is target in the dimension of interest
            if ismember(event.target,targetid{i})

                targetididx=(targetid{i}==event.target);
                storage.targidx=targetididx;
                storage.win=trial.SMR.trialwin(i,targetididx);

                currentwindow{i}=data{i};

                % STORE CURRENT DATA VECTOR IN TRIAL BUFFER
                storage.data=currentwindow{i}; storage.datatype='data'; storage.buffertype='trial'; storage.limit=bufferlength;
                bufferbci.storage=storage;
                bufferbci=bci_ESI_ModBuffer('store',bufferbci);

                % STORE CURRENT CONTROL SIGNAL IN TRIAL BUFFER
                storage.data=control.raw(i,end); storage.datatype='cs'; 
                bufferbci.storage=storage;
                bufferbci=bci_ESI_ModBuffer('store',bufferbci);

                % STORE CURRENT DATA VECTOR IN WINDOW BUFFER
                storage.data=currentwindow{i}; storage.datatype='data'; storage.buffertype='window'; storage.limit=30*bufferlength;
                bufferbci.storage=storage;
                bufferbci=bci_ESI_ModBuffer('store',bufferbci);

                % STORE CURRENT CONTROL SIGNAL IN WINDOW BUFFER
                storage.data=control.raw(i,end); storage.datatype='cs';
                bufferbci.storage=storage;
                bufferbci=bci_ESI_ModBuffer('store',bufferbci);

                trial.SMR.trialwin(i,targetididx)=trial.SMR.trialwin(i,targetididx)+1;

            end

        end
        varargout{1}=trial;
                            
    elseif strcmp(action,'update')
        %% UPDATE BFUFERS AT END OF TRIAL/CYCLE
        
        if ismember('bci',str)
            bci=val{strcmp(str,'bci')};
        else
            error('Need bci structure to update buffer\n');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % END OF TRIAL - UPDATE BUFFER
        storage=struct('dim',[],'targidx',[],'limit',[],'data',[],'datatype',[],'buffertype',[],'win',[]);
        for i=dimused
            storage.dim=i;

            if ismember(event.target,targetid{i})

                targetididx=(targetid{i}==event.target);
                storage.targidx=targetididx;

                bufferbci.storage.datatype='cs';
                bufferbci=bci_ESI_ModBuffer('update',bufferbci,'updatecount',[i targetididx]);
                bufferbci.storage.datatype='data';
                bufferbci=bci_ESI_ModBuffer('update',bufferbci,'updatecount',[i targetididx]);

            end

        end
                            
        % UPDATE CLASSIFIER WEIGHTS (AND OFFSET)
        for i=dimused
            if ~isempty(bufferbci.data.window{i,1}) && ~isempty(bufferbci.data.window{i,2}) &&...
                    isequal(decodeadapt,3)
                switch feattype
                    case 'Regress'
                    case {'RLDA','PCA'}
% 
%                         if strcmp(label(i),'One-vs-One')
                            tic
                            [bci.SMR.offset{i},bci.SMR.weight{i},PC(:,:,i)]=...
                                RLDA(bufferbci.data.window{i,1}',...
                                bufferbci.data.window{i,2}',bci.SMR.lambda{i});
                            toc
                            bci.SMR.offset(1)

%                             Dat.weight{win}=bci.weight;
%                             Dat.offset{win}=bci.offset;
%                             updatewin=[updatewin win];
% 
%                         elseif strcmp(label(i),'One-vs-Rest')
% 
%                             for j=1:2
%                                 [bci.offset{i}(j),bci.weight{i}(:,j),PC(:,:,i,j)]=...
%                                     RLDA(datawindows{i,j}',...
%                                     basedata{i}',bci.lambda{i});
%                             end
% 
%                             updatewin=[updatewin win];

%                         elseif strcmp(label(i),'One-vs-All')
%                         end

                    case 'FDA'

                    case 'Mahal'
                end
            end
        end

        targetididx=(targetid{i}==event.target);
        trial.SMR.trialwin(i,targetididx)=1;
        trial.SMR.tottrial=tottrial+1;
%         basedata=cell(3,1);
        varargout{1}=trial;
        varargout{2}=bci;
    end
end

    
function [W0,W,PC]=RLDA(X1,X2,lambda)

    X1mean=mean(X1,1);
    X2mean=mean(X2,1);

    n1=size(X1,1);
    n2=size(X2,1);

    pp1=n1/(n1+n2);
    pp2=n2/(n1+n2);

    X1=X1-repmat(X1mean,[n1,1]);
    X2=X2-repmat(X2mean,[n2,1]);
    
    X1cov=1/(n1-1)*(X1'*X1);
    X2cov=1/(n2-1)*(X2'*X2);
    
    PC=(n1*X1cov+n2*X2cov)/(n1+n2);

    % Regularize
    D=(trace(PC)/size(PC,1))*eye(size(PC));
    PC=(1-lambda)*PC+lambda*D;
    
    W0=log(pp2/pp1)-.5*(X2mean-X1mean)/(PC)*(X2mean+X1mean)';
    W=(X2mean-X1mean)/(PC);
    W=W(:);    
    
    