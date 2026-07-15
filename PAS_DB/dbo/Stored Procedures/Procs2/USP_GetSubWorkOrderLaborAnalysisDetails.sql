
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.USP_GetSubWorkOrderLaborAnalysisDetails   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetSubWorkOrderLaborAnalysisDetails.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [USP_GetWorkOrderLaborAnalysisDetails]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Sub WorkOrder Labor Analysis Details    
 ** Purpose:         
 ** Date:   06/18/2021        
          
 ** PARAMETERS:           
 @SubWorkOrderPartNoId BIGINT   
 @IsDetailView BIT 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    02/22/2021   Hemant Saliya			Created
	2    12/22/2021   Devendra Shekh		added SubWorkOrderNo to select
    3    01/09/2025   Moin Bloch    Update Added StandardHours,StandardMinute,VarianceHours,VarianceMinute
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
 
 EXECUTE USP_GetSubWorkOrderLaborAnalysisDetails 331,122, 0

**************************************************************/ 
    
CREATE     PROCEDURE [dbo].[USP_GetSubWorkOrderLaborAnalysisDetails]    
(       
@WorkOrderId BIGINT = NULL, 
@SubWorkOrderPartNoId BIGINT  = NULL,
@IsDetailView BIT = false
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN  
				SELECT 
						im.partnumber AS PartNumber,
						im.PartDescription,
						im.RevisedPart AS RevisedPN,
						--ISNULL(SUM(wl.[Hours]),0) AS [Hours],
						ISNULL(ISNULL(SUM(wl.[Hours]), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) AS [Hours],
						ISNULL(SUM(wl.Adjustments),0) AS [Adjustments],
						ISNULL(SUM(wl.AdjustedHours),0) AS [AdjustedHours],
						ISNULL(SUM(wl.StandardHours),0) AS StandardHours,
						ISNULL(SUM(wl.StandardMinute),0) AS StandardMinute,
						ISNULL(SUM(wl.VarianceHours),0) AS VarianceHours,	
						ISNULL(SUM(wl.VarianceMinute),0) AS VarianceMinute,
						ISNULL(SUM(wl.BurdenRateAmount),0) AS BurdenRateAmount,
						CASE WHEN wl.BillableId = 1 THEN 'Billable' ELSE 'Non-Billable' END AS BillableOrNonBillable,
						c.[Name] AS Customer,
						wo.WorkOrderNum,
						swo.SubWorkOrderNo,
						ws.Stage,
						st.[Description] AS [Status],
						t.[Description] AS [Action],
						ex.[Description] AS Expertise,
						emp.FirstName + ' ' + emp.LastName AS EmployeeName,
						wl.EmployeeId
					FROM dbo.SubWorkOrderLaborHeader wlh WITH (NOLOCK)
						JOIN dbo.SubWorkOrderLabor wl WITH (NOLOCK) ON wl.SubWorkOrderLaborHeaderId = wlh.SubWorkOrderLaborHeaderId
						JOIN dbo.SubWorkOrderPartNumber wop WITH (NOLOCK) ON wlh.SubWOPartNoId = wop.SubWOPartNoId
						JOIN dbo.SubWorkOrder swo WITH (NOLOCK) ON wlh.SubWorkOrderId = swo.SubWorkOrderId
						JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
						JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.SubWorkOrderStageId
						JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
						JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
						JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON st.Id = wop.SubWorkOrderStatusId
						JOIN dbo.Task t WITH (NOLOCK) ON t.TaskId = wl.TaskId
						JOIN dbo.EmployeeExpertise ex WITH (NOLOCK) ON wl.ExpertiseId = ex.EmployeeExpertiseId	
						LEFT JOIN dbo.Employee emp WITH (NOLOCK) ON emp.EmployeeId = wl.EmployeeId
					WHERE wlh.SubWOPartNoId = @SubWorkOrderPartNoId AND wo.WorkOrderId = @WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1 --AND BillableId = 1 
					 AND ISNULL(im.IsNonStock,0) = 0
					 GROUP BY im.partnumber,im.PartDescription,im.RevisedPart,c.[Name] ,wo.WorkOrderNum,ws.Stage,BillableId,
						st.[Description],t.[Description],ex.[Description],emp.FirstName + ' ' + emp.LastName,wl.EmployeeId,swo.SubWorkOrderNo
		--	END
		--COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrderLaborAnalysisDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderPartNoId, '') + ''', 													   
													   @Parameter2 = ' + ISNULL(CAST(@isDetailView AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END