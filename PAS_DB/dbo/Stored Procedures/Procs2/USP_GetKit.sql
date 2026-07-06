/*************************************************************           
 ** File:		[dbo].[USP_GetKit]          
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Get Kit 
 ** Purpose:         
 ** Date:   14-10-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 14-10-2025         Nakul Chandigra     Created 
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetKit]
@kitId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
	SET NOCOUNT ON;  
	BEGIN TRY

	SELECT 
		kIM.KitId,
		kIM.KitNumber,
		kIM.KitDescription,
		imst.ItemMasterId,
		imst.PartNumber,
		imst.PartDescription,
		imst.ManufacturerId,
		ISNULL(imst.ManufacturerName, '') AS ManufacturerName,
		kIM.IsDeleted,
		kIM.IsActive,
		kIM.CustomerName,
		kIM.CustomerId,
		kIM.KitCost,
		kIM.CreatedBy,
		kIM.WorkScopeId,
		ISNULL(wos.WorkScopeCode, '') AS WorkScopeName,
		kIM.Memo
	FROM [dbo].[KitMaster] kIM WITH (NOLOCK)
	LEFT JOIN [dbo].[ItemMaster] imst WITH (NOLOCK) ON kIM.ItemMasterId = imst.ItemMasterId
	 AND ISNULL(imst.IsNonStock,0) = 0
	 LEFT JOIN [dbo].[WorkScope] wos WITH (NOLOCK) ON kIM.WorkScopeId = wos.WorkScopeId
	WHERE kIM.KitId = @KitId;

	END TRY
	BEGIN CATCH
		IF @@trancount > 0		  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetKit]'
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