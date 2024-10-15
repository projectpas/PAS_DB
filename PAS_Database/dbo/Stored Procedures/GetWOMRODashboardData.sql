/*****************************************************************************************           
 ** File:   [GetWOMRODashboardData]        
 ** Author:   Shrey Chandegara
 ** Description: This stored procedure is used Display WO MRODashBoardData
 ** Purpose:         
 ** Date:   22-11-2023      
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author			Change Description            
 ** --   --------         -------			----------------------------   
    1    2 Nov 2024		Shrey Chandegara		CREATED   
	
	EXEC dbo.GetWOMRODashboardData @MasterCompanyId=1,@StartDate='2024-10-02 00:00:00',@EmployeeId=2,@ManagementStructureId=1
*********************************************************************************************/
CREATE     PROCEDURE [dbo].[GetWOMRODashboardData]
	@MasterCompanyId INT = NULL,
	@StartDate DATETIME = NULL,
	@EmployeeId BIGINT = NULL,
	@ManagementStructureId BIGINT = NULL
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY
	BEGIN
		DECLARE @WOQApproveStatus AS INT;
		DECLARE @WOReceiptUnits AS INT;
		DECLARE @WOQNonFlatAmount AS DECIMAL(20, 2);
		DECLARE @WOQFlatAmount AS DECIMAL(20, 2);
		DECLARE @WOQApprovalNonFlatAmount AS DECIMAL(20, 2);
		DECLARE @WOQApprovalFlatAmount AS DECIMAL(20, 2);
		DECLARE @WOQuotedUnits AS INT;
		DECLARE @WOQuotedAmount AS DECIMAL(20, 2);
		DECLARE @WOApprovalUnits AS INT;
		DECLARE @WOApprovalAmount AS DECIMAL(20, 2);
		DECLARE @WOBillingUnits AS INT;
		DECLARE @WOBillingAmount AS DECIMAL(20, 2);
		DECLARE @WOMTDUnits AS INT;
		DECLARE @WOMTDAmount AS DECIMAL(20, 2);

		SET @WOQApproveStatus = (SELECT WorkOrderQuoteStatusId FROM [dbo].[WorkOrderQuoteStatus] WHERE Description = 'Approved')
		SET @WOReceiptUnits = (SELECT COUNT(ReceivingCustomerWorkId) FROM [dbo].[ReceivingCustomerWork] RC WITH (NOLOCK)
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE   RC.IsPiecePart = 0 AND  RC.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,RC.CreatedDate)= @StartDate);

		SET @WOQuotedUnits = (SELECT COUNT(WorkOrderQuoteId) FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE WOQ.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WOQ.CreatedDate)= @StartDate);

		SET @WOQNonFlatAmount =	(SELECT ISNULL(SUM(WOQD.LaborFlatBillingAmount),0) + ISNULL(SUM(WOQD.MaterialFlatBillingAmount),0) + ISNULL(SUM(WOQD.ChargesFlatBillingAmount),0) + ISNULL(SUM(FreightFlatBillingAmount),0) 
								FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
								INNER JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH(NOLOCK) ON WOQD.WorkOrderQuoteId = WOQ.WOrkOrderQUoteID
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE   WOQ.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WOQ.CreatedDate)= @StartDate AND WOQD.QuoteMethod = 0);

		SET @WOQFlatAmount =	(SELECT ISNULL(SUM(WOQD.CommonFlatRate),0) FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
								INNER JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH(NOLOCK) ON WOQD.WorkOrderQuoteId = WOQ.WOrkOrderQUoteID
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE  WOQ.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WOQ.CreatedDate)= @StartDate AND WOQD.QuoteMethod = 1);
		
		SET @WOQuotedAmount = (@WOQFlatAmount + @WOQNonFlatAmount)


		SET @WOApprovalUnits = (SELECT COUNT(WorkOrderQuoteId) FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE  WOQ.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WOQ.ApprovedDate)= @StartDate AND WOQ.QuoteStatusId = @WOQApproveStatus)

		SET @WOQApprovalNonFlatAmount = (SELECT ISNULL(SUM(WOQD.LaborFlatBillingAmount),0) + ISNULL(SUM(WOQD.MaterialFlatBillingAmount),0) + ISNULL(SUM(WOQD.ChargesFlatBillingAmount),0) + ISNULL(SUM(FreightFlatBillingAmount),0) FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
											INNER JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH(NOLOCK) ON WOQD.WorkOrderQuoteId = WOQ.WOrkOrderQUoteID
											INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
											INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
											WHERE  WOQ.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WOQ.CreatedDate)= @StartDate AND WOQD.QuoteMethod = 0 AND WOQ.QuoteStatusId = @WOQApproveStatus);

		SET @WOQApprovalFlatAmount = (SELECT ISNULL(SUM(WOQD.CommonFlatRate),0) FROM [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK)
										INNER JOIN [dbo].[WorkOrderQuoteDetails] WOQD WITH(NOLOCK) ON WOQD.WorkOrderQuoteId = WOQ.WOrkOrderQUoteID
										INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
										INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
										WHERE WOQ.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WOQ.CreatedDate)= @StartDate AND WOQD.QuoteMethod = 1 AND WOQ.QuoteStatusId = @WOQApproveStatus);

		SET @WOApprovalAmount = (@WOQApprovalNonFlatAmount + @WOQApprovalFlatAmount);

		SET @WOBillingUnits = (SELECT COUNT(WBI.BillingInvoicingId) FROM [dbo].[WorkOrderBillingInvoicing] WBI WITH(NOLOCK)
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE   WBI.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WBI.CreatedDate)= @StartDate AND WBI.IsVersionIncrease = 0 AND ISNULL(WBI.IsPerformaInvoice,0) != 1)
		
		SET @WOBillingAmount = (SELECT ISNULL(SUM(WBI.GrandTotal),0) FROM [dbo].[WorkOrderBillingInvoicing] WBI WITH(NOLOCK)
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE  WBI.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WBI.CreatedDate)= @StartDate AND WBI.IsVersionIncrease = 0 AND ISNULL(WBI.IsPerformaInvoice,0) != 1) 


		SET @WOMTDUnits = (SELECT COUNT(WBI.BillingInvoicingId) FROM [dbo].[WorkOrderBillingInvoicing] WBI WITH(NOLOCK)
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE  WBI.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WBI.CreatedDate) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
								AND @StartDate AND WBI.IsVersionIncrease = 0 AND ISNULL(WBI.IsPerformaInvoice,0) != 1)



		
		SET @WOMTDAmount = (SELECT ISNULL(SUM(WBI.GrandTotal),0) FROM [dbo].[WorkOrderBillingInvoicing] WBI WITH(NOLOCK)
								INNER JOIN [dbo].[RoleManagementStructure] RMS WITH (NOLOCK) ON  RMS.EntityStructureId = @ManagementStructureId
								INNER JOIN [dbo].[EmployeeUserRole] EUR WITH (NOLOCK) ON EUR.RoleId = RMS.RoleId AND EUR.EmployeeId = @EmployeeId
								WHERE	 WBI.MasterCompanyId = @MasterCompanyId AND CONVERT(DATE,WBI.CreatedDate) BETWEEN DATEFROMPARTS(YEAR(@StartDate), MONTH(@StartDate), 1) 
								AND @StartDate AND WBI.IsVersionIncrease = 0 AND ISNULL(WBI.IsPerformaInvoice,0) != 1)						
		--SET @WOQFlatAmount = (SELECT ISNULL(SUM(CommonFlatRate),0) FROM [dbo].[WorkOrderQuoteDetails] WOQD WITH(NOLOCK) WHERE WOQD.WorkOrderQuoteId IN (@WOQFlatIDs))
		--SET @WOQNonFlatAmount = (SELECT ISNULL(SUM(LaborFlatBillingAmount),0) + ISNULL(SUM(MaterialFlatBillingAmount),0) + ISNULL(SUM(ChargesFlatBillingAmount),0) + ISNULL(SUM(FreightFlatBillingAmount),0) FROM [dbo].[WorkOrderQuoteDetails] WOQD WITH(NOLOCK) WHERE WOQD.WorkOrderQuoteId IN (@WOQNonFlatIDs))

		
		
		SELECT  @WOReceiptUnits AS WoReceiptUnits,
			    @WOQuotedUnits AS WoQuotedUnits,
				@WOQuotedAmount AS WoQuotedAmount,
				@WOApprovalUnits AS WoApprovalUnits,
				@WOApprovalAmount AS WoApprovalAmount,
				@WOBillingUnits AS WoBillingUnits,
				@WOBillingAmount AS WoBillingAmount,
				@WOMTDUnits AS WoMTDUnits,
				@WOMTDAmount AS WoMTDAmount
	END
	END TRY
	BEGIN CATCH      
		IF @@trancount > 0
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetWOMRODashboardData' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '
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