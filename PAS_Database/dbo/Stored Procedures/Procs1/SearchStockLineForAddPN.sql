﻿/*************************************************************             
 ** File:   [SearchStockLineForAddPN]             
 ** Author:   Hemant Saliya  
 ** Description: Search Data for Add PN WO Materilas      
 ** Purpose:           
 ** Date:   05/26/2022           
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author          Change Description              
 ** --   --------     -------  --------------------------------            
 ** 1    05/26/2022   Hemant Saliya   Created  
 ** 2    07/26/2023	  HEMANT SALIYA	  Allow User to reserver & Issue other Customer Stock as well
 ** 3    08/08/2023	  HEMANT SALIYA	  Cistomer Stock Validation Changes
 ** 4    10/11/2023	  HEMANT SALIYA   Added Condition Group Changes
 ** 5    08/29/2024	  Devendra Shekh  Duplicate StockLine Issue Resolved
       
-- EXEC [dbo].[SearchStockLineForAddPN] '2', 33, 10,-1,NULL  
**************************************************************/   
  
CREATE   PROCEDURE [dbo].[SearchStockLineForAddPN]  
@ItemMasterIdlist VARCHAR(max) = '0',   
@ConditionId BIGINT = NULL,  
@CustomerId BIGINT = NULL,  
@MappingType INT = -1,  
@StocklineIdlist VARCHAR(max)='0'  
AS  
BEGIN  
  
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
		DECLARE @StockType INT = 1;
		DECLARE @AlternatePartNumber VARCHAR(250);  
		DECLARE @ConditionGroup VARCHAR(50);
		DECLARE @MasterCompanyId INT;

	    IF OBJECT_ID(N'tempdb..#ConditionGroup') IS NOT NULL
		BEGIN
			DROP TABLE #ConditionGroup 
		END

		IF OBJECT_ID(N'tempdb..#StockLineResult') IS NOT NULL
		BEGIN
			DROP TABLE #StockLineResult 
		END

		CREATE TABLE #ConditionGroup 
		(
			ID BIGINT NOT NULL IDENTITY, 
			[ConditionId] [BIGINT] NULL,
			[ConditionGroup] VARCHAR(50) NULL,
		)

		CREATE TABLE #StockLineResult (
			[PartNumber] VARCHAR(50) NULL,
			[StockLineId] BIGINT NULL,
			[PartId] BIGINT NULL,
			[ItemMasterId] BIGINT NULL,
			[Description] NVARCHAR(MAX) NULL,
			[unitOfMeasureId] BIGINT NULL,
			[unitOfMeasure] VARCHAR(100) NULL,
			[ItemGroup] VARCHAR(256) NULL,
			[Manufacturer] VARCHAR(100) NULL,
			[ManufacturerId] BIGINT NULL,
			[ItemClassificationCode] VARCHAR(30) NULL,
			[ItemClassification] VARCHAR(100) NULL,
			[ItemClassificationId] BIGINT NULL,
			[ConditionDescription] VARCHAR(256) NULL,
			[ConditionId] BIGINT NULL,
			[AlternateFor] VARCHAR(250) NULL,
			[StockType] VARCHAR(20) NULL,
			[MappingType] INT NULL,
			[StockLineNumber] VARCHAR(50) NULL,
			[SerialNumber] VARCHAR(30) NULL,
			[ControlNumber] VARCHAR(50) NULL,
			[IdNumber] VARCHAR(100) NULL,
			[UomDescription] VARCHAR(100) NULL,
			[QtyAvailable] INT NULL,
			[QtyOnHand] INT NULL,
			[unitCost] DECIMAL(18, 2) NULL,
			[unitSalePrice] DECIMAL(18, 2) NULL,
			[TracableToName] VARCHAR(150) NULL,
			[OwnerName] VARCHAR(150) NULL,
			[ObtainFromName] VARCHAR(150) NULL,
			[TagDate] DATETIME2 NULL,
			[TagType] VARCHAR(500) NULL,
			[CertifiedBy] VARCHAR(100) NULL,
			[CertifiedDate] DATETIME2 NULL,
			[Memo] NVARCHAR(MAX) NULL,
			[Method] VARCHAR(30) NULL,
			[MethodType] VARCHAR(10) NULL,
			[PMA] BIT NULL,
			[StkLineManufacturer] VARCHAR(100) NULL,
			[FixRate] DECIMAL(18, 2) NULL,
			[CustomerId] BIGINT NULL,
			[IsCustomerStock] BIT NULL,
			[CustomerName] VARCHAR(100) NULL
		);

		SELECT TOP 1 @MasterCompanyId = MasterCompanyId FROM dbo.ItemMaster WITH (NOLOCK) WHERE ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))     

		SELECT @ConditionGroup = C.GroupCode FROM dbo.Condition C WHERE C.ConditionId = @ConditionId
					
		INSERT INTO #ConditionGroup (ConditionId)
		SELECT ConditionId FROM dbo.Condition WITH (NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND GroupCode = @ConditionGroup
     
		--Select for Alternate partnumber from mapping master table.  
		SELECT @AlternatePartNumber = STRING_AGG(Im.partnumber, ',')  
		FROM [DBO].[Nha_Tla_Alt_Equ_ItemMapping] IMM  
			JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON IMM.ItemMasterId = IM.ItemMasterId  
		WHERE MappingItemMasterId = @ItemMasterIdlist AND IMM.MappingType IN(1,2);  
  
		INSERT INTO #StockLineResult (
			[PartNumber], [StockLineId], [PartId], [ItemMasterId], [Description], [unitOfMeasureId], [unitOfMeasure], [ItemGroup], [Manufacturer], [ManufacturerId],
			[ItemClassificationCode], [ItemClassification], [ItemClassificationId], [ConditionDescription], [ConditionId], [AlternateFor], [StockType], [MappingType],
			[StockLineNumber], [SerialNumber], [ControlNumber], [IdNumber], [UomDescription], [QtyAvailable], [QtyOnHand], [unitCost], [unitSalePrice], [TracableToName],
			[OwnerName], [ObtainFromName], [TagDate], [TagType], [CertifiedBy], [CertifiedDate], [Memo], [Method], [MethodType], [PMA], [StkLineManufacturer], [FixRate], [CustomerId],
			[IsCustomerStock], [CustomerName]
		)
		SELECT DISTINCT  
			im.PartNumber  
			,sl.StockLineId  
			,im.ItemMasterId As PartId  
			,im.ItemMasterId As ItemMasterId  
			,im.PartDescription AS Description  
			,sl.PurchaseUnitOfMeasureId  AS unitOfMeasureId  
			,suom.Description AS unitOfMeasure  
			,ig.Description AS ItemGroup  
			,mf.Name AS Manufacturer  
			,ISNULL(im.ManufacturerId, -1) AS ManufacturerId  
			,ic.ItemClassificationCode  
			,ic.Description AS ItemClassification  
			,ic.ItemClassificationId  
			,c.Description ConditionDescription  
			,c.ConditionId  
			,isnull(@AlternatePartNumber,'') AlternateFor  
			,CASE   
			 WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'  
			 WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'  
			 WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'  
			 ELSE 'OEM'  
			END AS StockType  
			,@MappingType AS MappingType  
			,sl.StockLineNumber   
			,sl.SerialNumber  
			,sl.ControlNumber  
			,sl.IdNumber  
			,uom.ShortName AS UomDescription  
			,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable  
			,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand  
			,ISNULL(sl.UnitCost, 0) AS unitCost  
			,ISNULL(sl.UnitSalesPrice, 0) AS unitSalePrice  
			,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name  
			  WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName  
			  WHEN sl.TraceableToType = 9 THEN leTraceble.Name  
			  WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)  
			  ELSE ''  
			END AS TracableToName  
			,CASE WHEN sl.OwnerType = 1 THEN cusOwner.Name  
			  WHEN sl.OwnerType = 2 THEN vOwner.VendorName  
			  WHEN sl.OwnerType = 9 THEN leOwner.Name  
			  WHEN sl.OwnerType = 4 THEN CAST(sl.Owner as varchar)  
			  ELSE ''  
			END AS [OwnerName]  
			,CASE WHEN sl.ObtainFromType = 1 THEN cusObtain.Name  
			  WHEN sl.ObtainFromType = 2 THEN vObtain.VendorName  
			  WHEN sl.ObtainFromType = 9 THEN leObtain.Name  
			  WHEN sl.ObtainFromType = 4 THEN CAST(sl.ObtainFrom as varchar)  
			  ELSE ''  
			END AS  ObtainFromName  
			,sl.TagDate  
			,sl.TagType  
			,sl.CertifiedBy  
			,sl.CertifiedDate  
			,sl.Memo  
			,'Stock Line' AS Method  
			,'S' AS MethodType  
			,CONVERT(BIT,0) AS PMA  
			,mf.Name as StkLineManufacturer  
			,imps.PP_FXRatePerc AS FixRate,
			sl.CustomerId,
			sl.IsCustomerStock,
			cus.Name As CustomerName
	   FROM DBO.ItemMaster im WITH(NOLOCK)  
			JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId   
				AND sl.isActive = 1 AND sl.IsDeleted = 0   
				--AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup)
				AND sl.ConditionId = CASE WHEN @ConditionId IS NOT NULL   
					  THEN @ConditionId ELSE sl.ConditionId   
					  END  
			LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId  
			LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId   
				 AND sl.IsDeleted = 0  
			LEFT JOIN DBO.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId   
				AND pop.ItemMasterId = im.ItemMasterId   
				AND pop.IsDeleted = 0 AND pop.isActive = 1  
				AND pop.ItemTypeId = @StockType                  --------------------------------  Added For Stock Type  
		   LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId  
		   LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON sl.ManufacturerId = mf.ManufacturerId  
		   LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId  
		   LEFT JOIN DBO.UnitOfMeasure uom WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId  
		   LEFT JOIN DBO.UnitOfMeasure suom  WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = suom.UnitOfMeasureId  
		   LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId  
		   LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId  
		   LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId  
		   LEFT JOIN DBO.Customer cusObtain WITH(NOLOCK) ON sl.ObtainFrom = cusObtain.CustomerId  
		   LEFT JOIN DBO.Vendor vObtain WITH(NOLOCK) ON sl.ObtainFrom = vObtain.VendorId  
		   LEFT JOIN DBO.LegalEntity leObtain WITH(NOLOCK) ON sl.ObtainFrom = leObtain.LegalEntityId  
		   LEFT JOIN DBO.Customer cusOwner WITH(NOLOCK) ON sl.Owner = cusOwner.CustomerId  
		   LEFT JOIN DBO.Vendor vOwner WITH(NOLOCK) ON sl.Owner = vOwner.VendorId  
		   LEFT JOIN DBO.LegalEntity leOwner WITH(NOLOCK) ON sl.Owner = leOwner.LegalEntityId  
		   LEFT JOIN DBO.Customer cus WITH(NOLOCK) ON sl.CustomerId = cus.CustomerId  
		   LEFT JOIN DBO.ItemMasterPurchaseSale imps WITH (NOLOCK) on imps.ItemMasterId = im.ItemMasterId  
				AND imps.ConditionId = c.ConditionId  
		WHERE   
			im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@ItemMasterIdlist,','))    
			AND ISNULL(sl.QuantityAvailable, 0) > 0   
			AND (sl.IsCustomerStock = 0 OR (sl.IsCustomerStock = 1 AND sl.CustomerId = @CustomerId))  
			AND sl.IsParent = 1  
	   
	   --UNION  
  
		INSERT INTO #StockLineResult (
			[PartNumber], [StockLineId], [PartId], [ItemMasterId], [Description], [unitOfMeasureId], [unitOfMeasure], [ItemGroup], [Manufacturer], [ManufacturerId],
			[ItemClassificationCode], [ItemClassification], [ItemClassificationId], [ConditionDescription], [ConditionId], [AlternateFor], [StockType], [MappingType],
			[StockLineNumber], [SerialNumber], [ControlNumber], [IdNumber], [UomDescription], [QtyAvailable], [QtyOnHand], [unitCost], [unitSalePrice], [TracableToName],
			[OwnerName], [ObtainFromName], [TagDate], [TagType], [CertifiedBy], [CertifiedDate], [Memo], [Method], [MethodType], [PMA], [StkLineManufacturer], [FixRate], [CustomerId],
			[IsCustomerStock], [CustomerName]
		)
	   SELECT DISTINCT  
			im.PartNumber  
			,sl.StockLineId  
			,im.ItemMasterId As PartId  
			,im.ItemMasterId As ItemMasterId  
			,im.PartDescription AS Description  
			,sl.PurchaseUnitOfMeasureId  AS unitOfMeasureId  
			,suom.Description AS unitOfMeasure  
			,ig.Description AS ItemGroup  
			,mf.Name AS Manufacturer  
			,ISNULL(im.ManufacturerId, -1) AS ManufacturerId  
			,ic.ItemClassificationCode  
			,ic.Description AS ItemClassification  
			,ic.ItemClassificationId  
			,c.Description ConditionDescription  
			,c.ConditionId  
			,'' AlternateFor  
			,CASE   
			 WHEN im.IsPma = 1 and im.IsDER = 1 THEN 'PMA&DER'  
			 WHEN im.IsPma = 1 and im.IsDER = 0 THEN 'PMA'  
			 WHEN im.IsPma = 0 and im.IsDER = 1 THEN 'DER'  
			 ELSE 'OEM'  
			END AS StockType  
			,@MappingType AS MappingType  
			,sl.StockLineNumber   
			,sl.SerialNumber  
			,sl.ControlNumber  
			,sl.IdNumber  
			,uom.ShortName AS UomDescription  
			,ISNULL(sl.QuantityAvailable,0) AS QtyAvailable  
			,ISNULL(sl.QuantityOnHand, 0) AS QtyOnHand  
			,ISNULL(sl.UnitCost, 0) AS unitCost  
			,ISNULL(sl.UnitSalesPrice, 0) AS unitSalePrice  
			,CASE WHEN sl.TraceableToType = 1 THEN cusTraceble.Name  
			  WHEN sl.TraceableToType = 2 THEN vTraceble.VendorName  
			  WHEN sl.TraceableToType = 9 THEN leTraceble.Name  
			  WHEN sl.TraceableToType = 4 THEN CAST(sl.TraceableTo as varchar)  
			  ELSE ''  
			END AS  TracableToName  
			,CASE WHEN sl.OwnerType = 1 THEN cusOwner.Name  
			  WHEN sl.OwnerType = 2 THEN vOwner.VendorName  
			  WHEN sl.OwnerType = 9 THEN leOwner.Name  
			  WHEN sl.OwnerType = 4 THEN CAST(sl.Owner as varchar)  
			  ELSE ''  
			END AS  [OwnerName]  
			,CASE WHEN sl.ObtainFromType = 1 THEN cusObtain.Name  
			  WHEN sl.ObtainFromType = 2 THEN vObtain.VendorName  
			  WHEN sl.ObtainFromType = 9 THEN leObtain.Name  
			  WHEN sl.ObtainFromType = 4 THEN CAST(sl.ObtainFrom as varchar)  
			  ELSE ''  
			END AS  ObtainFromName  
			,sl.TagDate  
			,sl.TagType  
			,sl.CertifiedBy  
			,sl.CertifiedDate  
			,sl.Memo  
			,'Stock Line' AS Method  
			,'S' AS MethodType  
			,CONVERT(BIT,0) AS PMA  
			,mf.Name as StkLineManufacturer  
			,imps.PP_FXRatePerc AS FixRate ,
			sl.CustomerId,
			sl.IsCustomerStock,
			cus.Name As CustomerName
	   FROM DBO.ItemMaster im WITH(NOLOCK)  
		   JOIN DBO.StockLine sl WITH(NOLOCK) ON im.ItemMasterId = sl.ItemMasterId   
			   AND sl.isActive = 1 AND sl.IsDeleted = 0   
			   --AND SL.ConditionId IN (SELECT ConditionId FROM #ConditionGroup)
			   AND sl.ConditionId = CASE WHEN @ConditionId  IS NOT NULL   
					 THEN @ConditionId ELSE sl.ConditionId   
					 END  
		   LEFT JOIN DBO.Condition c WITH(NOLOCK) ON c.ConditionId = sl.ConditionId  
		   LEFT JOIN DBO.PurchaseOrder po WITH(NOLOCK) ON po.PurchaseOrderId = sl.PurchaseOrderId   
				AND sl.IsDeleted = 0  
			LEFT JOIN DBO.PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId   
				AND pop.ItemMasterId = im.ItemMasterId   
				AND pop.IsDeleted = 0 AND pop.isActive = 1  
				AND pop.ItemTypeId = @StockType                  --------------------------------  Added For Stock Type  
		   LEFT JOIN DBO.ItemGroup ig WITH(NOLOCK) ON im.ItemGroupId = ig.ItemGroupId  
		   LEFT JOIN DBO.Manufacturer mf WITH(NOLOCK) ON sl.ManufacturerId = mf.ManufacturerId  
		   LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) ON im.ItemClassificationId = ic.ItemClassificationId  
		   LEFT JOIN DBO.UnitOfMeasure uom WITH(NOLOCK) ON im.PurchaseUnitOfMeasureId = uom.UnitOfMeasureId  
		   LEFT JOIN DBO.UnitOfMeasure suom  WITH(NOLOCK) ON sl.PurchaseUnitOfMeasureId = suom.UnitOfMeasureId  
		   LEFT JOIN DBO.Customer cusTraceble WITH(NOLOCK) ON sl.TraceableTo = cusTraceble.CustomerId  
		   LEFT JOIN DBO.Vendor vTraceble WITH(NOLOCK) ON sl.TraceableTo = vTraceble.VendorId  
		   LEFT JOIN DBO.LegalEntity leTraceble WITH(NOLOCK) ON sl.TraceableTo = leTraceble.LegalEntityId  
		   LEFT JOIN DBO.Customer cusObtain WITH(NOLOCK) ON sl.ObtainFrom = cusObtain.CustomerId  
		   LEFT JOIN DBO.Vendor vObtain WITH(NOLOCK) ON sl.ObtainFrom = vObtain.VendorId  
		   LEFT JOIN DBO.LegalEntity leObtain WITH(NOLOCK) ON sl.ObtainFrom = leObtain.LegalEntityId  
		   LEFT JOIN DBO.Customer cusOwner WITH(NOLOCK) ON sl.Owner = cusOwner.CustomerId  
		   LEFT JOIN DBO.Vendor vOwner WITH(NOLOCK) ON sl.Owner = vOwner.VendorId  
		   LEFT JOIN DBO.LegalEntity leOwner WITH(NOLOCK) ON sl.Owner = leOwner.LegalEntityId  
		   LEFT JOIN DBO.Customer cus WITH(NOLOCK) ON sl.CustomerId = cus.CustomerId  
		   LEFT JOIN DBO.ItemMasterPurchaseSale imps WITH (NOLOCK) on imps.ItemMasterId = im.ItemMasterId  
				AND imps.ConditionId = c.ConditionId  
		WHERE SL.StockLineId IN (SELECT Item FROM DBO.SPLITSTRING(@StocklineIdlist,','))  
		AND SL.StockLineId NOT IN (SELECT StockLineId FROM #StockLineResult);

		SELECT * FROM #StockLineResult;
	  END  
	  COMMIT  TRANSACTION  
  
	  END TRY      
	  BEGIN CATCH        
	   IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'SearchStockLineForAddPN'   
               , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterIdlist, '') + ''',  
              @Parameter2 = ' + ISNULL(@ConditionId,'') + ',   
              @Parameter3 = ' + ISNULL(@CustomerId,'') + ',   
                                               @Parameter4 = ' + ISNULL(@MappingType,'') +''  
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