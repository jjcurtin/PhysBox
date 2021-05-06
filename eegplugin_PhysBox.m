% Usage: eegplugin_PhysBox(fig, trystrs, catchstrs);
%
% Inputs:
%   fig        - [integer]  EEGLAB figure
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks.
%
% PhysBox: The Psychophysiology Toolbox
% Author: John J. Curtin (jjcurtin@wisc.edu)
% Department of Psycholgy
% University of Wisconsin-Madison
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.
%
%See also eeglab()

function currvers = eegplugin_PhysBox(fig, try_strings, catch_strings)

currvers  = 'PhysBox: The Psychophysiology Toolbox (jjcurtin@wisc.edu)';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% MENU CALLBACKS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Plot functions
cmdPlotOverlay = [try_strings.check_epoch '[LASTCOM] = pop_PlotOverlay(EEG);' catch_strings.add_to_hist ];
cmdPlotSet = [try_strings.no_check '[LASTCOM] = pop_PlotSet(EEG);' catch_strings.add_to_hist ];
cmdFigure6Panel = [try_strings.no_check '[EEG, LASTCOM] = pop_Figure6Panel(EEG);' catch_strings.add_to_hist ];

%Scoring
cmdScoreSTL = [try_strings.check_epoch '[EEG, LASTCOM] = pop_ScoreStartle(EEG);' catch_strings.new_and_hist];
cmdScoreWindows = [try_strings.check_epoch '[EEG, LASTCOM] = pop_ScoreWindows(EEG);' catch_strings.new_and_hist];
cmdScoreERP = [try_strings.check_epoch '[EEG, LASTCOM] = pop_ScoreERP(EEG);' catch_strings.new_and_hist];
%cmdScoreSegments = [try_strings.check_epoch '[EEG, LASTCOM] = pop_ScoreWSegments(EEG);' catch_strings.new_and_hist];

%Artifact
cmdQuantNoise = [try_strings.check_cont '[EEG, LASTCOM] = pop_QuantNoise(EEG);' catch_strings.new_and_hist ];
cmdRejectBreaks = [try_strings.check_cont '[EEG, LASTCOM] = pop_RejectBreaks(EEG);' catch_strings.new_and_hist ];
cmdRemoveBlinks = [try_strings.check_cont '[EEG, LASTCOM] = pop_RemoveBlinks(EEG);' catch_strings.new_and_hist ];
cmdMarkThreshold = [try_strings.check_epoch '[EEG, Indices, LASTCOM] = pop_MarkThreshold(EEG);' catch_strings.new_and_hist];
cmdMarkMean = [try_strings.check_epoch '[EEG, Indices, LASTCOM] = pop_MarkMean(EEG);' catch_strings.new_and_hist];
cmdMarkEpoch = [try_strings.check_epoch '[EEG, Indices, LASTCOM] = pop_MarkEpoch(EEG);' catch_strings.new_and_hist];
cmdMarkDeflection = [try_strings.check_epoch '[EEG, Indices, LASTCOM] = pop_MarkDeflection(EEG);' catch_strings.new_and_hist];
cmdViewRejects = [try_strings.check_epoch '[EEG, LASTCOM] = pop_ViewRejects(EEG);' catch_strings.add_to_hist];
cmdRejectRejects = [try_strings.check_epoch '[EEG, COM] = pop_RejectEpochs(EEG);' catch_strings.new_and_hist];

%Data/Notes export
cmdExportEpochs = [try_strings.check_epoch '[EEG, LASTCOM] = pop_ExportEpochs(EEG);' catch_strings.add_to_hist];
cmdExportScores = [try_strings.check_epoch '[EEG, LASTCOM] = pop_ExportScores(EEG);' catch_strings.add_to_hist];
cmdExportNotes = [try_strings.check_epoch '[EEG, LASTCOM] = pop_ExportNotes(EEG);' catch_strings.add_to_hist];

