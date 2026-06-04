/*************************************************************   
** File:        [usp_SaveAircraftHistory]
** Author:      [Amit Ghediya]
** Description: Save a single Aircraft History row.
**              Exactly 16 params matching AircraftHistoryTVP columns.
**              No TYPE required. Called once per changed field.
**
** Change History
********************
** PR   Date         Author          Description
** --   ----------   -------------   -------------------------
** 1    04/06/2026   Amit Ghediya     Created  
**************************************************************/

CREATE   PROCEDURE [dbo].[USP_SaveAircraftHistory]
    @ModuleId           TINYINT,
    @ModuleName         VARCHAR(100),
    @RefferenceId       BIGINT,
    @SubRefferenceId    BIGINT          = NULL,
    @SubModuleName      VARCHAR(100)    = NULL,
    @FieldsName         VARCHAR(150),
    @OldValue           VARCHAR(MAX),
    @NewValue           VARCHAR(MAX),
    @HistoryText        VARCHAR(MAX),
    @Activity           VARCHAR(10),
    @MasterCompanyId    INT,
    @CreatedBy          VARCHAR(256)    = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	BEGIN TRY 
		BEGIN TRANSACTION;

			DECLARE @AcTailNum          VARCHAR(50)     = NULL,
					@AcMake             VARCHAR(100)    = NULL,
					@AcModel            VARCHAR(100)    = NULL,
					@SerialNum          VARCHAR(100)    = NULL; 

			SELECT @AcTailNum = TailNum,@AcMake = MakeType,@AcModel = AircraftModel,@SerialNum = SerialNum 
			FROM dbo.[AircraftRegistryHeader] WITH(NOLOCK) WHERE AircraftRegistryId = @RefferenceId;

			INSERT INTO [dbo].[AircraftHistory]
			(
				[ModuleId], [ModuleName], [RefferenceId], [SubRefferenceId], [SubModuleName],
				[FieldsName], [OldValue], [NewValue], [HistoryText], [Activity],
				[AcTailNum], [AcMake], [AcModel], [SerialNum],
				[MasterCompanyId], [CreatedBy], [UpdatedBy],
				[CreatedDate], [UpdatedDate]
			)
			VALUES
			(
				@ModuleId, @ModuleName, @RefferenceId, @SubRefferenceId, @SubModuleName,
				@FieldsName, @OldValue, @NewValue, @HistoryText, @Activity,
				@AcTailNum, @AcMake, @AcModel, @SerialNum,
				@MasterCompanyId, @CreatedBy, @CreatedBy,   
				GETUTCDATE(), GETUTCDATE()
			);
		COMMIT TRANSACTION;
	END TRY
 
    BEGIN CATCH
 
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
 
        DECLARE
            @ErrorLogID      INT,
            @DatabaseName    VARCHAR(100) = DB_NAME(),
            @AdhocComments   VARCHAR(150) = 'USP_SaveAircraftHistory',
            @ApplicationName VARCHAR(100) = 'PAS';
 
        EXEC spLogException
            @DatabaseName    = @DatabaseName,
            @AdhocComments   = @AdhocComments,
            @ApplicationName = @ApplicationName,
            @ErrorLogID      = @ErrorLogID OUTPUT;
 
        RAISERROR(
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );
 
        RETURN(1);
 
    END CATCH
END