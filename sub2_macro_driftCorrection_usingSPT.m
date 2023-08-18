%% 2023 update: use the median of multiple tracks (for noisy single-molecules)
% Find all TIF files in the folder and correct.
% 2022 Apr: read TrackMate xml file (now pick only one)
% updated from "qTGT_macro_driftCorrectionOnly.m"

%% Settings
if ~exist('path0', 'var') %check if path0 is in this workspace.
    path0 = 'E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023';
end
fXML2txt = true;               %Get one trajectory from a TrackMate xml file.
nChan=3;                       % TIF # of channel ex) two chan TIF
%magnification = 59.9078;       % Objective Mag.: ojb X tube 0.217 = 13/59.9078
magnification = 13;            % 13 when image/track scale is pixel: 13/13 = 1
%initial = 1;    %mcDriftCorrection2 can skip frames: initial, initial+i*interval

%% Chose tif files to run.
fSkipInput = false;
if exist('fByMasterMacro', 'var')
    if fByMasterMacro
        fSkipInput = true;
        nChan = master_nChan;    
    end
end
if fSkipInput
    disp('drift correction for tif files... (skip uigetfile)')
else
    cd(path0);
     [files,path]=uigetfile('*.tif','Select all files to analyze','MultiSelect','on');
    if ~iscell(files) % files is not a cell whne only one file is selected.
        files = {files};
    end
    nfiles = size(files,2);
end
cd(path)

for i=1:nfiles
    filename = files{i};
    [filepath,filenamehead,ext] = fileparts(filename);
    trjhead = filenamehead;
    filename = [filenamehead '.tif'];

    %% load tracks (Trackmate) and get the drift trace
    if fXML2txt
        %% xml file data to txt with one median trajectory (covering all frames)
        [tracks, info] = importTrackMateTracks([trjhead '_Tracks.xml']); %tracks{n}: t,x,y,z
        TrackCnt = size(tracks,1);

        % Check the length of each track
        LengthList = zeros(TrackCnt,1);
        for j=1:TrackCnt
            LengthList(j) = size(tracks{j},1);
        end
        MaxLength =  max(LengthList);
        MaxIDs = find(LengthList == MaxLength);
        cntLong = size(MaxIDs,1);
        x = nan(MaxLength, cntLong);
        y = nan(MaxLength, cntLong);
        for j=1:cntLong
            thisTrace = tracks{MaxIDs(j)};
            x(:,j) = thisTrace(:,2)-thisTrace(1,2); %set the first position zero.
            y(:,j) = thisTrace(:,3)-thisTrace(1,3);
        end
        TheTraceXY = [median(x,2) median(y,2)]; %TheTraceXY = [mean(x,2) mean(y,2)];

        save([trjhead '.txt'], 'TheTraceXY', '-ascii');
        if strcmp(info.spaceUnits,'pixel')
            magnification = 13; %distance=tempfactor*magnification/px_micron;
            disp('space unit is pixel. magnification is set to be 13.');
        end
    end

    %% correct the drift
    mcDriftCorrection(path, filenamehead, trjhead, nChan, magnification);
    %mcDriftCorrection2(path, filenamehead, trjhead, nChan, magnification, interval, initial);
    %mcDriftCorrection2023Apr(path, filenamehead, trjhead, nChan, magnification);

end



