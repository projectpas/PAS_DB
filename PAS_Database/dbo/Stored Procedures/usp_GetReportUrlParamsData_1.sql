
/*************************************************************           
 ** File:   [usp_GetReportUrlParamsData]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to get report url params
 ** Purpose:         
 ** Date:   05/04/2024
 ** PARAMETERS: 
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		     Change Description            
 ** --   --------     -------		     --------------------------------          
    1    05/04/2024   Abhishek Jirawla	 Created

************************************************************************/
CREATE PROCEDURE [dbo].[usp_GetReportUrlParamsData] 
	@ReportId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	

		SELECT Id,
			ReportUrl,
			ReportName,
			CreatedBy,
			CreatedDate
		FROM ReportUrlParams
		WHERE Id = @ReportId

	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
                ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetReportUrlParamsData' 
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReportId, '') AS varchar(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH 
END