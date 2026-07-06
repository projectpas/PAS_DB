/*************************************************************           
 ** File:   [GetLabourAuditList]           
 ** Author:   Subhash Saliya
 ** Description: Get Search Data for Labour Audit List    
 ** Purpose:         
 ** Date:   09/20/2021      
          
 ** PARAMETERS: @POId varchar(60)   
 ** RETURN VALUE:           
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/20/2021   Subhash Saliya Created
	2    03/04/2025   Ekta Chandegra    Convert date using dbo.ConvertUTCtoLocal
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
 EXECUTE [GetLabourAuditList] 14
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetLabourAuditList]
	@WorkOrderLaborId bigint = null,
	@EmployeeId bigint
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

				SELECT 
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						)
					FROM 
						dbo.Employee E WITH (NOLOCK) 
					LEFT JOIN 
						dbo.TimeZone ETZ WITH (NOLOCK) 
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN 
						dbo.LegalEntity LE WITH (NOLOCK) 
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN 
						dbo.TimeZone LTZ WITH (NOLOCK) 
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE 
						E.EmployeeId = @EmployeeId;

				SELECT	
					 wlb.WorkOrderLaborAuditId
					,wlb.WorkOrderLaborId
					,wlb.WorkOrderLaborAuditHeaderId
					,wlb.TaskId
					,wlb.ExpertiseId
					,wlb.EmployeeId
					,wlb.Hours
					,wlb.Adjustments
					,wlb.AdjustedHours
					,wlb.Memo
					,wlb.CreatedBy
					,wlb.UpdatedBy
					,(Cast(DBO.ConvertUTCtoLocal(wlb.CreatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS CreatedDate
					,(Cast(DBO.ConvertUTCtoLocal(wlb.UpdatedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS UpdatedDate
					,wlb.IsActive
					,wlb.IsDeleted
					,(Cast(DBO.ConvertUTCtoLocal(wlb.StartDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS StartDate
					,(Cast(DBO.ConvertUTCtoLocal(wlb.EndDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS EndDate
					,wlb.BillableId
					,wlb.IsFromWorkFlow
					,wlb.MasterCompanyId
					,wlb.TaskName
					,wlb.LabourExpertise
					,wlb.LabourEmployee
					,wlb.Billable
					,wlb.DirectLaborOHCost
					,wlb.BurdaenRatePercentageId
					,wlb.BurdenRateAmount
					,wlb.TotalCostPerHour
					,wlb.TotalCost
					,wlb.TaskStatusId
					,(Cast(DBO.ConvertUTCtoLocal(wlb.StatusChangedDate,@CurrntEmpTimeZoneDesc)AS DATETIME)) AS StatusChangedDate
					,wo.WorkOrderNum
					,im.partnumber AS PartNumber
					,im.PartDescription
					,ws.Stage
					,c.Name AS Customer
					,st.[Description] As [Status]
					,wop.NTE as nte
					,emps.StationName
					
					
				FROM dbo.WorkOrderLaborAudit wlb WITH(NOLOCK)
				INNER JOIN dbo.WorkOrderLaborHeaderAudit wlh WITH (NOLOCK) ON wlh.WorkOrderLaborHeaderId = wlb.WorkOrderLaborAuditHeaderId
				INNER JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
				INNER JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
				INNER JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
				INNER JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
				INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
				INNER JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
				LEFT JOIN dbo.TaskStatus st WITH (NOLOCK) ON st.TaskStatusId = wlb.TaskStatusId
				LEFT JOIN dbo.EmployeeStation emps WITH (NOLOCK) ON emps.EmployeeStationId = wop.TechStationId
				WHERE wlb.WorkOrderLaborId = @WorkOrderLaborId

				 AND ISNULL(im.IsNonStock,0) = 0
				 END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetLabourAuditList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderLaborId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END