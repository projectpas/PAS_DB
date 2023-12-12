/*************************************************************           
 ** File:   [dbo].[SearchItemMasterBySpeedQuotePopData]        
 ** Author		:   Deep Patel
 ** Description	:	Get Item Master Details for speed quote popup.
 ** Purpose		:   Get Item Master Details for speed quote popup.
 ** Date		:   19-may-2021

     
 EXECUTE [dbo].[SearchItemMasterBySpeedQuotePopData] 7,1
**************************************************************/ 
CREATE    PROCEDURE [dbo].[SearchItemMasterBySpeedQuotePopData]
@ItemMasterIdlist VARCHAR(max) = '0',
@mastercompanyid int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	DECLARE @OHCondition INT=NULL, @REPCondition INT=NULL,@BCCondition INT =NULL;

	IF(@mastercompanyid = 11)
	BEGIN
		SELECT @OHCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @mastercompanyid AND Code = 'OVERHAULED';
		SELECT @REPCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @mastercompanyid AND Code = 'REPAIRED';
		SELECT @BCCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @mastercompanyid AND Code = 'BC';	
	END
	ELSE
	BEGIN
		SELECT @OHCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @mastercompanyid AND Code = 'OVERHAUL';
		SELECT @REPCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @mastercompanyid AND Code = 'REPAIR';
		SELECT @BCCondition = ConditionId FROM DBO.Condition WITH (NOLOCK) WHERE MasterCompanyId = @mastercompanyid AND Code = 'BC';	
	END

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT
					im.PartNumber
					,im.ItemMasterId As PartId
					,im.ItemMasterId As ItemMasterId
					,im.PartDescription AS Description
					,im.PurchaseUnitOfMeasureId  AS unitOfMeasureId
					,im.PurchaseUnitOfMeasure AS unitOfMeasure
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
					,c.Code
					,ISNULL(STUFF((
					SELECT DISTINCT ', '+ I.partnumber FROM DBO.Nha_Tla_Alt_Equ_ItemMapping M WITH (NOLOCK) INNER JOIN ItemMaster I WITH (NOLOCK) ON I.ItemMasterId = M.ItemMasterId Where M.MappingItemMasterId = im.ItemMasterId AND M.MappingType = 1
					FOR XML PATH('')
					)
					,1,1,''), '') AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER' --'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA' --'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS Oempmader
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN OEMPMA.partnumber 
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN OEMPMA.partnumber 
						ELSE ''
						END AS OemPN
					,im.IsPma
					,ISNULL(imps.PP_UnitPurchasePrice,0) AS UnitCost
					,ISNULL(imps.SP_CalSPByPP_UnitSalePrice,0) AS UnitSalePrice
					,CASE WHEN c.ConditionId = @BCCondition THEN im.turnTimeBenchTest
					WHEN c.ConditionId = @OHCondition THEN im.TurnTimeOverhaulHours
					WHEN c.ConditionId = @REPCondition THEN im.TurnTimeRepairHours
					ELSE 0 END AS TAT
				FROM DBO.ItemMaster im WITH (NOLOCK)
				LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId in (Select ConditionId from Condition where MasterCompanyId=@mastercompanyid)
				LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.ConditionId = c.ConditionId 
					AND sl.IsDeleted = 0  AND sl.isActive = 1
				LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
				LEFT JOIN (SELECT partnumber, ItemMasterId FROM DBO.ItemMaster WITH (NOLOCK)) OEMPMA ON OEMPMA.ItemMasterId = im.IsOemPNId
				LEFT JOIN DBO.ItemMasterPurchaseSale imps WITH (NOLOCK) on imps.ItemMasterId = im.ItemMasterId
							and imps.ConditionId = c.ConditionId
				WHERE 
					im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))
					AND c.ConditionId in(@OHCondition, @REPCondition, @BCCondition)
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
					,OEMPMA.partnumber
					,sl.ItemMasterId
					,imps.PP_UnitPurchasePrice
					,imps.SP_CalSPByPP_UnitSalePrice
					,im.TurnTimeOverhaulHours
					,im.TurnTimeRepairHours
					,im.turnTimeBenchTest
					,c.Code
					--ORDER BY c.Description
					order 
						by case when c.ConditionId = @OHCondition then 1
						        when c.ConditionId = @REPCondition then 2
						        when c.ConditionId = @BCCondition then 3
						      else null end 
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SearchItemMasterBySpeedQuotePopData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '')+''
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