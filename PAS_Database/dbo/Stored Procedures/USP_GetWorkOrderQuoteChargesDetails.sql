/*************************************************************           
 ** File:   [USP_GetWorkOrderQuoteChargesDetails]           
 ** Author:   Bhargav Saliya 
 ** Description: Get WorkOrder Charges Details
 ** Purpose:         
 ** Date:   06-May-2025      
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			 Author			Change Description            
 ** --   --------		 -------		--------------------------------          
    1    06-May-2025   Bhargav Saliya		Created
    2    20-Aug-2026   Sumit Kumar     Modified to prepend sequence number to task name for duplicate tasks on Dynamic WOs [PN-17643]

	EXEC [USP_GetWorkOrderQuoteChargesDetails]  @WorkOrderQuoteDetailsId = 6803, @BuildMethodId = 4
**************************************************************/
CREATE   PROCEDURE	[dbo].[USP_GetWorkOrderQuoteChargesDetails]
    @WorkOrderQuoteDetailsId BIGINT,
	@BuildMethodId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @WorkOrderId BIGINT;
		DECLARE @WorkOrderPartNumberId BIGINT;
		DECLARE @WorkOrderFormTypeId BIT;
		DECLARE @GLAllocationName VARCHAR(50) = 'As Per GL Allocation';

		-- Get WorkOrderId and WorkOrderPartNumberId from WorkOrderQuoteDetails
		SELECT TOP 1 @WorkOrderId = woq.WorkOrderId, @WorkOrderPartNumberId = wq.WOPartNoId
		FROM [dbo].[WorkOrderQuoteDetails] wq WITH(NOLOCK)
		INNER JOIN WorkOrderQuote woq ON wq.WorkOrderQuoteId = woq.WorkOrderQuoteId
		WHERE wq.IsDeleted = 0 AND wq.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;

		-- Get WorkOrderFormTypeId from WorkOrder
		SELECT TOP 1 @WorkOrderFormTypeId = WorkOrderFormTypeId
		FROM [dbo].[WorkOrder] WITH(NOLOCK)
		WHERE WorkOrderId = @WorkOrderId;

		-- Declare and populate table variable to get active task counts to detect duplicates 
		DECLARE @DupTasks TABLE (TaskId BIGINT, TaskCount INT);

		INSERT INTO @DupTasks (TaskId, TaskCount)
		SELECT TaskId, COUNT(*) AS TaskCount
		FROM [dbo].[WorkOrderTask] WITH(NOLOCK)
		WHERE WorkOrderId = @WorkOrderId 
		  AND WorkOrderPartNumberId = @WorkOrderPartNumberId
		  AND [IsActive] = 1 AND [IsDeleted] = 0
		GROUP BY TaskId;

		SELECT DISTINCT
			woc.ChargesTypeId,
			ct.ChargeType,
			woc.Description,
			woc.Quantity,
			woc.UnitCost,
			woc.ExtendedCost,
			woc.VendorId,
			v.VendorName,
			woc.CreatedBy,
			woc.CreatedDate,
			woc.IsActive,
			woc.IsDeleted,
			woc.MarkupPercentageId,
			woc.MasterCompanyId,
			woc.UpdatedBy,
			woc.UpdatedDate,
			woc.WorkOrderQuoteDetailsId,
			woc.WorkOrderQuoteChargesId,
			woc.ChargesTypeId AS WorkflowChargeTypeId,
			woc.TaskId,
			CASE 
				WHEN @WorkOrderFormTypeId = 1 
                     THEN (CASE WHEN ISNULL(Dup.TaskCount, 0) > 1 AND ISNULL(wott.[SequenceNumber], '') <> '' 
                                THEN wott.[SequenceNumber] + ' - ' + wott.[TaskName] 
                                ELSE wott.[TaskName] 
                           END)
				ELSE ISNULL(ts.Description, '')
			END as TaskName, -- Prepend sequence number to TaskName if duplicate tasks exist 
			woc.MarkupFixedPrice,
			woc.BillingMethodId,
			woc.HeaderMarkupId,
			woc.BillingRate,
			woc.BillingAmount,
			@GLAllocationName AS GLAccountName,
			uom.ShortName AS uom,
			woc.UOMId
		FROM [dbo].[WorkOrderQuoteCharges] woc WITH(NOLOCK)
		INNER JOIN [dbo].[WorkOrderQuoteDetails] wq WITH(NOLOCK) ON woc.WorkOrderQuoteDetailsId = wq.WorkOrderQuoteDetailsId
		INNER JOIN [dbo].[Charge] ct WITH(NOLOCK) ON woc.ChargesTypeId = ct.ChargeId
		LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON woc.VendorId = v.VendorId
		LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON woc.TaskId = ts.TaskId
		LEFT JOIN [dbo].[WorkOrderTask] wott WITH(NOLOCK) ON woc.TaskId = wott.WorkOrderTaskId
		-- Join to get active task counts to detect duplicates 
		LEFT JOIN @DupTasks Dup ON wott.TaskId = Dup.TaskId
		LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId
		LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON woc.UOMId = uom.UnitOfMeasureId
		WHERE woc.IsDeleted = 0 AND woc.WorkOrderQuoteDetailsId = @WorkOrderQuoteDetailsId;
	END TRY
	BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderQuoteChargesDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderQuoteDetailsId, '') + ''
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