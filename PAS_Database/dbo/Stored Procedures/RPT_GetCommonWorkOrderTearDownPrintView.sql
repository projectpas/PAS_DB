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
	2    19/10/2026   Moin Bloch			PN-17943 Added EmployeeInitials for Technician, [Inspector]     
	
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

				DECLARE @SARMasterCompanyCode VARCHAR(50);
				DECLARE @MasterCompanyCode VARCHAR(50);
				DECLARE @MasterCompanyId AS INT = 0;				

				SELECT @ItemMasterIdlist = [TearDownTypes],@MasterCompanyId = [MasterCompanyId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE WorkOrderId = @WorkorderId

				SELECT @MasterCompanyCode = [MasterCompanyCode] FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;

				SELECT @SARMasterCompanyCode = MasterCompanyCode FROM [dbo].[MasterCompany] WITH(NOLOCK) WHERE UPPER(MasterCompanyCode) = UPPER('SAR');

			    SELECT DISTINCT tdt.[CommonTearDownTypeId],
					ISNULL(td.[ReasonName],'') ReasonName,                    
					CASE
						WHEN @SARMasterCompanyCode = @MasterCompanyCode
							THEN UPPER(COALESCE(NULLIF(em.[EmployeeInitials], ''), ISNULL(td.[TechnicalName], '')))
						ELSE UPPER(ISNULL(td.[TechnicalName], ''))
					END AS [Technician],
					CASE
						WHEN @SARMasterCompanyCode = @MasterCompanyCode
							THEN UPPER(COALESCE(NULLIF(ei.[EmployeeInitials], ''), ISNULL(td.[InspectorName], '')))
						ELSE UPPER(ISNULL(td.[InspectorName], ''))
					END AS [Inspector],                    
					REPLACE(REPLACE(ISNULL(td.[Memo],''), '<p>', ''),'</p>','<br />') AS [Memo],                   
					td.[TechnicianDate],
                    td.[InspectorDate] AS InspectorDate,
                    td.[IsDocument] AS IsDocumentAdded,
					tdt.[Name] AS TearDownType,
					ISNULL(tdt.[IsTechnician],0) AS IsTechnician,
					tdt.[IsDate],
					ISNULL(tdt.[IsInspector],0) AS IsInspector,
					ISNULL(tdt.[IsInspectorDate],'') AS IsInspectorDate,
					tdt.[IsDocument],
					tdt.[Sequence],
					tdt.[DocumentModuleName]
				FROM [dbo].[CommonTeardownType] tdt WITH(NOLOCK)
				LEFT JOIN [dbo].[CommonWorkOrderTearDown] td WITH(NOLOCK) ON td.[CommonTearDownTypeId] = tdt.[CommonTearDownTypeId] AND td.WorkOrderId = @WorkorderId AND td.[WorkFlowWorkOrderId] = @workFlowWorkOrderId AND Isnull(td.IsSubWorkOrder,0) = 0
				LEFT JOIN [dbo].[Employee] em WITH(NOLOCK) ON em.[EmployeeId] = td.[TechnicianId]				
				LEFT JOIN [dbo].[Employee] ei WITH(NOLOCK) ON ei.[EmployeeId] = td.[InspectorId]
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