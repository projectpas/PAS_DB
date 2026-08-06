/*************************************************************           
 ** File:		[dbo].[USP_searchItemmasterfordashboardheader]       
 ** Author:		 Nakul Chandigra
 ** Description: This Stored Procedure Is Used To Search Itemmaster For Dashboardheader
 ** Purpose:         
 ** Date:   26-09-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
	1	27-11-2025           Nakul Chandigra     Created 
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_searchItemmasterfordashboardheader] 
@ItemMasterId BIGINT,
@ConditionId BIGINT  
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		
	SELECT TOP 1 
		imp.PP_UnitPurchasePrice,
		imst.ItemClassificationName,
		imst.ItemGroup
	FROM [dbo].[ItemMasterPurchaseSale] imp WITH (NOLOCK)
	LEFT JOIN [dbo].[ItemMaster] imst ON imp.ItemMasterId = imst.ItemMasterId
	 AND ISNULL(imst.IsNonStock,0) = 0
	WHERE imp.ItemMasterId = @ItemMasterId AND imp.ConditionId = @ConditionId

    END TRY
	BEGIN CATCH    
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_searchItemmasterfordashboardheader]'
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