%Event processing
cmdEventCheck = [try_strings.check_cont '[EventCount,TimingArray,S1S2Array,CBArray,LASTCOM] = pop_EventCheck(EEG);' catch_strings.add_to_hist ];
cmdRecodeEvents = [try_strings.no_check '[EEG, LASTCOM] = pop_RecodeEvents(EEG);' catch_strings.new_and_hist ];
cmdImportEvents = [try_strings.check_cont '[EEG, LASTCOM] = pop_ImportEvents(EEG);' catch_strings.new_and_hist ];
cmdConvertEvents = [try_strings.check_cont '[EEG, LASTCOM] = pop_ConvertEvents(EEG);' catch_strings.new_and_hist ];
cmdImportResponses = [try_strings.check_cont '[EEG, LASTCOM] = pop_ImportResponses(EEG);' catch_strings.new_and_hist ];
cmdResponseEvents = [try_strings.check_cont '[EEG, LASTCOM] = pop_ResponseEvents(EEG);' catch_strings.new_and_hist ];

cmdDeleteEpochs = [try_strings.check_epoch '[EEG, LASTCOM] = pop_DeleteEpochs(EEG);' catch_strings.new_and_hist ];
cmdExtractEpochs = [try_strings.check_cont '[EEG, LASTCOM] = pop_ExtractEpochs(EEG);' catch_strings.new_and_hist ];
cmdRemoveBase = [try_strings.check_epoch '[EEG, LASTCOM] = pop_RemoveBase(EEG);' catch_strings.new_and_hist ];
cmdCreateAvg = [try_strings.check_epoch '[EEG, LASTCOM] = pop_CreateAvg(EEG);' catch_strings.new_and_hist ];
cmdAverageWaveform = [try_strings.check_epoch '[EEG, LASTCOM] = pop_AverageWaveform(EEG);' catch_strings.new_and_hist ];
cmdGrandAverage = [try_strings.check_epoch '[EEG, LASTCOM] = pop_GrandAverage(EEG);' catch_strings.new_and_hist ];

%File Load/Close/Save
cmdLoadSet = [try_strings.no_check '[EEG, LASTCOM] = pop_LoadSet;' catch_strings.new_and_hist];
cmdLoadCnt = [try_strings.no_check '[EEG, LASTCOM] = pop_LoadCnt;' catch_strings.new_and_hist];
cmdLoadSma = [try_strings.no_check '[EEG, LASTCOM] = pop_LoadSma;' catch_strings.new_and_hist];
cmdLoadCurry = [try_strings.no_check '[EEG, LASTCOM] = pop_LoadCurry;' catch_strings.new_and_hist];
cmdLoadAnt = [try_strings.no_check '[EEG, LASTCOM] = pop_LoadAnt;' catch_strings.new_and_hist];
cmdLoadEGI = [try_strings.no_check '[EEG, LASTCOM] = pop_LoadEGI;' catch_strings.new_and_hist];
cmdLoadFig = [try_strings.no_check 'LASTCOM = pop_LoadFig;' catch_strings.add_to_hist];
cmdSaveSet = [try_strings.no_check '[EEG, LASTCOM] = pop_SaveSet(EEG);' catch_strings.new_and_hist];
cmdCloseSet = [try_strings.no_check '[ALLEEG, LASTCOM] = pop_CloseSet(ALLEEG); eeglab redraw;' catch_strings.add_to_hist ];

%Data processing
cmdSelectChannels = [try_strings.check_cont '[EEG, LASTCOM] = pop_SelectChannels(EEG);' catch_strings.new_and_hist ];
cmdButterworthFilter = [try_strings.no_check '[EEG, LASTCOM] = pop_ButterworthFilter(EEG);' catch_strings.new_and_hist ];
cmdAveMastoid = [try_strings.check_cont '[EEG, LASTCOM] = pop_AveMastoid(EEG);' catch_strings.new_and_hist ];
cmdRectifyChannels = [try_strings.check_cont '[EEG, LASTCOM] = pop_RectifyChannels(EEG);' catch_strings.new_and_hist ];

%Parameter file processing
cmdGetParameters = [try_strings.no_check '[P, LASTCOM] = pop_GetParameters;' catch_strings.add_to_hist ];
cmdSaveParameters = [try_strings.no_check '[P, LASTCOM] = pop_SaveParameters(P);' catch_strings.add_to_hist ];
cmdProcessSet = [try_strings.no_check '[EEG, P] = pop_ProcessSet(EEG);' catch_strings.new_and_hist ];
cmdMultiSet = [try_strings.no_check '[P, LASTCOM] = pop_ProcessSets(P);' catch_strings.add_to_hist ];

