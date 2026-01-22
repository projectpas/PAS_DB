/* EXEC [dbo].[GetKitPartsById] 2379 */
CREATE   PROCEDURE [dbo].[GetKitPartsById]
	@KitId BIGINT = 0
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
			SELECT  DISTINCT
					KIM.KitItemMasterMappingId,
					KIM.KitId,
					KIM.ItemMasterId,
					KIM.ManufacturerId,
					KIM.ConditionId,
					KIM.UOMId,
					KIM.Qty,
					KIM.UnitCost,
					ISNULL((SELECT TOP 1 ISNULL(S.UnitCost,0) FROM [dbo].[Stockline] S (NOLOCK) WHERE S.ItemMasterId = KIM.ItemMasterId AND S.ConditionId = KIM.ConditionId AND S.[IsParent] = 1 AND S.[IsCustomerStock] = 0 ORDER BY StocklineId DESC),0) AS StocklineUnitCost,
					--ISNULL(select TOP 1 S.UnitCost from dbo.Stockline S WHERE S. ORDER BY StocklineId desc ,0) AS StocklineUnitCost,
					KIM.PartNumber,
					KIM.PartDescription,
					KIM.Manufacturer,
					KIM.Condition,
					KIM.UOM,
					KIM.MasterCompanyId,
					KIM.CreatedBy,
					KIM.UpdatedBy,
					KIM.CreatedDate,
					KIM.UpdatedDate,
					KIM.IsActive,
					KIM.IsDeleted
			FROM [dbo].[KitItemMasterMapping] KIM  WITH (NOLOCK)			
			WHERE KIM.KitId = @KitId AND KIM.IsDeleted = 0 AND KIM.IsActive = 1;
			
		END TRY    
		BEGIN CATCH      
			
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetKitPartsById'
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@KitId, '') as varchar(100))
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