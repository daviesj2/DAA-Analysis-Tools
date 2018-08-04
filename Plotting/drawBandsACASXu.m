function[figures,frames]=drawBandsACASXu(messages,plotAll,OwnshipState,IntruderState)
%   Plots horizontal guidance bands provided from AcasXu LVC messages.
% 
%   Name: plotDAAbandsAcasXu.m [Function]   
%
%   INPUT: 
%       messages        [struct]: LVC message structure from getLVC().m
%       plotAll         [bool]: Plot all provided messages or up to 5
%       OwnshipState    [struct]: State structure of ownship
%       IntruderState   [struct]: State structure of intruder(s)
%
%   OUTPUT:
%       figures [fig/cdata]: Vector of figure handles or color frames of generated plots
%
%   NOTES:
%       Figures are embedded with UTC time of applicability in h.UserData
%       as [1x1 double]
%
% Jason T. Davies (ARC-AFT)[UNIVERSITIES SPACE RESEARCH ASSOCIATION]
% September 13, 2017

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%GRAPHICS OPTIONS%%%
tailLength = 100;
drawFrames = true;

%Band colors in vector format
colorCLEAR  = [0 0 0];   %black
colorRWC    = [1 0.5 0]; %orange
colorCA     = [1 0 0];   %red

ownshipMarkerSize = 120; %Size of ownship marker

bandWeight  = 45;        %Weight of alert bands
bandsRadius = 0.8;       %TrkBands distance from ownship
%%%%%%%%%%%%%%%%%%%%%%%


if ~exist('plotAll','var'), plotAll = false; end

if exist('OwnshipState','var') && exist('IntruderState','var')
    drawOwnship = true;
else
    drawOwnship = false;
end

AcasXu = messages(strcmpi({messages.Name},'AcasXu')); %Make sure we only have ACAS messages

times = [AcasXu.Data];
times = [times.m_timeOfApplicability]; %Sort by time of applicability
[~, Idx] = sort(times);
AcasXu = AcasXu(Idx);
for i=1:length(AcasXu)   
    AcasXu(i).time = times(i);
end
times = [AcasXu.time];

clear messages Idx;

if length(AcasXu) > 5 && ~plotAll
    AcasXu=AcasXu(1:5);
end
    
theta = (-80:10:80)*(pi/180);
figures(length(AcasXu))=figure('Visible','off');
close(figures(end));

