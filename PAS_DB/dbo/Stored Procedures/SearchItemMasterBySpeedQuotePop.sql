/*************************************************************           
 ** File:   [dbo].[SearchItemMasterBySpeedQuotePop]        
 ** Author		:   Deep Patel
 ** Description	:	Get Item Master Details for speed quote popup.
 ** Purpose		:   Get Item Master Details for speed quote popup.
 ** Date		:   19-may-2021       

     
 EXECUTE [dbo].[SearchItemMasterBySpeedQuotePop] 303,1
**************************************************************/ 
CREATE PROCEDURE [dbo].[SearchItemMasterBySpeedQuotePop]
@ItemMasterIdlist VARCHAR(max) = '0',
@CustomerId BIGINT = 318,
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
					,(SELECT SUM(ISNULL(sl.QuantityAvailable, 0)) FROM StockLine sl Where sl.ItemMasterId = im.ItemMasterId AND IsActive = 1 AND IsDeleted = 0) AS QtyAvailable
					,(SELECT SUM(ISNULL(sl.QuantityOnHand, 0)) FROM StockLine sl Where sl.ItemMasterId = im.ItemMasterId  AND IsActive = 1 AND IsDeleted = 0) AS QtyOnHand
					,ig.Description AS ItemGroup
					,mf.Name Manufacturer
					,ISNULL(im.ManufacturerId, -1) AS ManufacturerId
					,ic.ItemClassificationCode
					,ic.Description AS ItemClassification
					,ic.ItemClassificationId
					,ISNULL(STUFF((
					SELECT DISTINCT ', '+ I.partnumber FROM DBO.Nha_Tla_Alt_Equ_ItemMapping M INNER JOIN ItemMaster I ON I.ItemMasterId = M.ItemMasterId Where M.MappingItemMasterId = im.ItemMasterId AND M.MappingType = 1
					FOR XML PATH('')
					)
					,1,1,''), '') AlternateFor
					--,CASE 
					--	WHEN im.IsPma = 1 and im.IsDER = 1 THEN OEMPMA.partnumber --'PMA&DER'
					--	WHEN im.IsPma = 1 and im.IsDER = 0 THEN OEMPMA.partnumber --'PMA'
					--	WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
					--	ELSE 'OEM'
					--	END AS Oempmader
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER' --'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA' --'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS Oempmader
					,@MappingType AS MappingType
				FROM DBO.ItemMaster im WITH (NOLOCK)
				LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
				LEFT JOIN (SELECT partnumber, ItemMasterId FROM DBO.ItemMaster) OEMPMA ON OEMPMA.ItemMasterId = im.IsOemPNId
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
					,im.IsPma
					,im.IsDER
					,OEMPMA.partnumber
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchItemMasterBySpeedQuotePop' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''', @Parameter2 = ' + ISNULL(@CustomerId ,'') +''
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