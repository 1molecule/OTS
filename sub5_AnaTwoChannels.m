%% Get tracks of spots on two color channels using ImageJ TrackMate
% MJ - 2023 Mar
% https://imagej.net/ij/developer/api/ij/ij/ImagePlus.html

%% Run ImageJ instance
% ImageJ-Matlab plugin is required: https://imagej.net/plugins/trackmate/scripting/using-from-matlab
% addpath(E:\OneDrive - Johns Hopkins\fiji\Fiji.app\scripts);
%clearvars -except IJM
% if ~exist('IJM')
%     ImageJ % it only works sometimes... ? Enter "ImageJ" to prompt.
% end

% clear
%ImageJ
%fCloseImageJ = true;

%% path for data
path0 = 'E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023';

%% Settings for spot detection and linking
targetChan1 = 2;         % 
criThreshold1 = 70.0;    % 50 for 200ms/EM-filter
targetChan2 = 3;         % 
criThreshold2 = 30.0;    % 20 for 200ms/EM-filter

spotRADIUS_both = 2.5;
criLinkingMaxDistance_both = 1;
criGapClosingMaxDistance_both = 0.6;
criMaxFrameGap_both = 5;
fFilterDisplacement_both = false;
criFilterDispalcement_both = 1.5;
fFilterDuration_both = true;
criFilterDuration_both = 0;
fTrackStart = true;
criTrackStart = 1;      %time or frame???


%% import ImageJ/TrackMate functions
import java.lang.Integer
import ij.IJ
import ij.WindowManager
import fiji.plugin.trackmate.TrackMate
import fiji.plugin.trackmate.Model
import fiji.plugin.trackmate.Settings
import fiji.plugin.trackmate.SelectionModel
import fiji.plugin.trackmate.Logger
import fiji.plugin.trackmate.features.FeatureFilter
import fiji.plugin.trackmate.detection.LogDetectorFactory
import fiji.plugin.trackmate.tracking.jaqaman.SparseLAPTrackerFactory
import fiji.plugin.trackmate.tracking.jaqaman.LAPUtils
import fiji.plugin.trackmate.gui.displaysettings.DisplaySettingsIO
import fiji.plugin.trackmate.gui.displaysettings.DisplaySettings
import fiji.plugin.trackmate.visualization.hyperstack.HyperStackDisplayer
import java.io.File
import fiji.plugin.trackmate.io.TmXmlWriter
import fiji.plugin.trackmate.action.ExportTracksToXML %as ExportTracksToXML


%% select multiple files
fSkipInput = false;
filenameTag = [];
if exist('fByMasterMacro', 'var')
    if fByMasterMacro
        fSkipInput = true;
        filenameTag = '_drftc_reg';
        spotRADIUS_both = master_spotRADIUS_both;
        targetChan1 = master_targetChan1;         
        criThreshold1 = master_criThreshold1;    
        targetChan2 = master_targetChan2;         
        criThreshold2 = master_criThreshold2;    
        criFilterDispalcement_both = master_criFilterDispalcement_both;
    end
end
if fSkipInput
    disp('analzye two channels of each TIF file.. (skip uigetfile)')
else
    cd(path0);
    [files,path]=uigetfile('*.tif','Select all files to analyze','MultiSelect','on');
    cd(path)
    if ~iscell(files) % files is not a cell whne only one file is selected.
        files = {files};
    end
    nfiles = size(files,2);
end

