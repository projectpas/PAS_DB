/*************************************************************           
 ** File:   [USP_GetCustomerTax_Information_Repair_WO]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to get Customer Tax Information based on Reapir
 ** Purpose:         
 ** Date:   02/23/2024        
          
 ** PARAMETERS: @WorkOrderId BIGINT,@WorkOrderPartId BIGINT,@CustomerId BIGINT,@MasterCompanyId INT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/23/2024   Moin Bloch    Created
     
-- EXEC [USP_GetCustomerTax_Information_Repair_WO] 4111,3604,77,1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetCustomerTax_Information_Repair_WO] 
@WorkOrderId BIGINT,
@WorkOrderPartId BIGINT,
@CustomerId BIGINT,
@MasterCompanyId INT
AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
	  DECLARE @TotalRecord INT = 0; 
	  DECLARE @MinId BIGINT = 1; 
	  DECLARE @OriginSiteId BIGINT = 0;
	  DECLARE @ShipToSiteId BIGINT = 0;
	  DECLARE @TotalSalesTax Decimal(18,2) = 0;
	  DECLARE @TotalOtherTax Decimal(18,2) = 0;	 

		IF OBJECT_ID(N'tempdb..#tmprwoShipDetails') IS NOT NULL
		BEGIN
			DROP TABLE #tmprwoShipDetails
		END
		
		CREATE TABLE #tmprwoShipDetails
		(
			[ID] BIGINT NOT NULL IDENTITY, 		
			[OriginSiteId] BIGINT NULL,
			[ShipToSiteId] BIGINT NULL,
			[CustomerId]  BIGINT NULL,
			[WorkOrderId] BIGINT NULL,
			[WorkOrderPartId] BIGINT NULL,
			[SalesTax] DECIMAL(18,2) NULL,
			[OtherTax]  DECIMAL(18,2) NULL				
		)
		
		INSERT INTO #tmprwoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderPartId])				 			
							 SELECT WOS.[OriginSiteId],
									WOS.[ShipToSiteId],
	  									@CustomerId,
										@WorkOrderId,
										@WorkOrderPartId
									 FROM [dbo].[WorkOrderShipping] WOS WITH(NOLOCK)  
									 INNER JOIN [dbo].[WorkOrderShippingItem] WOSI WITH(NOLOCK) ON WOS.[WorkOrderShippingId]  = WOSI.[WorkOrderShippingId]
									  WHERE WOS.[WorkOrderId] = @WorkOrderId AND WOSI.[WorkOrderPartNumId] = @WorkOrderPartId
										AND WOS.[IsActive] = 1 
										AND WOS.[IsDeleted] = 0;
           
		INSERT INTO #tmprwoShipDetails ([OriginSiteId],[ShipToSiteId],[CustomerId],[WorkOrderId],[WorkOrderPartId])				 			
							 SELECT STK.[SiteId],
									CDS.[CustomerDomensticShippingId], 
										@CustomerId,
										@WorkOrderId,
										@WorkOrderPartId								
								   FROM [dbo].[WorkOrder] WO WITH(NOLOCK) 
							 INNER JOIN [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WO.[WorkOrderId] = WOP.[WorkOrderId] 
							 INNER JOIN [dbo].[Stockline] STK WITH(NOLOCK) ON WOP.[StockLineId] = STK.[StockLineId]
							 INNER JOIN [dbo].[CustomerDomensticShipping] CDS WITH(NOLOCK) ON CDS.[CustomerId] = WO.[CustomerId] AND CDS.[IsPrimary] = 1
							   WHERE WO.[WorkOrderId] = @WorkOrderId  
								AND WOP.[ID] = @WorkOrderPartId
								AND WOP.[ID] NOT IN (SELECT WorkOrderPartId FROM #tmprwoShipDetails)									
																
		SELECT @TotalRecord = MAX(ID), @MinId = MIN(ID) FROM #tmprwoShipDetails    
	
		WHILE @MinId <= @TotalRecord
		BEGIN
			SELECT @OriginSiteId = [OriginSiteId],
				   @ShipToSiteId = [ShipToSiteId],
				   @CustomerId   = [CustomerId],
				   @WorkOrderPartId = [WorkOrderPartId]
			  FROM #tmprwoShipDetails WHERE ID = @MinId		
					
			EXEC [dbo].[USP_GetCustomerTax_Information_Repair] 
					 @CustomerId,
					 @ShipToSiteId,
					 @OriginSiteId,
					 @TotalSalesTax = @TotalSalesTax OUTPUT,
					 @TotalOtherTax = @TotalOtherTax OUTPUT										
				
			SET @MinId = @MinId + 1
		END
				
		SELECT  ISNULL(@TotalSalesTax,0) AS SalesTax,ISNULL(@TotalOtherTax,0) AS OtherTax;
	 	
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetCustomerTax_Information_Repair_WO]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END