%Data Integrity functions
cmdCheckERP = [try_strings.no_check '[LASTCOM] = pop_CheckERP();' catch_strings.add_to_hist ];
cmdCheckSTL = [try_strings.no_check '[LASTCOM] = pop_CheckStartle();' catch_strings.add_to_hist ];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% BUILD MAIN MENU %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
menuEEGLAB = findobj(fig, 'tag', 'EEGLAB');   % At EEGLAB Main Menu
submenuPB = uimenu( menuEEGLAB, 'Label', 'PhysBox', 'separator','on','tag','PhysBox');
set(submenuPB, 'position', 1);

%Data load/save functions
subLoadSave = uimenu( submenuPB,    'Label', 'Data Load/Save/Close' , 'separator', 'on');
uimenu(subLoadSave, 'label', 'Load SET file', 'callback',cmdLoadSet);
uimenu(subLoadSave, 'label', 'Load CNT file', 'callback',cmdLoadCnt);
uimenu(subLoadSave, 'label', 'Load CURRY file', 'callback',cmdLoadCurry);
uimenu(subLoadSave, 'label', 'Load SMA file', 'callback',cmdLoadSma);
uimenu(subLoadSave, 'label', 'Load ANT file', 'callback',cmdLoadAnt);
uimenu(subLoadSave, 'label', 'Load EGI file', 'callback',cmdLoadEGI);
uimenu(subLoadSave, 'label', 'Load FIG file', 'callback',cmdLoadFig, 'separator', 'on');
uimenu(subLoadSave, 'label', 'Save SET as', 'callback',cmdSaveSet, 'separator', 'on');
uimenu(subLoadSave, 'label', 'Close SET(s)', 'callback',cmdCloseSet , 'separator', 'on', 'userdata', 'startup:off;epoch:on;continuous:on');

%Event related functions
subEvents = uimenu( submenuPB,    'Label', 'Event/Epoch Processing' , 'separator', 'on');
uimenu(subEvents, 'label', 'Check Event Structure', 'callback',cmdEventCheck);
uimenu(subEvents, 'label', 'Convert Events to Integer', 'callback',cmdConvertEvents, 'separator','on');
uimenu(subEvents, 'label', 'Recode Events', 'callback',cmdRecodeEvents);
uimenu(subEvents, 'label', 'Import Events', 'callback',cmdImportEvents);
uimenu(subEvents, 'label', 'Import Response Data', 'callback',cmdImportResponses, 'separator','on');
uimenu(subEvents, 'label', 'Add Response Events', 'callback',cmdResponseEvents);
uimenu(subEvents, 'label', 'Extract Epochs', 'callback',cmdExtractEpochs, 'separator','on');
uimenu(subEvents, 'label', 'Delete Epochs', 'callback',cmdDeleteEpochs);
uimenu(subEvents, 'label', 'Remove Epoch Baseline', 'callback',cmdRemoveBase);
uimenu(subEvents, 'label', 'Create Average (AVG) SET', 'callback',cmdCreateAvg, 'separator','on');
uimenu(subEvents, 'label', 'Create Average Waveform', 'callback',cmdAverageWaveform);
uimenu(subEvents, 'label', 'Create Grand Average (GND) SET', 'callback',cmdGrandAverage, 'separator','on');

%Data field processing functions
subData = uimenu( submenuPB,    'Label', 'Data Field Processing' , 'separator', 'on');
uimenu(subData, 'label', 'Select Channels', 'callback',cmdSelectChannels, 'separator', 'on');
uimenu(subData, 'label', 'Apply Butterworth Filter', 'callback',cmdButterworthFilter, 'separator', 'on');
uimenu(subData, 'label', 'Remove Blinks', 'callback',cmdRemoveBlinks, 'separator','on');
uimenu(subData, 'label', 'Re-reference to average mastoid', 'callback',cmdAveMastoid, 'separator','on');
uimenu(subData, 'label', 'Rectify Channel(s)', 'callback',cmdRectifyChannels, 'separator','on');
uimenu(subData, 'label', 'Remove Epoch Baseline', 'callback',cmdRemoveBase, 'separator','on');
uimenu(subData, 'label', 'Create Average (AVG) SET', 'callback',cmdCreateAvg, 'separator','on');
uimenu(subData, 'label', 'Create Average Waveform', 'callback',cmdAverageWaveform, 'separator','on');
uimenu(subData, 'label', 'Create Grand Average (GND) SET', 'callback',cmdGrandAverage, 'separator','on');
%REMOVE DC 

