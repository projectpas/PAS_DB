/*************************************************************           
 ** File:  [RPT_PrintPurchasePartDataById]           
 ** Author:  Amit Ghediya
 ** Description: This stored procedure is used to Get Print Vendor Data By VendorId
 ** Purpose:         
 ** Date:   09/03/2023      
          
 ** PARAMETERS: @PurchaseOrderId BIGINT
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/03/2023  Amit Ghediya    Created
	2    17/05/2023  Amit Ghediya    Add Currency Code.
	3    26/07/2024  Amit Ghediya    Update to get Freight amount.
     
-- EXEC RPT_PrintPurchasePartDataById 2537
************************************************************************/
CREATE      PROCEDURE [dbo].[RPT_PrintPurchasePartDataById]
@PurchaseOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
		
		DECLARE @PurchaseOrderPartRecordId BIGINT,@POPart BIGINT,@TotalRecord BIGINT,
			    @CurrencyCode VARCHAR(50),@ChargesBilingMethodId INT,@FreightBilingMethodId INT,
				@FlatRateId INT = 3;
		SELECT @POPart = ManagementStructureModuleId FROM ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'POHeader';

		SELECT @TotalRecord = COUNT(PO.PartNumber) FROM [DBO].[PurchaseOrderPart] PO WITH (NOLOCK)
		LEFT JOIN [DBO].[PurchaseOrderManagementStructureDetails] POMS WITH (NOLOCK) ON PO.PurchaseOrderPartRecordId = POMS.ReferenceID AND ModuleID = @POPart
		LEFT JOIN [DBO].[PurchaseOrderCharges] POC WITH (NOLOCK) ON PO.PurchaseOrderPartRecordId = POC.PurchaseOrderPartRecordId AND POC.IsDeleted =0
		WHERE PO.PurchaseOrderId = @PurchaseOrderId
		AND PO.IsDeleted =0 AND PO.isParent = 1;

		SELECT @CurrencyCode = CU.Code, 
			   @ChargesBilingMethodId = PO.ChargesBilingMethodId, 
			   @FreightBilingMethodId = PO.FreightBilingMethodId
			FROM [DBO].[purchaseorder] PO
			LEFT JOIN [DBO].[PurchaseOrderManagementStructureDetails] MS WITH (NOLOCK) ON PO.ManagementStructureId = MS.MSDetailsId
			LEFT JOIN [DBO].[ManagementStructurelevel] MS1 WITH (NOLOCK) ON MS.level1Id = MS1.id
			LEFT JOIN LegalEntity LE WITH (NOLOCK) ON MS1.LegalEntityId = LE.LegalEntityId
			LEFT JOIN Currency CU WITH (NOLOCK) ON LE.FunctionalCurrencyId = CU.CurrencyId
		WHERE PO.PurchaseOrderId = @PurchaseOrderId;
		
		IF OBJECT_ID(N'tempdb..#tmpPurchaseORderPartRecord') IS NOT NULL
		BEGIN
			DROP TABLE #tmpPurchaseORderPartRecord
		END
		
		CREATE TABLE #tmpPurchaseORderPartRecord
		(
			ID BIGINT NOT NULL IDENTITY, 
			row_num BIGINT NULL,
			PartNumber VARCHAR(500) NULL,
			AltEquiPartNumber VARCHAR(500) NULL,
			PartDescription VARCHAR(MAX) NULL,
			Manufacturer VARCHAR(500) NULL,
			GLAccount VARCHAR(200) NULL,
			UnitOfMeasure VARCHAR(200) NULL,
			NeedByDate DATETIME,
			Condition VARCHAR(200) NULL,
			QuantityOrdered INT NULL,
			UnitCost DECIMAL(18,2) NULL,
			VendorListPrice DECIMAL(18,2) NULL,
			[Priority] VARCHAR(200) NULL,
			DiscountAmount DECIMAL(18,2) NULL,
			DiscountPercent BIGINT NULL,
			DiscountPercentValue DECIMAL(18,2) NULL,
			DiscountPerUnit DECIMAL(18,2) NULL,
			ExtendedCost DECIMAL(18,2) NULL,
			Memo VARCHAR(MAX) NULL,
			LastMSLevel VARCHAR(200) NULL,
			AllMSlevels VARCHAR(200) NULL,
			BillingAmount DECIMAL(18,2) NULL,
			ChargeMethodId INT NULL,
			FreightBillingAmount DECIMAL(18,2) NULL,
			FreightMethodId INT NULL,
			NumOfRecord BIGINT NULL,
			CurrencyCode VARCHAR(100) NULL
		)
		
		--Insert Charges records
		INSERT INTO #tmpPurchaseORderPartRecord(
				row_num,
				PartNumber,
				AltEquiPartNumber,
				PartDescription,
				Manufacturer,
				GLAccount,
				UnitOfMeasure,
				NeedByDate,
				Condition,
				QuantityOrdered,
				UnitCost,
				VendorListPrice,
				[Priority],
				DiscountAmount,
				DiscountPercent,
				DiscountPercentValue,
				DiscountPerUnit,
				ExtendedCost,
				Memo,
				LastMSLevel,
				AllMSlevels,
				BillingAmount,
				ChargeMethodId,
				FreightBillingAmount,
				FreightMethodId,
				NumOfRecord,
				CurrencyCode)
		SELECT DISTINCT
			 ROW_NUMBER() OVER (
				ORDER BY PO.PurchaseOrderPartRecordId
			 ) row_num, 
			 PO.PartNumber,
			 PO.AltEquiPartNumber,
			 CASE
			   WHEN PO.[PartDescription] !='' 
			   THEN 
					CASE WHEN LEN(ISNULL(PO.[PartDescription],'')) < 70
						THEN ISNULL(PO.[PartDescription],'')
					ELSE
						LEFT(ISNULL(PO.[PartDescription],''),70) + '....'
					END
			   ELSE 
					''
			 END AS 'PartDescription',
			 PO.Manufacturer,
			 PO.GLAccount,
			 PO.UnitOfMeasure,
			 PO.NeedByDate,
			 PO.Condition,
			 PO.QuantityOrdered,
			 PO.UnitCost,
			 PO.VendorListPrice,
			 PO.Priority,
			 PO.DiscountAmount,
			 PO.DiscountPercent,
			 PO.DiscountPercentValue,
			 PO.DiscountPerUnit,
			 PO.ExtendedCost,
			 PO.Memo,
			 POMS.LastMSLevel,
			 POMS.AllMSlevels,
			 SUM(POC.BillingAmount) AS BillingAmount,
			 @ChargesBilingMethodId AS ChargeMethodId,
			 0 AS FreightBillingAmount,
			 @FreightBilingMethodId AS FreightMethodId,
			 @TotalRecord AS NumOfRecord,
			 @CurrencyCode AS CurrencyCode
		FROM [DBO].[PurchaseOrderPart] PO WITH (NOLOCK)
		LEFT JOIN [DBO].[PurchaseOrderManagementStructureDetails] POMS WITH (NOLOCK) ON PO.PurchaseOrderPartRecordId = POMS.ReferenceID AND ModuleID = @POPart
		LEFT JOIN [DBO].[PurchaseOrderCharges] POC WITH (NOLOCK) ON PO.PurchaseOrderPartRecordId = POC.PurchaseOrderPartRecordId AND POC.IsDeleted =0
		WHERE PO.PurchaseOrderId = @PurchaseOrderId
		AND PO.IsDeleted =0 AND PO.isParent = 1
		GROUP BY PO.PurchaseOrderPartRecordId,PO.PartNumber, PO.AltEquiPartNumber, PO.PartDescription, PO.Manufacturer, PO.GLAccount,PO.UnitOfMeasure, PO.NeedByDate,PO.Condition,
			 PO.QuantityOrdered, PO.UnitCost, PO.VendorListPrice,PO.Priority,PO.DiscountAmount,PO.DiscountPercent,PO.DiscountPercentValue,PO.DiscountPerUnit,
			 PO.ExtendedCost, PO.Memo, POMS.LastMSLevel,POMS.AllMSlevels;
		
		--Insert Freight records
		INSERT INTO #tmpPurchaseORderPartRecord(
				row_num,
				PartNumber,
				AltEquiPartNumber,
				PartDescription,
				Manufacturer,
				GLAccount,
				UnitOfMeasure,
				NeedByDate,
				Condition,
				QuantityOrdered,
				UnitCost,
				VendorListPrice,
				[Priority],
				DiscountAmount,
				DiscountPercent,
				DiscountPercentValue,
				DiscountPerUnit,
				ExtendedCost,
				Memo,
				LastMSLevel,
				AllMSlevels,
				BillingAmount,
				ChargeMethodId,
				FreightBillingAmount,
				FreightMethodId,
				NumOfRecord,
				CurrencyCode)
		SELECT DISTINCT
			 ROW_NUMBER() OVER (
				ORDER BY PO.PurchaseOrderPartRecordId
			 ) row_num, 
			 PO.PartNumber,
			 PO.AltEquiPartNumber,
			 CASE
			   WHEN PO.[PartDescription] !='' 
			   THEN 
					CASE WHEN LEN(ISNULL(PO.[PartDescription],'')) < 70
						THEN ISNULL(PO.[PartDescription],'')
					ELSE
						LEFT(ISNULL(PO.[PartDescription],''),70) + '....'
					END
			   ELSE 
					''
			 END AS 'PartDescription',
			 PO.Manufacturer,
			 PO.GLAccount,
			 PO.UnitOfMeasure,
			 PO.NeedByDate,
			 PO.Condition,
			 PO.QuantityOrdered,
			 PO.UnitCost,
			 PO.VendorListPrice,
			 PO.Priority,
			 PO.DiscountAmount,
			 PO.DiscountPercent,
			 PO.DiscountPercentValue,
			 PO.DiscountPerUnit,
			 PO.ExtendedCost,
			 PO.Memo,
			 POMS.LastMSLevel,
			 POMS.AllMSlevels,
			 0 AS BillingAmount,
			 @ChargesBilingMethodId AS ChargeMethodId,
			 SUM(POF.BillingAmount) AS FreightBillingAmount,
			 @FreightBilingMethodId AS FreightMethodId,
			 @TotalRecord AS NumOfRecord,
			 @CurrencyCode AS CurrencyCode
		FROM [DBO].[PurchaseOrderPart] PO WITH (NOLOCK)
		LEFT JOIN [DBO].[PurchaseOrderManagementStructureDetails] POMS WITH (NOLOCK) ON PO.PurchaseOrderPartRecordId = POMS.ReferenceID AND ModuleID = @POPart
		LEFT JOIN [DBO].[PurchaseOrderFreight] POF WITH (NOLOCK) ON PO.PurchaseOrderPartRecordId = POF.PurchaseOrderPartRecordId AND POF.IsDeleted =0
		WHERE PO.PurchaseOrderId = @PurchaseOrderId
		AND PO.IsDeleted =0 AND PO.isParent = 1
		GROUP BY PO.PurchaseOrderPartRecordId,PO.PartNumber, PO.AltEquiPartNumber, PO.PartDescription, PO.Manufacturer, PO.GLAccount,PO.UnitOfMeasure, PO.NeedByDate,PO.Condition,
			 PO.QuantityOrdered, PO.UnitCost, PO.VendorListPrice,PO.Priority,PO.DiscountAmount,PO.DiscountPercent,PO.DiscountPercentValue,PO.DiscountPerUnit,
			 PO.ExtendedCost, PO.Memo, POMS.LastMSLevel,POMS.AllMSlevels;

		SELECT 
			 PartNumber,
			 row_num, 
			 AltEquiPartNumber,
			 PartDescription,
			 Manufacturer,
			 GLAccount,
			 UnitOfMeasure,
			 NeedByDate,
			 Condition,
			 QuantityOrdered,
			 UnitCost,
			 VendorListPrice,
			 Priority,
			 DiscountAmount,
			 DiscountPercent,
			 DiscountPercentValue,
			 DiscountPerUnit,
			 ExtendedCost,
			 Memo,
			 LastMSLevel,
			 AllMSlevels,
			 SUM(BillingAmount) AS BillingAmount,
			 ChargeMethodId,
			 SUM(FreightBillingAmount) AS FreightBillingAmount,
			 FreightMethodId,
			 NumOfRecord,
			 CurrencyCode
		FROM #tmpPurchaseORderPartRecord
		GROUP BY PartNumber,
			row_num, 
			AltEquiPartNumber,
			PartDescription,
			Manufacturer,
			GLAccount,
			UnitOfMeasure,
			NeedByDate,
			Condition,
			QuantityOrdered,
			UnitCost,
			VendorListPrice,
			Priority,
			DiscountAmount,
			DiscountPercent,
			DiscountPercentValue,
			DiscountPerUnit,
			ExtendedCost,
			Memo,
			LastMSLevel,
			AllMSlevels,
			ChargeMethodId,
			FreightMethodId,
			NumOfRecord,
			CurrencyCode;
  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'RPT_PrintPurchasePartDataById' 
        ,@ProcedureParameters VARCHAR(3000) = '@PurchaseOrderId = ''' + CAST(ISNULL(@PurchaseOrderId, '') AS varchar(100))			   
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