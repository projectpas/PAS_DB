
/*************************************************************           
 ** File:   [GetCommonWorkOrderTeardownView]           
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used retrieve Common Work Order Tear Down View
 ** Purpose:         
 ** Date:   12/29/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/29/2021   Vishal Suthar Created
     
--EXEC [GetCommonWorkOrderTeardownView] 5
**************************************************************/
CREATE PROCEDURE [dbo].[GetCommonWorkOrderTeardownView]
	@wowfId  bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			   SELECT tdt.CommonTearDownTypeId,
					ISNULL(td.ReasonName,'') ReasonName,
                    ISNULL(td.TechnicalName,'') as Technician,
                    ISNULL(td.InspectorName,'') as Inspector,
                    ISNULL(td.Memo,'') as Memo,
                    td.TechnicianDate as TechnicianDate,
                    td.InspectorDate as InspectorDate,
                    td.IsDocument as IsDocumentAdded,
					tdt.[Name] as TearDownType,
					tdt.IsTechnician,
					tdt.[IsDate],
					tdt.IsInspector,
					tdt.IsInspectorDate,
					tdt.IsDocument,
					tdt.[Sequence],
					tdt.DocumentModuleName
				FROM [dbo].[CommonWorkOrderTearDown] td WITH(NOLOCK)
				INNER JOIN [dbo].[CommonTeardownType] tdt ON td.CommonTearDownTypeId = tdt.CommonTearDownTypeId
				WHERE td.WorkFlowWorkOrderId = @wowfId
				ORDER BY tdt.[Sequence]
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@wowfId, '') + ''
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