/*************************************************************           
 ** File:		[dbo].[usp_GetItemMasterKitById]         
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Get Kit 
 ** Purpose:         
 ** Date:   01-12-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	 01-12-2025         Nakul Chandigra     Created 
**************************************************************/
CREATE    PROCEDURE [dbo].[usp_GetItemMasterKitById]
@kitId BIGINT
AS
BEGIN
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
	LEFT JOIN [dbo].[ItemMaster] imst ON kIM.ItemMasterId = imst.ItemMasterId
	LEFT JOIN [dbo].[WorkScope] wos ON kIM.WorkScopeId = wos.WorkScopeId
	WHERE kIM.KitId = @KitId;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[usp_GetItemMasterKitById]'
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