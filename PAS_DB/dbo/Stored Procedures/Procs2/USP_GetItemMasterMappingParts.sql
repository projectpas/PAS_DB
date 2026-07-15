
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: DBO.USP_GetItemMasterMappingParts   (source: PAS_DB/dbo/Stored Procedures/Procs2/USP_GetItemMasterMappingParts.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:		 [USP_GetItemMasterMappingParts]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Get ItemMaster Mapping Parts Data.
 ** Purpose:         
 ** Date:   04-NOV-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    04-NOV-2025		Divyesh Kathiriya	Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
    
 -- EXEC [USP_GetItemMasterMappingParts] @MappingItemMasterId=96984
**************************************************************/
CREATE     PROCEDURE [DBO].[USP_GetItemMasterMappingParts]
@MappingItemMasterId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT TOP 1
			[im1].[PartNumber] AS [Label],
			[alt].[MappingItemMasterId] AS [Value]
		FROM [DBO].[Nha_Tla_Alt_Equ_ItemMapping] AS alt WITH(NOLOCK)
		INNER JOIN [DBO].[ItemMaster] AS im1 WITH(NOLOCK) ON [alt].[MappingItemMasterId] = [im1].[ItemMasterId]
		WHERE [alt].[MappingItemMasterId] = @MappingItemMasterId AND ISNULL(im1.IsNonStock,0) = 0 ;		  		 	   			   	  
	
	END TRY 
	BEGIN CATCH
	
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetItemMasterMappingParts'
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