
/*************************************************************           
 ** File:   [GetCommonWorkOrderTeardownView]           
 ** Author: Subhash Saliya 
 ** Description: This stored procedure is used retrieve Common Work Order Tear Down View
 ** Purpose:         
 ** Date:   01/16/2023        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/16/2023   Subhash Saliya Created
     
--EXEC [GetCommonWorkOrderTeardownView] 5
**************************************************************/
Create   PROCEDURE [dbo].[GetCommonWorkOrderTeardownHistory]
	@CommonWorkOrderTearDownId  bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

			  SELECT [CommonWorkOrderTearDownAuditId]
                    ,[CommonWorkOrderTearDownId]
                    ,[CommonTeardownType]
                    ,[Memo]
                    ,[TechnicianDate]
                    ,[InspectorDate]
                    ,[ReasonName]
                    ,[InspectorName]
                    ,[TechnicalName]
                    ,[CreatedBy]
                    ,[UpdatedBy]
                    ,[CreatedDate]
                    ,[UpdatedDate]
                    ,[IsActive]
                    ,[IsDeleted]
                    ,[MasterCompanyId]
                    ,[IsSubWorkOrder]
                FROM [dbo].[CommonWorkOrderTearDownAudit] td WITH(NOLOCK)
				WHERE td.CommonWorkOrderTearDownId = @CommonWorkOrderTearDownId
				ORDER BY UpdatedDate desc
			  
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetCommonWorkOrderTeardownView' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CommonWorkOrderTearDownId, '') + ''
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