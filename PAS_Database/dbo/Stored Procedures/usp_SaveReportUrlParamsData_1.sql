
/*************************************************************           
 ** File:   [SaveReportUrlParamsData]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to save report url params
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
CREATE PROCEDURE [dbo].[usp_SaveReportUrlParamsData] 
	@ReportURL VARCHAR(MAX),
	@ReportName VARCHAR(100),
	@MasterCompanyId BIGINT,
	@CreatedBy VARCHAR(30)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	

		DECLARE @ReportId BIGINT

		INSERT INTO [ReportUrlParams]

			(ReportURL, ReportName, MasterCompanyId, CreatedBy, CreatedDate)
		
		VALUES 

			(@ReportURL, @ReportName, @MasterCompanyId, @CreatedBy, GETUTCDATE())
		
		
		SET @ReportId = SCOPE_IDENTITY()

		SELECT @ReportId AS ReportId

	END
	COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
                ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SaveReportUrlParamsData' 
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReportURL, '') AS VARCHAR(100))      
											+ '@Parameter2 = ''' + CAST(ISNULL(@ReportName, '') AS varchar(100))       
											+ '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))      
											+ '@Parameter4 = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100))    
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