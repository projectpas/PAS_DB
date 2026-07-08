/*************************************************************
 ** File:        [USP_UpdateAircraftPublicationCompliance]
 ** Author:      Amit Ghediya
 ** Description: 
 ** Purpose:
 ** Date:        07/07/2026

 ** RETURN VALUE: single-row result set with the columns below.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author			Change Description
 ** --   --------      -------			--------------------------------
    1    07/07/2026    Amit Ghediya      Created


 EXEC USP_UpdateAircraftPublicationCompliance 1,'','ref',1,'admin'
 **************************************************************/
CREATE      PROCEDURE [dbo].[USP_UpdateAircraftPublicationCompliance] 
    @AircraftPublicationId BIGINT,
    @ComplianceDate DATETIME2(7) = NULL,
    @RactificationDate  DATETIME2(7) = NULL,
    @MasterCompanyId INT,
    @UpdatedBy VARCHAR(256) = NULL
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    SET NOCOUNT ON;

    BEGIN TRY

        UPDATE [dbo].[AircraftPublication]
		SET [ComplianceDate] = @ComplianceDate,
			[RactificationDate] = @RactificationDate,
			[UpdatedBy] = @UpdatedBy,
			[UpdatedDate] = GETDATE()
		WHERE [AircraftPublicationId] = @AircraftPublicationId
		  AND [MasterCompanyId] = @MasterCompanyId;

		SELECT @@ROWCOUNT AS RowsAffected;

    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID  INT,
                @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments        VARCHAR(150)  = 'USP_UpdateAircraftPublicationCompliance'
              , @ProcedureParameters  VARCHAR(3000) = '@AircraftPublicationId = ''' + CAST(ISNULL(@AircraftPublicationId, 0) AS VARCHAR(20))
                                                     + ''', @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20)) + ''''
              , @ApplicationName      VARCHAR(100)  = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException
                  @DatabaseName          = @DatabaseName
                , @AdhocComments         = @AdhocComments
                , @ProcedureParameters   = @ProcedureParameters
                , @ApplicationName        = @ApplicationName
                , @ErrorLogID            = @ErrorLogID OUTPUT;
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN(1);
    END CATCH
END