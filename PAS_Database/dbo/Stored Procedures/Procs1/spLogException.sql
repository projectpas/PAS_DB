CREATE PROCEDURE [dbo].[spLogException]
    (
      @DatabaseName VARCHAR(300) = NULL ,
      @AdhocComments VARCHAR(1000) = '' ,
      @ProcedureParameters VARCHAR(3000) = '' ,
      @ModuleName VARCHAR(300) = '' ,
      @ApplicationName VARCHAR(100) = '' ,
      @ErrorLogID INT = 0 OUTPUT  -- Contains the ErrorLogID of the row inserted
)
AS
    BEGIN
        SET NOCOUNT ON;
        DECLARE @AppName VARCHAR(300) = '' ,
            @NSQLString NVARCHAR(1000) ,
            @Exists BIT ,
            @RolledBackTranCount TINYINT;

        SET @RolledBackTranCount = @@trancount;

        IF @@trancount > 0
            ROLLBACK TRAN;

        SELECT  @DatabaseName = LTRIM(RTRIM(@DatabaseName)) ,
                @AdhocComments = LTRIM(RTRIM(@AdhocComments)) ,
                @ModuleName = LTRIM(RTRIM(@ModuleName));

        SELECT  @DatabaseName = ISNULL(@DatabaseName, DB_NAME());

    -- Output parameter value of 0 indicates that error
    -- information was not logged.
        SET @ErrorLogID = 0;

        BEGIN TRY
        -- a transaction is in an uncommittable state.
            IF XACT_STATE() = -1
                BEGIN
                    PRINT 'Cannot log error since the current transaction is in an uncommittable state. '
                        + 'Rollback the transaction before executing uspLogError in order to successfully log error information.';
                    RETURN;
                END;

            INSERT  Appl_ErrorLog
                    ( [SQLUserName] ,
                      [ErrorNumber] ,
                      [ErrorSeverity] ,
                      [ErrorState] ,
                      [ErrorProcedure] ,
                      [ProcedureParameters] ,
                      [ErrorLine] ,
                      [ErrorMessage] ,
                      DatabaseName ,
                      ModuleName ,
                      AdhocComments ,
                      RolledBackTranCount ,
                      SPID ,
                      HostName ,
                      ClientAppName ,
                      ApplicationName
                    )
            VALUES  ( ISNULL(CONVERT(sysname, CURRENT_USER), '') ,
                      ISNULL(ERROR_NUMBER(), 0) ,
                      ISNULL(ERROR_SEVERITY(), 0) ,
                      ISNULL(ERROR_STATE(), 0) ,
                      ISNULL(ERROR_PROCEDURE(), 'Inline Code') ,
                      @ProcedureParameters ,
                      ISNULL(ERROR_LINE(), 0) ,
                      ISNULL(ERROR_MESSAGE(), '') ,
                      @DatabaseName ,
                      @ModuleName ,
                      @AdhocComments ,
                      @RolledBackTranCount ,
                      @@SPID ,
                      HOST_NAME() ,
                      SUBSTRING(APP_NAME(), 0, 300) ,
                      @ApplicationName
                    );

        -- Pass back the ErrorLogID of the row inserted
            SELECT  @ErrorLogID = @@IDENTITY;
        END TRY
        BEGIN CATCH
            PRINT 'An error occurred in stored procedure uspLogError: ';
            SELECT  CONVERT(sysname, CURRENT_USER) ,
                    ERROR_NUMBER() ,
                    ERROR_SEVERITY() ,
                    ERROR_STATE() ,
                    ERROR_PROCEDURE() ,
                    ERROR_LINE() ,
                    ERROR_MESSAGE();
            RETURN -1;
        END CATCH;
    END;