if plotAll, fprintf('Drawing %d frames...',length(AcasXu)); end
parfor i =1:length(AcasXu)
    
    if exist('OwnshipState','var')
        offset = OwnshipState(ismember([OwnshipState.time],times)).track;
    else
        offset = 0;
    end
    
    CA = AcasXu(i).Data.m_preventiveCABands(2:18);
    RWC = AcasXu(i).Data.m_preventiveRWCBands(2:18);
    RWCBandsTheta=theta(RWC);
    CABandsTheta=theta(CA);
    ClearBandsTheta = theta(~(CA|RWC));
    
    
    if plotAll, visible = 'off'; else, visible = 'on'; end
    figures(i)=figure('Visible',visible);
    PAX(i) = polaraxes('ThetaDir','clockwise','ThetaZeroLocation','Top','RTick',[],'ThetaTick',[0 10:10:80 100 260 280:10:350],'ThetaTickLabel',[{'0' '10' '20' '30' '40' '50' '60' '70' '80' '+'} {'-' '-80' '-70' '-60' '-50' '-40' '-30' '-20' '-10'}]);
    hold(PAX(i),'on');
    
    figures(i).Tag='AcasXuDAA';
    
    polarscatter(PAX(i),ClearBandsTheta,repmat(bandsRadius,1,length(ClearBandsTheta)),'o','SizeData',bandWeight,'MarkerEdgeColor','k','MarkerFaceColor',colorCLEAR)
    polarscatter(PAX(i),RWCBandsTheta,repmat(bandsRadius,1,length(RWCBandsTheta)),'o','SizeData',bandWeight,'MarkerEdgeColor','k','MarkerFaceColor',colorRWC)
    polarscatter(PAX(i),CABandsTheta,repmat(bandsRadius,1,length(CABandsTheta)),'o','SizeData',bandWeight,'MarkerEdgeColor','k','MarkerFaceColor',colorCA)
    polarscatter(0,0,'^k','SizeData',ownshipMarkerSize,'MarkerFaceColor',[0 0 0]);
    
    if AcasXu(i).Data.m_preventiveCABands(1)
        polarplot(PAX(i),(180:270)*(pi/180),ones(1,91)*bandsRadius,'Color',colorCA,'LineWidth',bandWeight/10)
    elseif AcasXu(i).Data.m_preventiveRWCBands(1)
        polarplot(PAX(i),(180:270)*(pi/180),ones(1,91)*bandsRadius,'Color',colorRWC,'LineWidth',bandWeight/10)
    else
        polarplot(PAX(i),(180:270)*(pi/180),ones(1,91)*bandsRadius,'Color',colorCLEAR,'LineWidth',bandWeight/10)
    end
        
    if AcasXu(i).Data.m_preventiveCABands(19)
        polarplot(PAX(i),(90:180)*(pi/180),ones(1,91)*bandsRadius,'Color',colorCA,'LineWidth',bandWeight/10)
    elseif AcasXu(i).Data.m_preventiveRWCBands(19)
        polarplot(PAX(i),(90:180)*(pi/180),ones(1,91)*bandsRadius,'Color',colorRWC,'LineWidth',bandWeight/10)
    else
        polarplot(PAX(i),(90:180)*(pi/180),ones(1,91)*bandsRadius,'Color',colorCLEAR,'LineWidth',bandWeight/10)
    end
    
    grid on;
    
    text(0,-0.1,AcasXu(i).Data.m_ownshipCallsign,'HorizontalAlignment','center')
    
    if AcasXu(i).Data.m_advisoryHeading == 0 %Dubious
        headingAdvisory = 'NONE';
    else
        polarplot([0 (AcasXu(i).Data.m_advisoryHeading-offset)*pi/180],[0 1],'Color',[0 0.68 0.12],'LineWidth',1.5)
        headingAdvisory = num2str(AcasXu(i).Data.m_advisoryHeading-offset,'%.1f');
    end
    
    text(0,-0.175,sprintf('Advised Heading: %s',headingAdvisory),'HorizontalAlignment','center')
    
    switch AcasXu(i).Data.m_enumCombinedControl
        case 1
            HAdvise = 'Advisory Cleared';
            Hcolor = [0 0.75 1];
        case 4
            HAdvise = 'Avoid Collision: Increase Heading';
            Hcolor = [1 0 0];
        case 5
            HAdvise = 'Avoid Collision: Decrease Heading';
            Hcolor = [1 0 0];
        case 6
            HAdvise = 'Remain Well Clear: Increase Heading';
            Hcolor = [1 0.5 0];
        case 7
            HAdvise = 'Remain Well Clear: Decrease Heading';
            Hcolor = [1 0.5 0];
        otherwise
            HAdvise = 'No Advisory';
            Hcolor = [0 0 0];
    end
    
    text(0,-0.25,HAdvise,'HorizontalAlignment','center','Color',Hcolor)

    text(0,-1.1,['Time: ' num2str(AcasXu(i).Data.m_timeOfApplicability) ' UTC'],'HorizontalAlignment','center')
    title(['ACAS-Xu DAA Message ' 'UTC: ' num2str(AcasXu(i).Data.m_timeOfApplicability)])
    rlim([0 1])
    
    figures(i).UserData = AcasXu(i).time;
    
    
    if drawOwnship
        
        figures(i).Units = 'pixels';
        kids = get(figures(i),'Children');
        set(kids,'Units','pixels');
        PAX(i).Position = [67.56 43.24 396.8 308.21];
        pos = figures(i).Position;
        figures(i).Position = [1151 286 512 684];
        
        thisOwnshipState = OwnshipState([OwnshipState.time] == AcasXu(i).time);
        thisOwnshipState=thisOwnshipState(1);
        thisIntruderState = IntruderState([IntruderState.time] == AcasXu(i).time);
        
        if i>tailLength && tailLength>0
            times = [AcasXu(i-tailLength:i-1).time];

            oldOwnshipState = OwnshipState(ismember([OwnshipState.time],times));
            oldIntruderState = IntruderState(ismember([IntruderState.time],times));
           
        else
            times = [AcasXu(1:i).time];
            
            oldOwnshipState = OwnshipState(ismember([OwnshipState.time],times));
            oldIntruderState = IntruderState(ismember([IntruderState.time],times));
        end
        
        
        
        XYax = axes(figures(i),'Units','pixels','Position',[50 430 438 230]);
        hold(XYax,'on');
        drawKinematics(XYax,thisOwnshipState,thisIntruderState,oldOwnshipState,oldIntruderState);
    end
    
end


if drawFrames
    fprintf('Done.\n')
    fprintf('Processing frames...');
    frames(length(figures))=getframe;
    parfor i = 1:length(figures)
        frameData = getframe(figures(i));
        frames(i) = frameData;
    end
    fprintf('Done.');
end

end
