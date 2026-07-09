/*************************************************************             
 ** File:   [USP_CreateWorkOrderMaterialsStoclkine]             
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used Create work order materials
 ** Date:   28-April-2025         
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date					Author						Change Description              
 ** --   --------				-------					--------------------------------            
 ** 1    28-April-2025			Devendra Shekh				Created         
 ** 2    25-June-2026			Abhishek Jirawla			Abhishek Jirawla
 3    09/July/2026			RAJESH GAMI			[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
       
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[USP_CreateWorkOrderMaterialsStoclkine]  
	@tbl_WorkOrderMaterialsType [WorkOrderMaterialsType] READONLY
AS  
BEGIN  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
  
	BEGIN TRY  
	BEGIN TRANSACTION

		DECLARE @CreatedMaterial VARCHAR(100) = 'Created-Updated';

		INSERT INTO [dbo].[WorkOrderMaterialStockLine] ([WorkOrderMaterialsId], [StocklineId], [ItemMasterId], [ProvisionId], [ConditionId], [Quantity], [QtyReserved], [QtyIssued], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
		[IsActive], [IsDeleted], [UnitCost], [ExtendedCost], [UnitPrice], [Figure], [Item], [ReferenceNumber], [AltPartMasterPartId], [IsAltPart], [EquPartMasterPartId], [IsEquPart], [IsPiecePart]) 
		SELECT TMP.[WorkOrderMaterialsId], TMP.[StocklineId], TMP.[ItemMasterId], [ProvisionId], [ConditionCodeId], [StocklineQuantity], 0, 0, TMP.[MasterCompanyId], TMP.[CreatedBy], TMP.[UpdatedBy], GETUTCDATE(), GETUTCDATE(),
		1, 0, STK.[UnitCost], (ISNULL(STK.UnitCost, 0) * ISNULL(StocklineQuantity, 0)), STK.[UnitCost], TMP.Figure, TMP.[Item], @CreatedMaterial,
		CASE WHEN ISNULL([IsAltPart], 0) = 1 THEN [IsAlternatePart] ELSE [AltPartMasterPartId] END, [IsAltPart], CASE WHEN ISNULL([IsEquPart], 0) = 1 THEN [IsAlternatePart] ELSE [EquPartMasterPartId] END, [IsEquPart], 0
		FROM @tbl_WorkOrderMaterialsType TMP
		LEFT JOIN [DBO].[StockLine] STK WITH(NOLOCK) ON TMP.StockLineId = STK.StockLineId AND ISNULL(STK.IsNonStock,0) = 0
		 
	COMMIT TRANSACTION  
	END TRY      
	BEGIN CATCH        
		IF @@trancount > 0  
		ROLLBACK TRAN;  
		DECLARE	@ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				, @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrderMaterialsStoclkine'   
				, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' 
				, @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
				EXEC	spLogException   
						@DatabaseName   = @DatabaseName  
						, @AdhocComments   = @AdhocComments  
						, @ProcedureParameters  = @ProcedureParameters  
						, @ApplicationName         = @ApplicationName  
						, @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
	END CATCH  
END