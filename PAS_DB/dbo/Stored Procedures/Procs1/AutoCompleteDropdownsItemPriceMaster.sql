
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.AutoCompleteDropdownsItemPriceMaster   (source: PAS_DB/dbo/Stored Procedures/Procs1/AutoCompleteDropdownsItemPriceMaster.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************           
 ** File:   [AutoCompleteDropdownsItemPriceMaster]           
 ** Author:  Ekta Chandegra
 ** Description: This stored procedure is used to retrieve AutoCompleteDropdownsItemPriceMaster List
 ** Purpose:         
 ** Date:   06/11/2024      
          
 ** PARAMETERS: @SerachText VARCHAR, @MasterCompanyId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/11/2024  Ekta Chandegra     Created
    2    07/11/2024  Ekta Chandegra     Remove Static parameter value and add Isnull for IsDeleted field
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
    4    05-Aug-2026			 Bhargav Saliya                     [PN-17562] Part Number search (Item Master dropdown): normalize dashes/slashes
--exec [dbo].[AutoCompleteDropdownsItemPriceMaster] @SearchText=N'13',@MasterCompanyId=1

************************************************************************/

CREATE      PROCEDURE [dbo].[AutoCompleteDropdownsItemPriceMaster]
@SearchText VARCHAR(50),
@MasterCompanyId BIGINT
AS BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	BEGIN TRY
		SELECT DISTINCT IM.ItemMasterId,
		IM.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId  AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) AS partnumber
		FROM [dbo].[ItemMaster] IM WITH(NOLOCK)
		LEFT JOIN [dbo].[ItemMasterPurchaseSale] IMPS WITH(NOLOCK) ON IM.ItemMasterId  = IMPS.ItemMasterId
		LEFT JOIN [dbo].[Manufacturer] M WITH(NOLOCK) ON M.ManufacturerId = IM.ManufacturerId
		WHERE IM.MasterCompanyId = @MasterCompanyId AND IM.IsActive = 1 AND ISNULL(IM.IsDeleted,0) = 0 AND
		(IM.partnumber LIKE '%' + @SearchText OR IM.partnumber LIKE @SearchText + '%' OR  IM.partnumber LIKE '%' + @SearchText + '%' OR REPLACE(REPLACE(IM.partnumber, '-', ''), '/', '') LIKE '%' + REPLACE(REPLACE(@SearchText, '-', ''), '/', '') + '%')
	 AND ISNULL(IM.IsNonStock,0) = 0
		 END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
				, @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsItemPriceMaster' 
				, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SearchText, '')AS VARCHAR(100)) 
				+ '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))     
				, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			exec spLogException 
					  @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END