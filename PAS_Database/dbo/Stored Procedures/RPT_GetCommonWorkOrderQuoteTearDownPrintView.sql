/*************************************************************           
 ** File:   [RPT_GetCommonWorkOrderQuoteTearDownPrintView]       
 ** Author: HEMANT SALIYA
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
    1    28/12/2023   HEMANT SALIYA		Created

RPT_GetCommonWorkOrderQuoteTearDownPrintView 5126, 4028, 4736
**************************************************************/
CREATE   PROCEDURE [dbo].[RPT_GetCommonWorkOrderQuoteTearDownPrintView]
	@WorkorderId BIGINT = 0,
	@WorkOrderQuoteId BIGINT = 0,
	@WorkFlowWorkOrderId BIGINT = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				DECLARE @TearDownTypeIds VARCHAR(max) = '0';
				DECLARE @MasterCompanyId BIGINT;
				DECLARE @WorkOrderTypeId BIGINT;

				SELECT @MasterCompanyId = MasterCompanyId, @WorkOrderTypeId = WorkOrderTypeId FROM DBO.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkorderId
				SELECT @TearDownTypeIds =  TearDownTypes FROM dbo.workorderquoteSettings WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND WorkOrderTypeId = @WorkOrderTypeId

			    SELECT DISTINCT tdt.CommonTearDownTypeId,
					ISNULL(td.ReasonName,'') ReasonName,
                    UPPER(ISNULL(td.TechnicalName,'')) as Technician,
                    UPPER(ISNULL(td.InspectorName,'')) as Inspector,
					REPLACE(REPLACE(ISNULL(td.Memo,''), '<p>', ''),'</p>','<br />') as Memo,
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
				FROM [dbo].[CommonTeardownType] tdt WITH(NOLOCK)
				LEFT JOIN [dbo].[CommonWorkOrderTearDown] td WITH(NOLOCK) ON td.CommonTearDownTypeId = tdt.CommonTearDownTypeId
					AND td.WorkOrderId = @WorkorderId AND td.WorkFlowWorkOrderId = @workFlowWorkOrderId AND Isnull(td.IsSubWorkOrder,0) = 0
				WHERE tdt.CommonTearDownTypeId IN (SELECT Item FROM DBO.SPLITSTRING(@TearDownTypeIds,','))
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