%Artifact related functions
subArtifact = uimenu( submenuPB,    'Label', 'Artifact' , 'separator', 'on');
uimenu(subArtifact, 'label', 'Quantify 60Hz Noise', 'callback',cmdQuantNoise, 'separator','on');
uimenu(subArtifact, 'label', 'Reject Break Periods', 'callback',cmdRejectBreaks, 'separator','on');
uimenu(subArtifact, 'label', 'Remove Blinks', 'callback',cmdRemoveBlinks, 'separator','on');
uimenu(subArtifact, 'label', 'Mark Artifactual Epochs by Threshold', 'callback',cmdMarkThreshold, 'separator','on');
uimenu(subArtifact, 'label', 'Mark Artifactual Epochs by Mean Level', 'callback',cmdMarkMean);
uimenu(subArtifact, 'label', 'Mark Artifactual Epochs by Epoch Number', 'callback',cmdMarkEpoch);
uimenu(subArtifact, 'label', 'Mark Artifactual Epochs by Max Deflection', 'callback',cmdMarkDeflection);
uimenu(subArtifact, 'label', 'Plot 6 Panel Artifact Figure', 'callback',cmdFigure6Panel, 'separator', 'on');
uimenu(subArtifact, 'label', 'Plot Artifact Marked Epochs', 'callback',cmdViewRejects);
uimenu(subArtifact, 'label', 'Reject Marked Epochs', 'callback',cmdRejectRejects, 'separator', 'on');

%plotting functions
subPlots = uimenu( submenuPB,    'Label', 'Plotting', 'separator', 'on');
uimenu(subPlots, 'label', 'View SET', 'callback',cmdPlotSet);
uimenu(subPlots, 'label', 'Plot Artifact Marked Epochs', 'callback',cmdViewRejects, 'separator', 'on');
uimenu(subPlots, 'label', 'Plot 6 Panel Artifact Figure', 'callback',cmdFigure6Panel);
uimenu(subPlots, 'label', 'Overlay Plot', 'callback',cmdPlotOverlay, 'separator','on');
%NEED TO ADD pop_image wrapper

%Scoring functions
subScore = uimenu( submenuPB,    'Label', 'Scoring Functions' , 'separator', 'on');
uimenu(subScore, 'label', 'Score Startle', 'callback',cmdScoreSTL, 'separator','on');
uimenu(subScore, 'label', 'Score Min/Max/Mean in Fixed Window(s)', 'callback',cmdScoreWindows);
uimenu(subScore, 'label', 'Score ERPs', 'callback',cmdScoreERP);
%uimenu(subScore, 'label', 'Score  Segment Means in Window', 'callback',cmdScoreSegments);
%NEED LATENCY SCORE FOR ERP

%Data export functions
subExport = uimenu( submenuPB,    'Label', 'Export to DAT' , 'separator', 'on');
uimenu(subExport, 'label', 'Export Epoch (EPH) File', 'callback',cmdExportEpochs, 'separator','on');
uimenu(subExport, 'label', 'Export Scores', 'callback',cmdExportScores);
uimenu(subExport, 'label', 'Export Notes', 'callback',cmdExportNotes);

%Multi-set processing functions
subMS = uimenu( submenuPB,    'Label', 'Use Parameter File' , 'separator', 'on');
uimenu(subMS, 'label', 'Open Parameter File', 'callback',cmdGetParameters);
uimenu(subMS, 'label', 'Save Parameter File', 'callback',cmdSaveParameters);
uimenu(subMS, 'label', 'Call ProcessSet', 'callback', cmdProcessSet, 'separator', 'on');
uimenu(subMS, 'label', 'Call MultiSet', 'callback', cmdMultiSet, 'separator', 'on');

%Data Integrity functions
subAdmin = uimenu( submenuPB,    'Label', 'Data Integrity' , 'separator', 'on');
uimenu(subAdmin, 'label', 'Check ERP Reduction', 'callback',cmdCheckERP);
uimenu(subAdmin, 'label', 'Check STL Reduction', 'callback', cmdCheckSTL);
uimenu(subAdmin, 'label', 'Check Event Structure', 'callback',cmdEventCheck, 'separator', 'on');

end


