/*************************************************************           
 ** File:   [SearchItemMasterAutoCompleteDropdownsByRestriction]           
 ** Author		:   Vishal Suthar
 ** Description	:	Get Item Master Details By Customer Restriction    
 ** Purpose		:   Get Item Master Details By Customer Restriction      
 ** Date		:   14-Dec-2020        
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			-------------------          
    1    04-02-2020		Vishal Suthar	Created
	2    05-10-2020		Hemant Saliya	Rename SP to General Name & added Transation and Content Managment
	3    02-19-2024		Vishal Suthar	Changed to always exclude customer stocks, and sorting based on availability
	4    11-21-2024		Amit Ghediya	Get ECCN,HSCODE,Weight,LWH for billing.
	5    05-01-2025		ABHISHEK JIRAWLA Allow Repair Management Customer Stock Stockline
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	7    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	8    16/July/2026			 RAJESH GAMI						[PN-17350] - Allow Non-Stock Inventory Parts in Sales Order Quote and Sales Order: removed IsNonStock=0 filters (ItemMaster, joined Stockline, alternate-part mapping) so Non-Stock parts are included.
     
 EXECUTE [SearchItemMasterByCustomerRestriction] 11, 7, 77,-1
**************************************************************/ 
CREATE PROCEDURE [dbo].[SearchItemMasterByCustomerRestriction]
	@ItemMasterIdlist VARCHAR(max) = '0', 
	@ConditionIds VARCHAR(100) = NULL,
	@CustomerId BIGINT = NULL,
	@MappingType INT = -1
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT DISTINCT
					im.PartNumber
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,im.PurchaseUnitOfMeasureId  AS unitOfMeasureId
					,im.PurchaseUnitOfMeasure AS unitOfMeasure
					,im.IsPma
					,im.IsDER
					,SUM(ISNULL(sl.QuantityAvailable, 0)) AS QtyAvailable
					,SUM(ISNULL(sl.QuantityOnHand, 0)) AS QtyOnHand
					,ig.Description AS ItemGroup
					,mf.Name Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,ic.ItemClassificationCode
					,ic.Description AS ItemClassification
					,ic.ItemClassificationId
					,c.ConditionId ConditionId
					,c.Description ConditionDescription
					,ISNULL(STUFF((
					SELECT DISTINCT ', '+ I.partnumber FROM DBO.Nha_Tla_Alt_Equ_ItemMapping M INNER JOIN ItemMaster I ON I.ItemMasterId = M.ItemMasterId Where M.MappingItemMasterId = im.ItemMasterId AND M.MappingType = 1
									FOR XML PATH(''))
					,1,1,''), '') AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN OEMPMA.partnumber --'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN OEMPMA.partnumber --'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS Oempmader
					,(CASE WHEN ISNULL(im.IsNonStock,0) = 1 THEN 'Non-Stock' ELSE 'Stock' END) AS ItemType
					,@MappingType AS MappingType
					,imps.PP_UnitPurchasePrice AS UnitCost
					,imps.SP_CalSPByPP_UnitSalePrice AS UnitSalePrice
					,imps.PP_FXRatePerc AS FixRate
					,ime.ExportECCN AS ECCN
					,ime.HSCode AS HSCODE
					,ime.ExportWeight AS [Weight]
					,ime.ExportSizeLength AS SizeLength
					,ime.ExportSizeWidth AS SizeWidth
					,ime.ExportSizeHeight AS SizeHeight
				FROM DBO.ItemMaster im WITH (NOLOCK)
				LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId in (SELECT Item FROM DBO.SPLITSTRING(@ConditionIds,','))
				LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.ConditionId = c.ConditionId 
					AND sl.IsDeleted = 0  AND sl.isActive = 1 AND sl.IsParent = 1 
					AND (
							(sl.IsRepairManagement = 1) OR 
							((sl.IsRepairManagement = 0 OR sl.IsRepairManagement IS NULL) AND sl.IsCustomerStock = 0)
						) 
					--AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
				LEFT JOIN DBO.ItemMasterExportInfo ime WITH (NOLOCK) ON im.ItemMasterId = ime.ItemMasterId
				LEFT JOIN (SELECT partnumber, ItemMasterId FROM DBO.ItemMaster WITH (NOLOCK)) OEMPMA ON OEMPMA.ItemMasterId = im.IsOemPNId
				LEFT JOIN DBO.ItemMasterPurchaseSale imps WITH (NOLOCK) on imps.ItemMasterId = im.ItemMasterId
							and imps.ConditionId = c.ConditionId
				WHERE 
					im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
					 GROUP BY
					im.PartNumber
					,im.PurchaseUnitOfMeasureId
					,im.PurchaseUnitOfMeasure
					,im.ItemMasterId 
					,im.PartDescription
					,ig.Description 
					,mf.Name 
					,im.ManufacturerId
					,ic.ItemClassificationCode
					,ic.Description
					,ic.ItemClassificationId
					,c.Description
					,c.ConditionId
					,im.IsPma
					,im.IsDER
					,im.IsNonStock
					,OEMPMA.partnumber
					,sl.ItemMasterId
					,imps.PP_UnitPurchasePrice
					,imps.SP_CalSPByPP_UnitSalePrice
					,imps.PP_FXRatePerc
					,ime.ExportECCN
					,ime.HSCode
					,ime.ExportWeight
					,ime.ExportSizeLength
					,ime.ExportSizeWidth
					,ime.ExportSizeHeight
				ORDER BY 9 DESC
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchItemMasterByCustomerRestriction' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''', @Parameter2 = ' + ISNULL(@ConditionIds,'') + ', @Parameter3 = ' + ISNULL(@CustomerId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END