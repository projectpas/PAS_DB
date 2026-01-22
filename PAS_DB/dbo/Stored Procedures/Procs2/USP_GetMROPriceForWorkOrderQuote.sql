/*************************************************************           
 ** File: [USP_GetMROPriceForWorkOrderQuote]           
 ** Author:		 Moin Bloch
 ** Description: This Stored Procedure Is Used To Get MRO Price For Work Order Quote
 ** Purpose:         
 ** Date:   04-11-2025
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    04-11-2025		    Moin Bloch	        Created
	2    13/12/2025  Moin Bloch     Updated (Added Opr)
   
 --  EXEC [dbo].[USP_GetMROPriceForWorkOrderQuote]  97032, 152 ,4491, 12

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetMROPriceForWorkOrderQuote]
@ItemMasterId BIGINT = NULL,
@WorkOrderScopeId BIGINT = NULL,
@CustomerId BIGINT  = NULL,
@MasterCompanyId INT = NULL,
@Opr INT= NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @UnitPrice DECIMAL(18,2) = 0

		IF(@Opr=1)
		BEGIN
			SELECT TOP 1 @UnitPrice = ISNULL([FlatRatePrice],0)				 
			 FROM [dbo].[MROPriceMaster] WITH(NOLOCK)			
			WHERE CAST(GETUTCDATE() AS DATE) BETWEEN CAST([StartDate] AS DATE) AND CAST([EndDate] AS DATE)
			  AND [ItemMasterId] = @ItemMasterId
			  AND [WorkscopeId] = @WorkOrderScopeId
			  AND [CustomerId] = @CustomerId
			  AND [MasterCompanyId] = @MasterCompanyId
			  AND [IsActive] = 1
			  AND [IsDeleted] = 0	

			IF(@UnitPrice = 0)
			BEGIN			
				SELECT TOP 1 @UnitPrice = ISNULL([FlatRatePrice],0)				 
				 FROM [dbo].[MROPriceMaster] WITH(NOLOCK)			
				WHERE CAST(GETUTCDATE() AS DATE) BETWEEN CAST([StartDate] AS DATE) AND CAST([EndDate] AS DATE) 
				  AND [ItemMasterId] = @ItemMasterId
				  AND [WorkscopeId] = @WorkOrderScopeId			 
				  AND [MasterCompanyId] = @MasterCompanyId
				  AND [IsActive] = 1
				  AND [IsDeleted] = 0
				  AND [CustomerId] IS NULL
			END
		END
		IF(@Opr=2) 
		BEGIN
			SELECT TOP 1 @UnitPrice = ISNULL([FlatRatePrice],0)				 
			 FROM [dbo].[MROPriceMaster] WITH(NOLOCK)			
			WHERE [ItemMasterId] = @ItemMasterId
			  AND [WorkscopeId] = @WorkOrderScopeId
			  AND [CustomerId] = @CustomerId
			  AND [MasterCompanyId] = @MasterCompanyId
			  AND [IsActive] = 1
			  AND [IsDeleted] = 0	

			IF(@UnitPrice = 0)
			BEGIN			
				SELECT TOP 1 @UnitPrice = ISNULL([FlatRatePrice],0)				 
				 FROM [dbo].[MROPriceMaster] WITH(NOLOCK)			
				WHERE [ItemMasterId] = @ItemMasterId
				  AND [WorkscopeId] = @WorkOrderScopeId			 
				  AND [MasterCompanyId] = @MasterCompanyId
				  AND [IsActive] = 1
				  AND [IsDeleted] = 0
				  AND [CustomerId] IS NULL
			END
		END

		SELECT @UnitPrice [UnitPrice]
			
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  		
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetMROPriceForWorkOrderQuote'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END