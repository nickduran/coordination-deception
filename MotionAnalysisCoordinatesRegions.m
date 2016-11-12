%% CODE WRITTEN BY ... [TO BE ADDED IF PAPER IS ACCEPTED] AND USED IN PLOS ONE PAPER "SYNCHRONIZATION AND DECEPTION"

%% WHAT THIS PROGRAM DOES:

% 1. Takes as input all videos to be analyzed
% 2. Allows user to interactively mark mid screen and regions of interest for extracting motion energy flows ... 
% ... saves coordinates in data array structure to be used in MotionAnalysisGenerateFlow.m ... 

clear Points
close

CWD = '~vids/'; % folder with videos

tally = 0;
allfiles = dir('~vids/'); % folder with videos

%%
for k = 1:length(allfiles)

    af1 = struct2cell(allfiles(k));
    holdtemp = cell2mat(af1(1));
    disp(holdtemp)
    if (strcmp(holdtemp,'.') ~= 1) && (strcmp(holdtemp,'..') ~= 1) && (strcmp(holdtemp,'.DS_Store') ~= 1),
        tally = tally + 1;

        movLoc = strcat(CWD,holdtemp);

        LeftCount = 0;
        RightCount = 0;
        BothCount = 0;

        %%// get video information
        vidobj=VideoReader(movLoc);
        numFrames = get(vidobj,'NumberOfFrames');
        vidHeight = vidobj.Height;
        vidWidth = vidobj.Width;
        vidFrameRate = vidobj.FrameRate;
    %%          
        for m = 100, %%// select arbitrary point somwehere in video 

            mov1(1) = struct('cdata',zeros(vidHeight, vidWidth, 3, 'uint8'),'colormap',[]);
            mov1(1).cdata = read(vidobj,m);
            fig = figure(1);
            image(mov1(1).cdata);

            dcm_obj = datacursormode(fig);
            set(dcm_obj,'DisplayStyle','datatip',...
            'SnapToDataVertex','off','Enable','on')

            %%// interactive selection of x,y points on screen corresponding to regions of interest
            disp('Click MIDSCREEN X, then press ENTER ')
            pause
            midX = getCursorInfo(dcm_obj);
            midvalueX = midX.Position(1)

            disp('Click LEFT LEGS Y, then press ENTER ')
            pause
            lapLY = getCursorInfo(dcm_obj);
            legsYLEFT = lapLY.Position(2)

            disp('Click LEFT HEAD Y, then press ENTER ')
            pause
            headLY = getCursorInfo(dcm_obj);
            headYLEFT = headLY.Position(2)     

            disp('Click RIGHT LEGS Y, then press ENTER ')
            pause
            lapRY = getCursorInfo(dcm_obj);
            legsYRIGHT = lapRY.Position(2)    

            disp('Click RIGHT HEAD Y, then press ENTER ')
            pause
            headRY = getCursorInfo(dcm_obj);
            headYRIGHT = headRY.Position(2)        

            %%// for each dyad, save x.y coordinates for regions of interest in the data structure "Points" 
            dyadnum = strsplit(holdtemp,'_');
            ordernum = strsplit(cell2mat(dyadnum(2)),'.');
            Points.coord(tally,:) = [str2num(cell2mat(dyadnum(1))), str2num(cell2mat(ordernum(1))), midvalueX , legsYLEFT, headYLEFT, legsYRIGHT, headYRIGHT];
            close
        end
    clear mov1(1).cdata  
    close
    end
end
save('~/pointsmarkedRegions','Points')     
   

