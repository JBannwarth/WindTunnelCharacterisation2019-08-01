function [ UMean, UStd, UTi ] = TurbsimBin2Mat( folderIn, detailFile )
%TURBSIMBIN2MAT Convert .bin files generated by Turbsim to .mat files.
%   [UMEAN, USTD, UTI] = TURBSIMBIN2MAT( ) converts .bin files to .mat.
%   [UMEAN, USTD, UTI] = TURBSIMBIN2MAT( FOLDERIN ) specifies input folder.
%   [UMEAN, USTD, UTI] = TURBSIMBIN2MAT( FOLDERIN, DETAILFILE ) specifies name of detail file.
%
%   Inputs:
%       - folderIn:   name of input folder, defaults to 'turbsim'.
%       - detailFile: name of file containing scaling factors and
%                     target .bin filenames, defaults to
%                     'turbsim_generation_details.mat'.
%   Outputs:
%       - UMean: Mean wind speeds along U, V, and W axes (m/s).
%       - UStd: Standard deviation of wind speed along U, V, and W axes
%               (m/s).
%       - UTi:  Turbulence intensity along U, V, and W axes (%).
%
%   Use this function after running GenerateTurbsimSettings and running
%   Turbsim using the resulting .bat file.
%
%   See also IMPORTTURBSIMBIN, GENERATETURBSIMSETTINGS.
%
%   Written: 2021/20/25, J.X.J. Bannwarth based on original script by
%                        Z.J. Chen

    arguments
        folderIn   (1,:) char {mustBeNonempty} = 'turbsim'
        detailFile (1,:) char {mustBeNonempty} = 'turbsim_generation_details.mat'
    end

    %% Set-up
    % Get generation details
    load( fullfile( folderIn, detailFile), 'filenames', 'UStdNorm' )
    filenames = replace( filenames, '.inp', '.bin' );
    
    % Remove existing .mat files
    delete( fullfile( folderOut, '*.mat' ) )

    %% Convert files
    UMean = zeros( length(filenames), 3 );
    UStd = UMean;
    UTi  = UMean;
    for ii = 1:length( filenames )
        % Load file
        [ time, data ] = ImportTurbsimBin( fullfile( folderIn, filenames{ii} ) );

        % Get [U,V,W] wind components
        data = data(:, [1, 4, 5]);

        % Scale wind components
        data = data .* UStdNorm(ii,:);

        % Generate statistical properties
        UMean(ii,:) = mean(data,1);
        UStd(ii,:) = std(data,1,1);
        UTi(ii,:) = 100 * UStd(ii,:) / UMean(ii,1);

        % Form into timeseries object
        windInput = timeseries( data, time, 'Name', 'Wind profile' );
        windInput.DataInfo.Units = 'm/s';

        % Save data
        save( fullfile( folderIn, replace( filenames{ii}, '.bin', '.mat' ) ), ...
            'windInput')
    end
end