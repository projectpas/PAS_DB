﻿/*************************************************************           
 ** File:   [SearchItemMasterByCustomerRestrictionFromWO]           
 ** Author		:   HEMANT SALIYA
 ** Description	:	Get Item Master Details By Customer Restriction for WO   
 ** Purpose		:   Get Item Master Details By Customer Restriction for WO     
 ** Date		:   12-Oct-2023      
          
 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				-------------------          
    1    12-Oct-2023		HEMANT SALIYA		Created
	2    15-DEC-2023		Ayesha Sultana		BugFix - View Inventory in add/edit work order
     
 EXECUTE [SearchItemMasterByCustomerRestrictionFromWO] 3, 12, 2461,1
**************************************************************/ 
CREATE     PROCEDURE [dbo].[SearchItemMasterByCustomerRestrictionFromWO]
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
				IF OBJECT_ID(N'tempdb..#ConditionGroupCode') IS NOT NULL
				BEGIN
					DROP TABLE #ConditionGroupCode 
				END

				CREATE TABLE #ConditionGroupCode 
				(
					ID BIGINT NOT NULL IDENTITY, 
					[MasterCompanyId] [BIGINT] NULL,
					[ConditionGroup] VARCHAR(50) NULL,
				)

				IF OBJECT_ID(N'tempdb..#ConditionGroup') IS NOT NULL
				BEGIN
					DROP TABLE #ConditionGroup 
				END

				CREATE TABLE #ConditionGroup 
				(
					ID BIGINT NOT NULL IDENTITY, 
					[ConditionId] [BIGINT] NULL,
					[ConditionGroup] VARCHAR(50) NULL,
				)

				INSERT INTO #ConditionGroupCode (ConditionGroup, MasterCompanyId)
				SELECT DISTINCT GroupCode, MasterCompanyId FROM dbo.Condition WITH (NOLOCK) WHERE ConditionId IN (SELECT Item FROM DBO.SPLITSTRING(@ConditionIds,','))
					
				INSERT INTO #ConditionGroup (ConditionId, ConditionGroup)
				SELECT DISTINCT ConditionId, ConditionGroup FROM dbo.Condition C WITH (NOLOCK) 
				JOIN #ConditionGroupCode CG WITH (NOLOCK) ON C.GroupCode = CG.ConditionGroup
				WHERE C.MasterCompanyId = CG.MasterCompanyId

				-- Select * from #ConditionGroup

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
					FOR XML PATH('')
					)
					,1,1,''), '') AlternateFor
					,CASE 
						WHEN im.IsPma = 1 and im.IsDER = 1 THEN OEMPMA.partnumber --'PMA&DER'
						WHEN im.IsPma = 1 and im.IsDER = 0 THEN OEMPMA.partnumber --'PMA'
						WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'
						ELSE 'OEM'
						END AS Oempmader
					,@MappingType AS MappingType
					,imps.PP_UnitPurchasePrice AS UnitCost
					,imps.SP_CalSPByPP_UnitSalePrice AS UnitSalePrice
					,imps.PP_FXRatePerc AS FixRate
				FROM DBO.ItemMaster im WITH (NOLOCK)
				LEFT JOIN DBO.Condition c WITH (NOLOCK) ON c.ConditionId in (SELECT ConditionId FROM #ConditionGroup) 
				LEFT JOIN DBO.StockLine sl WITH (NOLOCK) ON im.ItemMasterId = sl.ItemMasterId AND sl.ConditionId in (SELECT ConditionId FROM #ConditionGroup) 
					AND sl.IsDeleted = 0  AND sl.isActive = 1 AND sl.IsParent = 1 --AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))
				LEFT JOIN DBO.ItemGroup ig WITH (NOLOCK) ON im.ItemGroupId = ig.ItemGroupId
				LEFT JOIN DBO.Manufacturer mf WITH (NOLOCK) ON im.ManufacturerId = mf.ManufacturerId
				LEFT JOIN DBO.ItemClassification ic WITH (NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId
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
					,OEMPMA.partnumber
					,sl.ItemMasterId
					,imps.PP_UnitPurchasePrice
					,imps.SP_CalSPByPP_UnitSalePrice
					,imps.PP_FXRatePerc
				ORDER BY 7 DESC
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