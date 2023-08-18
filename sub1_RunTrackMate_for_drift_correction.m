% Analysis of OTS2 using ImageJ in MATALB - MJ 230323
% See the refernces below
% imagej.net/plugins/trackmate/scripting/using-from-matlab
% imagej.net/scripting/matlab#adding-imagej-to-the-matlab-classpath
%--
% https://imagej.net/ij/developer/api/ij/ij/ImagePlus.html

%% Start "ImageJ" instance!
%ImageJ    %ImageJ(false)? restart MATLAB if error msg comes out... how to close?
% ij.IJ.run("Quit",""); %Quit the ImageJ instance from MATLAB command line
%clear
%ImageJ

%% path Settings
if ~exist('path0', 'var') %check if path0 is in this workspace.
    path0 = 'E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023';
end

%% TrackMate Settings
targetChan = 3;
spotRADIUS = 2.5;
criThreshold = 20.0;
fSubpixel = true;
fMedianFilter = false;

fFilterQaulity = true;
criFilterQaulity = 0.0;

criLinkingMaxDistance = 1.0;
criGapClosingMaxDistance = 1.0;
criMaxFrameGap = 0;
fSplitting= false;
fMerging = false;

fFilterDisplacement = true;
criFilterDispalcement = 0.0;
fFilterDuration = true;

% for drift correction (NaN for very long)
criFilterDuration = nan; % number of NaN eg. 2.5*140; %This is a unit of time, not frame

%% The import lines, like in Python and Java
import java.lang.Integer
import ij.IJ
import ij.ImagePlus 
%import ij.WindowManager
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

%% Choose nd2 files
fSkipInput = false;
if exist('fByMasterMacro', 'var')
    if fByMasterMacro
        fSkipInput = true;
        targetChan = master_drift_targetChan;
        criThreshold = master_drift_criThreshold;
    end
end
if fSkipInput
    disp('spot tracking for drift correction... (skip uigetfile)')
else
    cd(path0);
    [files,path]=uigetfile('*.nd2','Select all files to analyze','MultiSelect','on');
    if ~iscell(files) % files is not a cell whne only one file is selected.
        files = {files};
    end
    nfiles = size(files,2);
end
cd(path)

for i=1:nfiles
    filename = files{i};
    [filepath,filenamehead,ext] = fileparts(filename);
    filename = [filenamehead '.nd2'];

    %% open one image
    imgFileFull = fullfile(path, filename);
    imp = IJ.openImage(imgFileFull);
    imp.show()


    %% Get and reset metadata
    stackSize = imp.getDimensions; %(width, height, nChannels, nSlices, nFrames)
    cal = imp.getCalibration();
    %frameInterval = cal.frameInterval;

    % remove scale info.
    cal.setUnit(""); %remove the scale info cf. cal.setUnit("micron")
    cal.pixelWidth = 1.0;
    cal.pixelHeight = 1.0;
    cal.pixelDepth = 1.0;
    imp.setCalibration(cal);

    %% Duration of traces covering the whole movie.
    if isnan(criFilterDuration)
        frameInterval = cal.frameInterval;
        nFrames = stackSize(5); % int32
        criFilterDuration = frameInterval*(double(nFrames)-1.5);
    end

    %% Set TrackMate
    % Create the model object now
    model = Model();

    % Send all messages to ImageJ log window.
    model.setLogger( Logger.IJ_LOGGER );

    % Prepare settings object
    settings = Settings(imp);

    % Configure detector - We use a java map
    settings.detectorFactory = LogDetectorFactory();
    map = java.util.HashMap();
    map.put('DO_SUBPIXEL_LOCALIZATION', fSubpixel);
    map.put('RADIUS', spotRADIUS);
    map.put('TARGET_CHANNEL', Integer.valueOf(targetChan)); % Needs to be an integer, otherwise TrackMate complaints.
    map.put('THRESHOLD', criThreshold);
    map.put('DO_MEDIAN_FILTERING', fMedianFilter);
    settings.detectorSettings = map;

    % Configure spot filters - Classical filter on quality.
    % All the spurious spots have a quality lower than 50 so we can add:
    filter1 = FeatureFilter('QUALITY', criFilterQaulity, fFilterQaulity);
    settings.addSpotFilter(filter1)

    % Configure tracker - We want to allow splits and fusions

    settings.trackerFactory  = SparseLAPTrackerFactory();
    %settings.trackerSettings = LAPUtils.getDefaultLAPSettingsMap(); % old path
    settings.trackerSettings = settings.trackerFactory.getDefaultSettings(); % almost good enough
    settings.trackerSettings.put('MAX_FRAME_GAP', Integer.valueOf(criMaxFrameGap));
    settings.trackerSettings.put('LINKING_MAX_DISTANCE', criLinkingMaxDistance);
    settings.trackerSettings.put('GAP_CLOSING_MAX_DISTANCE', criGapClosingMaxDistance);
    settings.trackerSettings.put('ALLOW_TRACK_SPLITTING', fSplitting);
    settings.trackerSettings.put('ALLOW_TRACK_MERGING', fMerging);


    % Configure track analyzers - Later on we want to filter out tracks
    % based on their displacement, so we need to state that we want
    % track displacement to be calculated. By default, out of the GUI,
    % not features are calculated.

    % Let's add all analyzers we know of.
    settings.addAllAnalyzers()

    % Configure track filters - We want to get rid of the two immobile spots at
    % the bottom right of the image. Track displacement must be above 10 pixels.
    filter2 = FeatureFilter('TRACK_DISPLACEMENT', criFilterDispalcement, fFilterDisplacement);
    settings.addTrackFilter(filter2)

    %filter3 = FeatureFilter('TRACK_DURATION', Integer.valueOf(criFilterDuration), fFilterDuration);
    filter3 = FeatureFilter('TRACK_DURATION', criFilterDuration, fFilterDuration);
    settings.addTrackFilter(filter3);


    %% Run TrackMate
    trackmate = TrackMate(model, settings);

    ok = trackmate.checkInput();
    if ~ok
        display(trackmate.getErrorMessage())
    end

    ok = trackmate.process();
    if ~ok
        display(trackmate.getErrorMessage())
    end

    %% Display results

    % % Read the user default display setttings.
    % ds = DisplaySettingsIO.readUserDefault();
    %
    % % Big lines.
    % ds.setLineThickness( 3. )
    %
    % selectionModel = SelectionModel( model );
    % displayer = HyperStackDisplayer( model, selectionModel, imp, ds );
    % displayer.render()
    % displayer.refresh()
    %
    % % Echo results
    % display( model.toString() )

    %% Save the result
    outFile = File(path, filenamehead+"_Tracks.xml");
    fiji.plugin.trackmate.action.ExportTracksToXML.export(model, settings, outFile);
    %ExportTracksToXML.export(model, settings, outFile);

    %% Save the image stack as TIF
    saveFileFull = fullfile(path, [filenamehead '.tif']);
    ij.IJ.saveAs(imp, "Tiff", saveFileFull);

    %% close this image file
    imp.close

end

%Quit the ImageJ instance from
%ij.IJ.run("Quit","")

%% END


