%% Use t-form to registration (chromatic)
% open a single-color channel file
% the image size should be same (eg. 800 by 800 px)

%% Settings
disp('Chromatic error correction...')

% tform230414.mat ->without em filter
% tform230214.mat ->with em filter
if ~exist('tformFilefull', 'var') 
    tformFilefull='E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023\chromaticErr\tform230414.mat';
end

if ~exist('path0', 'var') %check if path0 is in this workspace.
    path0 = 'E:\OneDrive - Johns Hopkins\MJ\ExpData\ExpData_Cell_2023';
end

%% Load the coefficient ('tform')
if ~isfile(tformFilefull)
   cd(path0)
   [tformfile,path2] = uigetfile('*.mat','Open a t-form file'); %cd(path2)
   tformFilefull = fullfile(path2, tformfile);
end
load(tformFilefull); 
tform = movingReg.Transformation;

%% Load the image file
fSkipInput = false;
if exist('fByMasterMacro', 'var')
    if fByMasterMacro
        fSkipInput = true;
    end
end
if fSkipInput
    disp('Chromatic error correction for tif files... (skip uigetfile)')
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

    if fByMasterMacro
        %filenamehead = [filenamehead '_chan3_drftc'];
        filenamehead = [filenamehead '_chan' num2str(master_targetChan2) '_drftc'];
    end
    filename = [filenamehead '.tif'];

    stack0=loadtiff(filename);
    stack0info = whos('stack0');
    nx = stack0info.size(1);
    ny = stack0info.size(2);
    if size(stack0info.size,2)>2
        nf = stack0info.size(3);
        %nf = nf/nChan;
    else
        nf = 1;
    end
    datatype = char(stack0info.class);



    %% Get the transforamtion and registrated image
    stack1 = zeros(nx,ny,nf,datatype);
    for fr=1:nf
        thisImg = stack0(:,:,fr);
        stack1(:,:,fr) = imwarp(thisImg,tform,'OutputView', imref2d(size(thisImg))); %size(I))
    end

    %% Save the result
    cd(path)
    clear options;
    options.color = false;
    options.overwrite = true;
    saveastiff(stack1, [filenamehead '_reg.tif'], options);
end



