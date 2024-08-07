/*******           
 ** File:   [USP_GetAccountingItegrationSettingsById]           
 ** Author:   Bhargav SALIYA
 ** Description: Get Data for edit integration Data
 ** Purpose:         
 ** Date:   03-07-2024    
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 ********           
  ** Change History           
 ********           
 ** PR   Date         Author		  Change Description            
 ** --   --------     -------		  --------------------------------          
    1    06 Aug 2024   BHARGAV SALIYA   Created

	exec [USP_GetAccountingItegrationSettingsById] 1,1
********/ 

CREATE    PROCEDURE [dbo].[USP_GetAccountingItegrationSettingsById]
	@integrationID bigint = null,
	@MasterCompanyId bigint = null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				Select	
                    AIS.AccountingIntegrationSettingsId,
					AIS.IntegrationWith,
					AIS.LastRun,
					AIS.Interval,
					AIS.ModuleName,
					AIS.CreatedBy,
                    AIS.UpdatedBy,
                    AIS.UpdatedDate,
                    AIS.CreatedDate,
					AIS.IsActive,
					AIS.IsDeleted
				FROM DBO.AccountingIntegrationSettings AIS  WITH(NOLOCK)
				WHERE AIS.AccountingIntegrationSettingsId = @integrationID and AIS.MasterCompanyId = @MasterCompanyId

			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetAccountingItegrationSettingsById' 
              , @ProcedureParameters VARCHAR(3000)  = '@integrationID = '''+ ISNULL(@integrationID, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
			            
END