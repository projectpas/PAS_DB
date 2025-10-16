/*************************************************************           
 ** File:   [USP_CreateWorkOrderLaborHeader]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to update Revenue & Margin in Work Order and Sales Order
 ** Purpose:         
 ** Date:   15-10-2025         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------              
	1    15-10-2025   Moin Bloch       Created
	2    16-10-2025   Moin Bloch       Added  Revenue & Margin Percent From Employee If In Customer it's not available

--   EXEC [USP_UpdateSalesPersonDetails] 19841,1128,1,15
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateSalesPersonDetails]
@ReferenceId BIGINT = NULL,
@CustomerId BIGINT = NULL,
@MasterCompanyId INT = NULL,
@ModuleId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN	
	
	DECLARE @WorkOrderModuleID INT,@SalesOrderModuleID INT
	DECLARE @SalesPersonId BIGINT = NULL,@CSRId BIGINT = NULL,@SecondarySalesPersonId BIGINT = NULL,@SalesAgentID BIGINT = NULL;  
	DECLARE @PrimarySalesperson INT = 1,@SecondarySalesperson INT = 2,@Agent INT = 3,@CSR INT = 4
	DECLARE @MROActivity INT = 1,@Brokering INT = 2
	DECLARE @PrimarySalesRevenue BIGINT = NULL,@PrimarySalesMargin BIGINT = NULL
	DECLARE @SecondarySalesRevenue BIGINT = NULL,@SecondarySalesMargin BIGINT = NULL
	DECLARE @CSRSalesRevenue BIGINT = NULL,@CSRSalesMargin BIGINT = NULL
	DECLARE @AgentSalesRevenue BIGINT = NULL,@AgentSalesMargin BIGINT = NULL

	SELECT @WorkOrderModuleID  = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='WorkOrder';
	SELECT @SalesOrderModuleID = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName]='SalesOrder';
	
	SELECT TOP 1 @SalesPersonId = [PrimarySalesPersonId],
                 @CSRId = [CsrId],
	             @SecondarySalesPersonId = [SecondarySalesPersonId],
	             @SalesAgentID = [SaId] 
		    FROM [dbo].[CustomerSales] WITH(NOLOCK) 
		   WHERE [CustomerId] = @CustomerId 
		     AND [MasterCompanyId] = @MasterCompanyId 
		     AND [IsActive] = 1 
		     AND [IsDeleted] = 0;
	
	-- Set CSRId and SalesPersonId to NULL if 0
    IF @CSRId = 0
        SET @CSRId = NULL;
    IF @SalesPersonId = 0
        SET @SalesPersonId = NULL;
	IF @SecondarySalesPersonId = 0
	    SET @SecondarySalesPersonId = NULL;
	IF @SalesAgentID = 0
	    SET @SalesAgentID = NULL;	

	IF(@ModuleId = @WorkOrderModuleID)
	BEGIN
		-- Primary Salesperson
		SELECT @PrimarySalesRevenue = [RevenuePercentageId],@PrimarySalesMargin = [MarginPercentageId] FROM [dbo].[SalesPersonActivityType] WITH(NOLOCK) WHERE [DropdownTypeId] = @PrimarySalesperson AND [ActivityTypeId] = @MROActivity AND [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		-- Secondary Salesperson
		SELECT @SecondarySalesRevenue = [RevenuePercentageId],@SecondarySalesMargin = [MarginPercentageId] FROM [dbo].[SalesPersonActivityType] WITH(NOLOCK) WHERE [DropdownTypeId] = @SecondarySalesperson AND [ActivityTypeId] = @MROActivity AND [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		-- Customer Service Rep (CSR)
		SELECT @CSRSalesRevenue = [RevenuePercentageId],@CSRSalesMargin = [MarginPercentageId] FROM [dbo].[SalesPersonActivityType] WITH(NOLOCK) WHERE [DropdownTypeId] = @CSR AND [ActivityTypeId] = @MROActivity AND [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		-- Agent
		SELECT @AgentSalesRevenue = [RevenuePercentageId],@AgentSalesMargin = [MarginPercentageId] FROM [dbo].[SalesPersonActivityType] WITH(NOLOCK) WHERE [DropdownTypeId] = @Agent AND [ActivityTypeId] = @MROActivity AND [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		
		IF(ISNULL(@SalesPersonId, 0) != 0)
		BEGIN
			IF(ISNULL(@PrimarySalesRevenue, 0) = 0)
			BEGIN
				SELECT @PrimarySalesRevenue = [MRORevenuePercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SalesPersonId
			END
			IF(ISNULL(@PrimarySalesMargin, 0) = 0)
			BEGIN
				SELECT @PrimarySalesMargin = [MROMarginPercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SalesPersonId
			END
		END

		IF(ISNULL(@SecondarySalesPersonId, 0) != 0)
		BEGIN
			IF(ISNULL(@SecondarySalesRevenue, 0) = 0)
			BEGIN
				SELECT @SecondarySalesRevenue = [MRORevenuePercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SecondarySalesPersonId
			END
			IF(ISNULL(@SecondarySalesMargin, 0) = 0)
			BEGIN
				SELECT @SecondarySalesMargin = [MROMarginPercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SecondarySalesPersonId
			END
		END

		IF(ISNULL(@CSRId, 0) != 0)
		BEGIN
			IF(ISNULL(@CSRSalesRevenue, 0) = 0)
			BEGIN
				SELECT @CSRSalesRevenue = [MRORevenuePercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @CSRId
			END
			IF(ISNULL(@CSRSalesMargin, 0) = 0)
			BEGIN
				SELECT @CSRSalesMargin = [MROMarginPercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @CSRId
			END
		END

		IF(ISNULL(@SalesAgentID, 0) != 0)
		BEGIN
			IF(ISNULL(@AgentSalesRevenue, 0) = 0)
			BEGIN
				SELECT @AgentSalesRevenue = [MRORevenuePercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SalesAgentID
			END
			IF(ISNULL(@AgentSalesMargin, 0) = 0)
			BEGIN
				SELECT @AgentSalesMargin = [MROMarginPercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SalesAgentID
			END
		END

		UPDATE [dbo].[WorkOrder]
		   SET [SecondarySalesPersonId] = @SecondarySalesPersonId
			  ,[SalesAgentID] = @SalesAgentID
			  ,[PrimarySalesRevenue] = CASE WHEN ISNULL(@SalesPersonId,0) = 0 THEN 0 ELSE @PrimarySalesRevenue END 
			  ,[PrimarySalesMargin] =  CASE WHEN ISNULL(@SalesPersonId,0) = 0 THEN 0 ELSE @PrimarySalesMargin END 
			  ,[SecondarySalesRevenue] = CASE WHEN ISNULL(@SecondarySalesPersonId,0) = 0 THEN 0 ELSE @SecondarySalesRevenue END
			  ,[SecondarySalesMargin] =  CASE WHEN ISNULL(@SecondarySalesPersonId,0) = 0 THEN 0 ELSE @SecondarySalesMargin  END
			  ,[CSRSalesRevenue] = CASE WHEN ISNULL(@CSRId,0) = 0 THEN 0 ELSE @CSRSalesRevenue END
			  ,[CSRSalesMargin] =  CASE WHEN ISNULL(@CSRId,0) = 0 THEN 0 ELSE @CSRSalesMargin END
			  ,[AgentSalesRevenue] = CASE WHEN ISNULL(@SalesAgentID,0) = 0 THEN 0 ELSE @AgentSalesRevenue END
			  ,[AgentSalesMargin] = CASE WHEN ISNULL(@SalesAgentID,0) = 0 THEN 0 ELSE @AgentSalesMargin END
		 WHERE [WorkOrderId] = @ReferenceId

	END
	IF(@ModuleId = @SalesOrderModuleID)
	BEGIN
		-- Primary Salesperson
		SELECT @PrimarySalesRevenue = [RevenuePercentageId],@PrimarySalesMargin = [MarginPercentageId] FROM [dbo].[SalesPersonActivityType] WITH(NOLOCK) WHERE [DropdownTypeId] = @PrimarySalesperson AND [ActivityTypeId] = @Brokering AND [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		-- Secondary Salesperson
		SELECT @SecondarySalesRevenue = [RevenuePercentageId],@SecondarySalesMargin = [MarginPercentageId] FROM [dbo].[SalesPersonActivityType] WITH(NOLOCK) WHERE [DropdownTypeId] = @SecondarySalesperson AND [ActivityTypeId] = @Brokering AND [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		-- Customer Service Rep (CSR)
		SELECT @CSRSalesRevenue = [RevenuePercentageId],@CSRSalesMargin = [MarginPercentageId] FROM [dbo].[SalesPersonActivityType] WITH(NOLOCK) WHERE [DropdownTypeId] = @CSR AND [ActivityTypeId] = @Brokering AND [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		-- Agent
		SELECT @AgentSalesRevenue = [RevenuePercentageId],@AgentSalesMargin = [MarginPercentageId] FROM [dbo].[SalesPersonActivityType] WITH(NOLOCK) WHERE [DropdownTypeId] = @Agent AND [ActivityTypeId] = @Brokering AND [CustomerId] = @CustomerId AND [MasterCompanyId] = @MasterCompanyId AND [IsActive] = 1 AND [IsDeleted] = 0;
		

		IF(ISNULL(@SalesPersonId, 0) != 0)
		BEGIN
			IF(ISNULL(@PrimarySalesRevenue, 0) = 0)
			BEGIN
				SELECT @PrimarySalesRevenue = [BrokeringRevenuePercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SalesPersonId
			END
			IF(ISNULL(@PrimarySalesMargin, 0) = 0)
			BEGIN
				SELECT @PrimarySalesMargin = [BrokeringMarginPercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SalesPersonId
			END
		END

		IF(ISNULL(@SecondarySalesPersonId, 0) != 0)
		BEGIN
			IF(ISNULL(@SecondarySalesRevenue, 0) = 0)
			BEGIN
				SELECT @SecondarySalesRevenue = [BrokeringRevenuePercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SecondarySalesPersonId
			END
			IF(ISNULL(@SecondarySalesMargin, 0) = 0)
			BEGIN
				SELECT @SecondarySalesMargin = [BrokeringMarginPercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SecondarySalesPersonId
			END
		END

		IF(ISNULL(@CSRId, 0) != 0)
		BEGIN
			IF(ISNULL(@CSRSalesRevenue, 0) = 0)
			BEGIN
				SELECT @CSRSalesRevenue = [BrokeringRevenuePercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @CSRId
			END
			IF(ISNULL(@CSRSalesMargin, 0) = 0)
			BEGIN
				SELECT @CSRSalesMargin = [BrokeringMarginPercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @CSRId
			END
		END

		IF(ISNULL(@SalesAgentID, 0) != 0)
		BEGIN
			IF(ISNULL(@AgentSalesRevenue, 0) = 0)
			BEGIN
				SELECT @AgentSalesRevenue = [BrokeringRevenuePercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SalesAgentID
			END
			IF(ISNULL(@AgentSalesMargin, 0) = 0)
			BEGIN
				SELECT @AgentSalesMargin = [BrokeringMarginPercentageId] FROM [dbo].[Employee] WITH(NOLOCK) WHERE [EmployeeId] = @SalesAgentID
			END
		END

		UPDATE [dbo].[SalesOrder]
		   SET [SecondarySalesPersonId] = @SecondarySalesPersonId
			  ,[SalesAgentID] = @SalesAgentID
			  ,[PrimarySalesRevenue] = CASE WHEN ISNULL(@SalesPersonId,0) = 0 THEN 0 ELSE @PrimarySalesRevenue END 
			  ,[PrimarySalesMargin] =  CASE WHEN ISNULL(@SalesPersonId,0) = 0 THEN 0 ELSE @PrimarySalesMargin END 
			  ,[SecondarySalesRevenue] = CASE WHEN ISNULL(@SecondarySalesPersonId,0) = 0 THEN 0 ELSE @SecondarySalesRevenue END
			  ,[SecondarySalesMargin] =  CASE WHEN ISNULL(@SecondarySalesPersonId,0) = 0 THEN 0 ELSE @SecondarySalesMargin  END
			  ,[CSRSalesRevenue] = CASE WHEN ISNULL(@CSRId,0) = 0 THEN 0 ELSE @CSRSalesRevenue END
			  ,[CSRSalesMargin] =  CASE WHEN ISNULL(@CSRId,0) = 0 THEN 0 ELSE @CSRSalesMargin END
			  ,[AgentSalesRevenue] = CASE WHEN ISNULL(@SalesAgentID,0) = 0 THEN 0 ELSE @AgentSalesRevenue END
			  ,[AgentSalesMargin] = CASE WHEN ISNULL(@SalesAgentID,0) = 0 THEN 0 ELSE @AgentSalesMargin END
		 WHERE [SalesOrderId] = @ReferenceId
	END
			
	END
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
        ROLLBACK TRAN;
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateSalesPersonDetails' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100)) + 			                                         
													 '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
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
        END CATCH     
END