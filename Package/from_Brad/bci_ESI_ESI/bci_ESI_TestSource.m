function [hObject,handles]=bci_ESI_TestSource(hObject,handles)


if ~isempty(handles.SYSTEM.Electrodes.current.eLoc)
    eLoc=handles.SYSTEM.Electrodes.current.eLoc;
    MaxChan=size(eLoc,2);
    TestPoints=str2num(get(handles.senspikes,'string'));
    TestData=zeros(MaxChan,1);
    TestData(TestPoints)=1;
else
    fprintf(2,'MUST SELECT EEG SYSTEM TO TEST SOURCE\n');
end

eegsystem=get(handles.eegsystem,'value');
switch eegsystem
    case 1 % None
    case {2,3,4,5,6}
        
        spatdomain=get(handles.spatdomain,'Value');
        switch spatdomain
            case 1 % None
            case 2 % Sensor
            case 3 % ESI
                
                % Check if necessary variables have been created
                if exist('eLoc','var') && ~isequal(sum(TestData),0)
                    
                    cortex=handles.ESI.cortex;
                    J=zeros(size(cortex.Vertices,1),1);
                    noise=handles.ESI.noisetype;
                    
                    parcellation=get(handles.parcellation,'value');
                    switch parcellation
                        case 1 % None
                    
                            switch noise
                                case {1,2} % None or no noise estimation

                                    INV=handles.ESI.NOCLUSTER.inv.nomodel;
                                    J=INV*TestData;
                                    J=abs(J);

                                case {3,4} % Diagonal or full 

                                    INVreal=handles.ESI.NOCLUSTER.inv.real;
                                    Jreal=INVreal*TestData;

                                    INVimag=handles.ESI.NOCLUSTER.inv.imag;
                                    Jimag=INVimag*TestData;

                                    J=complex(Jreal,Jimag);
                                    J=abs(J);

                            end
                            
                        case 2 % MSP
                            
                            clusters=handles.ESI.CLUSTER.clusters;
                            numcluster=size(clusters,2);
                            
                            switch noise
                                case {1,2} % None or no noise estimation
                                    
                                    INV=handles.ESI.CLUSTER.inv.nomodel;
                                    for i=1:numcluster
                                        J(clusters{i})=INV{i}*TestData;
                                    end
                                    J=abs(J);
                                    
                                    
                                case {3,4} % Diagonal or full 
                            
                                    INVreal=handles.ESI.CLUSTER.inv.real;
                                    INVimag=handles.ESI.CLUSTER.inv.imag;
                                    for i=1:numcluster
                                        Jreal(clusters{i})=INVreal{i}*TestData;
                                        Jimag(clusters{i})=INVimag{i}*TestData;
                                    end
                                    J=complex(Jreal,Jimag);
                                    J=abs(J);
                            end
                            
                        case 3 % K-means
                    end   
                          
%                     M=.15*max(J);
%                     J(J<M)=0;
                    
                    axes(handles.axes3); cla
                    set(handles.Axis3Label,'string','Test Source');
                    h=trisurf(cortex.Faces,cortex.Vertices(:,1),...
                        cortex.Vertices(:,2),cortex.Vertices(:,3),J);
                    set(h,'FaceColor','interp','EdgeColor','None','FaceLighting','gouraud'); 
                    axis auto; axis equal; axis off; view(-90,90)
                    colormap(jet(256)); caxis auto; rotate3d on
                    light; h2=light; lightangle(h2,90,-90); h3=light;lightangle(h3,-90,30);
                    
%                 cmap=jet(128); cmap=[repmat([.85 .85 .85],[10,1]);cmap]; colormap(cmap);
% %                 caxis([-.2 1]);
                    
                    axes(handles.axes2); cla; view(0,90)
                    topoplot(TestData,eLoc,'plotrad',.5,'electrodes','numbers');
                    set(gcf,'color',[.94 .94 .94])
                    set(handles.Axis2Label,'string','Test Source');
                end
        end
end

