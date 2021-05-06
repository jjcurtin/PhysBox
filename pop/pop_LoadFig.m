%USAGE: COM = pop_LoadFig( FigFileName, Maximize, Wait )
%Loads a FIG file created by notes_ functions (or really any fig file).  If
%no parameters provided, it will prompt to open file and set Maximize=1 and
%Wait=0
%
%INPUTS
%FigFileName: Full filename and path
%Maximize: If true(1), will maximize the window (default is true)
%Wait (If true(1), will halt execution using UIWAIT until fig is closed (default is false)
%
%OUTPUTS
%COM:  EEGLAB COM

%Revision History
%2011-11-25: released, JJC

function COM = pop_LoadFig( FigFileName, Maximize, Wait )
    COM = 'COM = pop_LoadFig()';
    
    if nargin < 3 || isempty (Wait)
        Wait = 1;
    end
    if nargin < 2 || isempty(Maximize)
        Maximize = 1;
    end

    if nargin < 1 || isempty(FigFileName)
        [Filename Pathname] = uigetfile('*.fig', 'Open Figure File');
        if  isequal(Filename,0) || isequal(Pathname,0)
            return
        end
        FigFileName = fullfile(Pathname, Filename);
    end

    open(FigFileName);
    if Maximize
        maximize(gcf)
    end
    
    if Wait
        uiwait(gcf);
    end
    
    COM = sprintf('COM = pop_LoadFig(%s, %d, %d)', FigFileName, Maximize, Wait);

end

