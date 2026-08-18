/*************************************************************           
 ** File:   [QuickBooks_GetItemDetailsForUpdateItem]           
 ** Author:   Abhishek Jirawla
 ** Description: Get Item Details to Update Item in QuickBooks    
 ** Purpose:         
 ** Date:   07-Feb-2025       
         
 ** RETURN VALUE: 
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    07-Feb-2025   Abhishek Jirawla	Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
     
 EXECUTE [QuickBooks_GetNewItemListForCreateItem] 1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[QuickBooks_GetItemDetailsForUpdateItem]
	@IntegrationTypeId INT = NULL,
	@MasterCompanyId INT = NULL,
	@ReferenceId BIGINT = NULL
AS
BEGIN
	DECLARE @InvModuleId INT = 0;
	DECLARE @InvModuleName VARCHAR(200) = '';
	
	SELECT @InvModuleId = AccountingModuleId, @InvModuleName = AccountingModuleName FROM [dbo].[AccountingModule] WITH(NOLOCK) WHERE UPPER([AccountingModuleName]) = 'ItemMaster';

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

		-- FOR QuickBooks
		IF(ISNULL(@IntegrationTypeId, 0) = 1) 
		BEGIN
			SELECT IM.ItemMasterId, 
				IM.partnumber, 
				IM.PartDescription,
				IM.ManufacturerId,
				IM.ManufacturerName,
				--CAST(stl.QuantityOnHand AS varchar) 'QuantityOnHand',  
				--CAST(stl.QuantityAvailable AS varchar) 'QuantityAvailable',  
				--CAST(stl.UnitCost AS varchar) 'UnitCost',
				CAST(0 AS varchar) AS 'QuantityOnHand',
				CAST(0 AS varchar) AS 'QuantityAvailable',
				(SELECT UnitCost FROM DBO.Stockline WITH(NOLOCK) WHERE ItemMasterId = IM.ItemMasterId AND isDeleted = 0 AND isActive = 1 AND StocklineId = (SELECT MAX(StockLineId) FROM DBO.Stockline WITH(NOLOCK) WHERE ItemMasterId = IM.ItemMasterId  AND isDeleted = 0 AND isActive = 1)) AS 'UnitCost',
				GLIncome.QuickBooksReferenceId AS IncomeAccountId,
				GLIncome.AccountName AS IncomeAccountName,
				GLAsset.QuickBooksReferenceId AS AssetAccountId,
				GLAsset.AccountName AS AssetAccountName,
				GLExpense.QuickBooksReferenceId AS ExpenseAccountId,
				GLExpense.AccountName AS ExpenseAccountName,
				@InvModuleName AS ModuleName,
				@InvModuleId AS ModuleId,
				IM.MasterCompanyId,
				IM.UpdatedBy,
				IM.CreatedDate,
				IM.QuickBooksReferenceId AS ItemQuickBooksReferenceId,
				IM.SyncToken
			FROM DBO.ItemMaster IM WITH(NOLOCK)
				INNER JOIN DBO.GLAccount GLIncome WITH(NOLOCK) ON IM.RevenueSoGLAccId = GLIncome.GLAccountId
				INNER JOIN DBO.GLAccount GLAsset WITH(NOLOCK) ON IM.GLAccountId = GLAsset.GLAccountId
				INNER JOIN DBO.GLAccount GLExpense WITH(NOLOCK) ON IM.COGS_SalesOrderGLAccId = GLExpense.GLAccountId
			WHERE ISNULL(IM.QuickBooksReferenceId, '') != '' AND IM.ItemMasterId = @ReferenceId AND IM.MasterCompanyId = @MasterCompanyId
		
		 AND ISNULL(IM.IsNonStock,0) = 0
		END
	END TRY    
	BEGIN CATCH      

	         DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'QuickBooks_GetItemDetailsForUpdateItem'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@IntegrationTypeId, '') AS varchar(100))  			                                           
			,@ApplicationName VARCHAR(100) = 'PAS'
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