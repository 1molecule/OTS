%% Master macro for OTS2 spot analysis 
% Use the result and 'M_PTS2_ana....m' for the time delay analysis

%% How to run
% Enter this to start an instance before run: ImageJ
% Enter this to close the instance: ij.IJ.run("Quit","")
% add this path: "~~~ fiji\Fiji.app\scripts"
% It is for 3-channel image stcks (RICM/green/red)

%% working
% get and save frame interval
% get the num of frame and auto set criFilterDuration.

%% Settings
fByMasterMacro = true;
path0 = 'E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023';
master_nChan = 4;
switch master_nChan
    case 3
        % 3ch for THP1 (2.5s without EM filter)
        % master_nChan = 3;
        master_drift_targetChan = 3;
        master_drift_criThreshold = 20.0;
        master_spotRADIUS_both = 2.5;
        master_targetChan1 = 2;
        master_criThreshold1 = 150.0;    %70.0 wo filter?, 50.0 w filter
        master_targetChan2 = 3;
        master_criThreshold2 = 60.0;    %30.0 wo filter?, 20.0 w fitler
        master_criFilterDispalcement_both = 1.0;
        tformFilefull='E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023\chromaticErr\tform230414.mat'; % wo em filter
        %tformFilefull='E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023\chromaticErr\tform230214.mat'; % w/ em filter
    case 4
        % 4ch for U2OSpg (5s with EM filter)
        % master_nChan = 4;
        master_drift_targetChan = 4;
        master_drift_criThreshold = 20.0;
        master_spotRADIUS_both = 2.5;
        master_targetChan1 = 3;
        master_criThreshold1 = 100.0;    %150.0 wo filter?, 100.0 w filter
        master_targetChan2 = 4;
        master_criThreshold2 = 25.0;    %60.0 wo filter?, 25.0 w fitler
        master_criFilterDispalcement_both = 1.0;
        tformFilefull='E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023\chromaticErr\tform230414.mat'; % wo em filter
        %tformFilefull='E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023\chromaticErr\tform230214.mat'; % w/ em filter
end



%% select multiple .ND2 files
cd(path0);
% [files,path]=uigetfile('*.nd2','Select all files to analyze','MultiSelect','on');
% if ~iscell(files) % files is not a cell whne only one file is selected.
%     files = {files};
% end
% nfiles = size(files,2);
[nd2files, path]=uigetfile('*.nd2','Select all files to analyze','MultiSelect','on');
if ~iscell(nd2files) % files is not a cell whne only one file is selected.
    nd2files = {nd2files};
end
fileCnt = size(nd2files,2);
cd(path)

macroStart = tic;
for fi = 1:fileCnt 
    % one by one, pass a cell with only one file.
    macroStartEach = tic;
    files{1} = nd2files(fi);
    nfiles = size(files,2);

    % Get/save tracks of spots for drift correction. Save image as Tif.
    sub1_RunTrackMate_for_drift_correction


    % Drift correction
    sub2_macro_driftCorrection_usingSPT
    % the TIF files are saved without some meta data


    % Chromatic error correction
    sub3_macro_ChromaticErrorReg_DoRegisration
    % the TIF files are saved without some meta data


    % Merge the corrected channels + update the image Info & properties
    sub4_CombineImages_using_ImageJ

    % analyze spots in two channel.
    sub5_AnaTwoChannels
    
    % show the elapsed time for this loop.
    fprintf('### OTS2 analysis was done for %d of %d (%.1f s)\n', fi, fileCnt, toc(macroStartEach));
end

%% The End
disp('##### OTS2 analysis was done for all file #####')
toc(macroStart)
fclose all;
cd(path0)
