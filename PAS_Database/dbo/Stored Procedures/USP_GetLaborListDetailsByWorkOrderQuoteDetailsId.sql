/*************************************************************           
 ** File:   [USP_GetLaborListDetailsByWorkOrderQuoteDetailsId]         
 ** Author:   Bhargav Saliya 
 ** Description: Get Labor List Details By WorkOrder Quote Details Id
 ** Purpose:         
 ** Date:   09-May-2025     
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    09-May-2025   Bhargav Saliya		Created

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetLaborListDetailsByWorkOrderQuoteDetailsId]
    @WorkOrderQuoteDetailsId BIGINT,
    @BuildMethodId BIGINT
AS
BEGIN

 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 SET NOCOUNT ON;
	 BEGIN TRY
		SELECT top 1
			lh.CreatedBy,
			lh.CreatedDate,
			lh.DataEnteredBy,
			lh.IsActive,
			lh.IsDeleted,
			lh.MasterCompanyId,
			lh.UpdatedBy,
			lh.UpdatedDate,
			lh.WorkOrderQuoteDetailsId,
			lh.WorkOrderQuoteLaborHeaderId,
			ISNULL(deby.FirstName, '') AS DataEnteredByName,
			lh.MarkupFixedPrice,
			lh.HeaderMarkupId,
			wq.LaborFlatBillingAmount,
			wq.MaterialFlatBillingAmount,
			wq.ChargesFlatBillingAmount,
			wq.FreightFlatBillingAmount
		FROM [dbo].[WorkOrderQuoteLaborHeader] lh WITH(NOLOCK)
			INNER JOIN [dbo].[WorkOrderQuoteDetails] wq WITH(NOLOCK) ON lh.WorkOrderQuoteDetailsId = wq.WorkOrderQuoteDetailsId
			LEFT JOIN [dbo].[Employee] deby WITH(NOLOCK) ON lh.DataEnteredBy = deby.EmployeeId
		WHERE ISNULL(lh.IsDeleted,0) = 0 AND lh.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;

		-- Result Set 2: Labor List
		SELECT 
			wol.BillableId,
			wol.CreatedBy,
			wol.CreatedDate,
			wol.ExpertiseId,
			wol.Expertise AS Expertise,
			wol.Hours,
			wol.IsActive,
			wol.IsDeleted,
			wol.TaskId,
			wol.TaskName AS Task,
			wol.UpdatedBy,
			wol.UpdatedDate,
			wol.WorkOrderQuoteLaborHeaderId,
			wol.WorkOrderQuoteLaborId,
			wol.DirectLaborOHCost,
			wol.MarkupPercentageId,
			wol.BurdenRateAmount,
			wol.TotalCostPerHour,
			wol.TotalCost,
			wol.BillingMethodId,
			wol.BillingRate,
			wol.BillingAmount,
			wol.BurdaenRatePercentageId,
			wol.EmployeeId,
			emp.FirstName + ' ' + emp.LastName AS EmployeeName,
			wol.Billabletype,
			wol.BurdaenRatePercentage
		FROM [dbo].[WorkOrderQuoteLabor] wol WITH(NOLOCK)
		LEFT JOIN [dbo].[EmployeeExpertise] expr WITH(NOLOCK) ON wol.ExpertiseId = expr.EmployeeExpertiseId
		LEFT JOIN [dbo].[Task] task WITH(NOLOCK) ON wol.TaskId = task.TaskId
		LEFT JOIN [dbo].[Employee] emp WITH(NOLOCK) ON wol.EmployeeId = emp.EmployeeId
		WHERE ISNULL(wol.IsDeleted,0) = 0 AND wol.WorkOrderQuoteLaborHeaderId IN (SELECT WorkOrderQuoteLaborHeaderId FROM [dbo].[WorkOrderQuoteLaborHeader] WITH(NOLOCK) WHERE IsDeleted = 0 AND WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId);
	END TRY
	BEGIN CATCH  
   
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME(),  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            @AdhocComments varchar(150) = 'USP_GetLaborListDetailsByWorkOrderQuoteDetailsId',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderQuoteDetailsId, '') AS varchar(100)) +    
            '@Parameter2 = ''' + CAST(ISNULL(@BuildMethodId, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'   
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
    EXEC Splogexception @DatabaseName = @DatabaseName,  
                        @AdhocComments = @AdhocComments,  
                        @ProcedureParameters = @ProcedureParameters,  
                        @ApplicationName = @ApplicationName,  
                        @ErrorLogID = @ErrorLogID OUTPUT;  
  
    RAISERROR (  
    'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'  
    , 16, 1, @ErrorLogID)  
  
    RETURN (1);  
	END CATCH
END;