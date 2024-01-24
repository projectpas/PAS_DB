/*************************************************************           
 ** File:   [RPT_GetCommonWorkOrderTearDownPrintView]       
 ** Author: AMIT GHEDIYA
 ** Description: This stored procedure is used retrieve Common Work Order Tear Down for SSRS report
 ** Purpose:         
 ** Date:   28/12/2023

 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		         Change Description            
 ** --   --------     -------				--------------------------------          
    1    28/12/2023   AMIT GHEDIYA			Created
     

**************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetCommonWorkOrderTearDownPrintView]
	@WorkorderId bigint = 0,
	@workFlowWorkOrderId bigint = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @ItemMasterIdlist VARCHAR(max) = '0';

				SELECT @ItemMasterIdlist = TearDownTypes FROM DBO.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkorderId

			    SELECT DISTINCT tdt.CommonTearDownTypeId,
					ISNULL(td.ReasonName,'') ReasonName,
                    UPPER(ISNULL(td.TechnicalName,'')) as Technician,
                    UPPER(ISNULL(td.InspectorName,'')) as Inspector,
                    --ISNULL(td.Memo,'') as Memo,
					REPLACE(REPLACE(ISNULL(td.Memo,''), '<p>', ''),'</p>','<br />') as Memo,
                    --ISNULL(td.TechnicianDate,'') AS TechnicianDate,
					td.TechnicianDate,
                    td.InspectorDate as InspectorDate,
                    td.IsDocument as IsDocumentAdded,
					tdt.[Name] as TearDownType,
					ISNULL(tdt.IsTechnician,0) AS IsTechnician,
					tdt.[IsDate],
					ISNULL(tdt.IsInspector,0) AS IsInspector,
					ISNULL(tdt.IsInspectorDate,'') AS IsInspectorDate,
					tdt.IsDocument,
					tdt.[Sequence],
					tdt.DocumentModuleName
				FROM [dbo].[CommonTeardownType] tdt WITH(NOLOCK)
				LEFT JOIN [dbo].[CommonWorkOrderTearDown] td WITH(NOLOCK) ON td.CommonTearDownTypeId = tdt.CommonTearDownTypeId
				AND td.WorkOrderId = @WorkorderId AND td.WorkFlowWorkOrderId = @workFlowWorkOrderId AND Isnull(td.IsSubWorkOrder,0) = 0
				WHERE tdt.CommonTearDownTypeId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
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
              , @AdhocComments     VARCHAR(150)    = 'RPT_GetCommonWorkOrderTearDownPrintView' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkorderId, '') + ''
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