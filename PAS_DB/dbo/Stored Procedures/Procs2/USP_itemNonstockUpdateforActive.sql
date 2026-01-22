/*************************************************************           
 ** File:		 [dbo].[USP_itemNonstockUpdateforActive]         
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Update status of active & inactive 
 ** Purpose:         
 ** Date:   26-09-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	---------------------  
	1	 26-09-2025			 Nakul Chandigra	 Created
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_itemNonstockUpdateforActive]
@Id BIGINT ,
@IsActive BIT, 
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @MasterPartId BIT;
	SELECT @MasterPartId = MasterPartId
	FROM [dbo].[itemMasterNonStock] WITH (NOLOCK)
	WHERE ItemMasterNonStockId = @Id

	UPDATE [dbo].[itemMasterNonStock]	
	SET [IsActive] = @IsActive  ,
		[UpdatedDate] = GETUTCDATE(),
		[UpdatedBy] = @UpdatedBy
	WHERE ItemMasterNonStockId = @Id
	
	UPDATE [dbo].[MasterParts]	
	SET [IsActive] = @IsActive ,
		[UpdatedDate] = GETUTCDATE(),
		[UpdatedBy] = @UpdatedBy
	WHERE MasterPartId = @Id

	SELECT [ItemMasterNonStockId]
      ,[MasterPartId]
      ,[PartNumber]
      ,[PartDescription]
      ,[ItemNonStockClassificationId]
      ,[ItemTypeId]
      ,[ItemGroupId]
      ,[IsAcquiredMethodBuy]
      ,[ManufacturerId]
      ,[MasterCompanyId]
      ,[DiscountPurchasePercent]
      ,[GLAccountId]
      ,[PurchaseUnitOfMeasureId]
      ,[IsHazardousMaterial]
      ,[CurrencyId]
      ,[UnitCost]
      ,[ListPrice]
      ,[PriceDate]
      ,[IsActive]
      ,[IsDeleted]
      ,[CreatedBy]
      ,[CreatedDate]
      ,[UpdatedBy]
      ,[UpdatedDate]
      ,[SiteId]
      ,[WarehouseId]
      ,[LocationId]
      ,[ShelfId]
      ,[BinId]
      ,[IsSerialized]
      ,[IsMfgExpirationDate]
      ,[LeadTimeDays]
      ,[StockLevel]
      ,[ReorderPoint]
      ,[ReorderQuantiy]
      ,[InWarranty]
      ,[CurrentStlNo]
      ,[Site]
      ,[Warehouse]
      ,[Location]
      ,[Shelf]
      ,[Bin]
      ,[ItemNonStockClassification]
      ,[GLAccount]
      ,[Currency]
      ,[Manufacturer]
      ,[MfgExpirationDate]
  FROM [dbo].[ItemMasterNonStock]
 WITH (NOLOCK) WHERE ItemMasterNonStockId = @Id

	COMMIT  TRANSACTION 
	END TRY 
	BEGIN CATCH 
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE---------------------------------------- 
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_itemNonstockUpdateforActive]' 
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
	END CATCH

END