for i=1:nfiles
    %path = 'E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023\230324_THP1_LDVPdp2036test\ana';
    filename = files{i};
    [filepath,filenamehead,ext] = fileparts(filename);
    %filenamehead = [filenamehead filenameTag];
    filename = [filenamehead filenameTag '.tif']; 
    saveFilename1 = [filenamehead filenameTag '_g.xml'];
    saveFilename2 = [filenamehead filenameTag '_r.xml'];

    %% open one image
    fullFilename = fullfile(path, filename);
    imp = IJ.openImage(fullFilename);
    imp.show()
    cal = imp.getCalibration();

    %% Check and reset the iamge stack dimension 
    dims = imp.getDimensions(); 
    if dims(4)>1 && dims(5)==1
        disp('Dimensionality was reset: XYCTZ to XYCZT')
        imp.setDimensions(dims(3), dims(5), dims(4));
    end
    

    %% TrackMate analysis for green (high force)
    disp('analyze the higher force chanel')
    targetChan = targetChan1;         % color channel depedent!
    spotRADIUS = spotRADIUS_both;
    criThreshold = criThreshold1;    % color channel depedent!
    fSubpixel = true;
    fMedianFilter = false;
    fFilterQaulity = true;
    criFilterQaulity = 0.0;
    criLinkingMaxDistance = criLinkingMaxDistance_both;
    criGapClosingMaxDistance = criGapClosingMaxDistance_both;
    criMaxFrameGap = criMaxFrameGap_both;
    fSplitting= false;
    fMerging = false;
    fFilterDisplacement = fFilterDisplacement_both;
    criFilterDispalcement = criFilterDispalcement_both;
    fFilterDuration = fFilterDuration_both;
    criFilterDuration = criFilterDuration_both; %This is a unit of time, not frame

    % set & run TrackMate - subMacro_setNrunTrackMate.m shold be in a same folder
    model = Model();                        % Create the model object now
    model.setLogger( Logger.IJ_LOGGER );    % Send all messages to ImageJ log window.
    model.setPhysicalUnits(cal.getUnit(), cal.getTimeUnit()) %% update the time unit

    settings = Settings(imp);               % Prepare settings object
    settings.detectorFactory = LogDetectorFactory();
    map = java.util.HashMap();
    map.put('DO_SUBPIXEL_LOCALIZATION', fSubpixel);
    map.put('RADIUS', spotRADIUS);
    map.put('TARGET_CHANNEL', Integer.valueOf(targetChan)); % Needs to be an integer, otherwise TrackMate complaints.
    map.put('THRESHOLD', criThreshold);
    map.put('DO_MEDIAN_FILTERING', fMedianFilter);
    settings.detectorSettings = map;

    filter1 = FeatureFilter('QUALITY', criFilterQaulity, fFilterQaulity);
    settings.addSpotFilter(filter1)

    % Configure tracker
    settings.trackerFactory  = SparseLAPTrackerFactory();
    settings.trackerSettings = settings.trackerFactory.getDefaultSettings(); % almost good enough
    settings.trackerSettings.put('MAX_FRAME_GAP', Integer.valueOf(criMaxFrameGap));
    settings.trackerSettings.put('LINKING_MAX_DISTANCE', criLinkingMaxDistance);
    settings.trackerSettings.put('GAP_CLOSING_MAX_DISTANCE', criGapClosingMaxDistance);
    settings.trackerSettings.put('ALLOW_TRACK_SPLITTING', fSplitting);
    settings.trackerSettings.put('ALLOW_TRACK_MERGING', fMerging);

    % Add all analyzers
    settings.addAllAnalyzers()

    % Configure track filters
    filter2 = FeatureFilter('TRACK_DISPLACEMENT', criFilterDispalcement, fFilterDisplacement);
    settings.addTrackFilter(filter2)
    filter3 = FeatureFilter('TRACK_DURATION', criFilterDuration, fFilterDuration);
    settings.addTrackFilter(filter3);
    filter4 = FeatureFilter('TRACK_START', criTrackStart, fTrackStart);
    settings.addTrackFilter(filter4);

    
    % Run TrackMate
    trackmate = TrackMate(model, settings);
    ok = trackmate.checkInput();
    if ~ok
        display(trackmate.getErrorMessage())
    end

    ok = trackmate.process();
    if ~ok
        display(trackmate.getErrorMessage())
    end

    % Display results
    % ds = DisplaySettingsIO.readUserDefault(); % Read the user default display setttings.   
    % ds.setLineThickness(1.) % Big lines.
    % selectionModel = SelectionModel( model );
    % displayer = HyperStackDisplayer( model, selectionModel, imp, ds );
    % displayer.render()
    % displayer.refresh()

    % Echo results
    %display( model.toString() )

    % Save the result
    outFile = File(path, saveFilename1);
    fiji.plugin.trackmate.action.ExportTracksToXML.export(model, settings, outFile);


    %% TrackMate analysis for red (low force)
    disp('analyze the lower force chanel')
    targetChan = targetChan2;         % color channel depedent!
    criThreshold = criThreshold2;    % color channel depedent!

    clear Model settings trackmate

    % set & run TrackMate - subMacro_setNrunTrackMate.m shold be in a same folder
    model = Model();                        % Create the model object now
    model.setLogger( Logger.IJ_LOGGER );    % Send all messages to ImageJ log window.
    model.setPhysicalUnits(cal.getUnit(), cal.getTimeUnit()) %% update the time unit

    settings = Settings(imp);               % Prepare settings object
    settings.detectorFactory = LogDetectorFactory();
    map = java.util.HashMap();
    map.put('DO_SUBPIXEL_LOCALIZATION', fSubpixel);
    map.put('RADIUS', spotRADIUS);
    map.put('TARGET_CHANNEL', Integer.valueOf(targetChan)); % Needs to be an integer, otherwise TrackMate complaints.
    map.put('THRESHOLD', criThreshold);
    map.put('DO_MEDIAN_FILTERING', fMedianFilter);
    settings.detectorSettings = map;

    filter1 = FeatureFilter('QUALITY', criFilterQaulity, fFilterQaulity);
    settings.addSpotFilter(filter1)

    % Configure tracker
    settings.trackerFactory  = SparseLAPTrackerFactory();
    settings.trackerSettings = settings.trackerFactory.getDefaultSettings(); % almost good enough
    settings.trackerSettings.put('MAX_FRAME_GAP', Integer.valueOf(criMaxFrameGap));
    settings.trackerSettings.put('LINKING_MAX_DISTANCE', criLinkingMaxDistance);
    settings.trackerSettings.put('GAP_CLOSING_MAX_DISTANCE', criGapClosingMaxDistance);
    settings.trackerSettings.put('ALLOW_TRACK_SPLITTING', fSplitting);
    settings.trackerSettings.put('ALLOW_TRACK_MERGING', fMerging);

    % Add all analyzers
    settings.addAllAnalyzers()

    % Configure track filters
    filter2 = FeatureFilter('TRACK_DISPLACEMENT', criFilterDispalcement, fFilterDisplacement);
    settings.addTrackFilter(filter2)
    filter3 = FeatureFilter('TRACK_DURATION', criFilterDuration, fFilterDuration);
    settings.addTrackFilter(filter3);
    filter4 = FeatureFilter('TRACK_START', criTrackStart, fTrackStart);
    settings.addTrackFilter(filter4);


    % Run TrackMate
    trackmate = TrackMate(model, settings);
    ok = trackmate.checkInput();
    if ~ok
        display(trackmate.getErrorMessage())
    end

    ok = trackmate.process();
    if ~ok
        display(trackmate.getErrorMessage())
    end

    %Display results
    % ds = DisplaySettingsIO.readUserDefault(); % Read the user default display setttings.   
    % ds.setLineThickness(1.) % Big lines.
    % selectionModel = SelectionModel( model );
    % displayer = HyperStackDisplayer( model, selectionModel, imp, ds );
    % displayer.render()
    % displayer.refresh()

    % Echo results
    %display( model.toString() )

    % Save the result
    outFile = File(path, saveFilename2);
    fiji.plugin.trackmate.action.ExportTracksToXML.export(model, settings, outFile);
    
    % close this image file
    imp.close

end
% Quite the ImageJ instance
% if fCloseImageJ
%     ij.IJ.run("Quit","")
% end


