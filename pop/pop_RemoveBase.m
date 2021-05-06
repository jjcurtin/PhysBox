%USAGE: [ EEG COM ] = pop_RemoveBase( EEG, BaseWin )    
%Wrapper function to call pop_rmbase() with Curtin lab function naming
%conventions. Only allows timerange input, not pointrange
%see also pop_rmbase()
%
%INPUTS
%EEG: An epoched EEG set
%BaseWin:  a cell or numeric array with start and end of window in ms
%
%OUTPUTS
%EEG:  an epoched EEG set that is now baseline corrected
%COM:  string processing step for history

%Revision history
%2012-01-26:  updated dialog GUI

function [ EEG COM ] = pop_RemoveBase(EEG, BaseWin )  

    COM = 'pop_RemoveBase( EEG );';

    if nargin < 1
        pophelp('pop_RemoveBase');
        return
    end
    
    if nargin < 2
        geometry = { [1 1]};
        uilist =   { ...
                   { 'style' 'text'  'string' 'Baseline Window:'                                } ...
                   { 'style' 'edit'  'string', [int2str(EEG.xmin*1000) '  0']   'tag' 'BaseWin' } ...
                   };

        [op ud sh Results] = inputgui( geometry, uilist, 'pophelp(''pop_RemoveBase'')', 'Remove Baseline - pop_RemoveBase()');
        if isempty(Results); return; end  
        
        BaseWin = parsetxt(Results.BaseWin);
        BaseWin{1} = str2double(BaseWin{1});
        BaseWin{2} = str2double(BaseWin{2});
    end
    
    fprintf('\npop_RemoveBase():  Removing baseline mean from epoch\n');
    
    if iscell(BaseWin)
        BaseWin = cell2mat(BaseWin);
    end
    
    [EEG  COM] = pop_rmbase(EEG, BaseWin, []);

end

