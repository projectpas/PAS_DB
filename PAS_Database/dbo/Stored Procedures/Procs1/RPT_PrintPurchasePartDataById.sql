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
     
-- EXEC RPT_PrintPurchasePartDataById 823
************************************************************************/
CREATE      PROCEDURE [dbo].[RPT_PrintPurchasePartDataById]
@PurchaseOrderId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
		
		DECLARE @PurchaseOrderPartRecordId BIGINT,@POPart BIGINT,@TotalRecord BIGINT,@CurrencyCode VARCHAR(50);
		SELECT @POPart = ManagementStructureModuleId FROM ManagementStructureModule WITH (NOLOCK) WHERE ModuleName = 'POHeader';

		SELECT @TotalRecord = COUNT(PO.PartNumber) FROM [DBO].[PurchaseOrderPart] PO WITH (NOLOCK)
		LEFT JOIN [DBO].[PurchaseOrderManagementStructureDetails] POMS WITH (NOLOCK) ON PO.PurchaseOrderPartRecordId = POMS.ReferenceID AND ModuleID = @POPart
		LEFT JOIN [DBO].[PurchaseOrderCharges] POC WITH (NOLOCK) ON PO.PurchaseOrderPartRecordId = POC.PurchaseOrderPartRecordId AND POC.IsDeleted =0
		WHERE PO.PurchaseOrderId = @PurchaseOrderId
		AND PO.IsDeleted =0 AND PO.isParent = 1;

		SELECT @CurrencyCode = CU.Code
			FROM [DBO].[purchaseorder] PO
			LEFT JOIN [DBO].[PurchaseOrderManagementStructureDetails] MS WITH (NOLOCK) ON PO.ManagementStructureId = MS.MSDetailsId
			LEFT JOIN [DBO].[ManagementStructurelevel] MS1 WITH (NOLOCK) ON MS.level1Id = MS1.id
			LEFT JOIN LegalEntity LE WITH (NOLOCK) ON MS1.LegalEntityId = LE.LegalEntityId
			LEFT JOIN Currency CU WITH (NOLOCK) ON LE.FunctionalCurrencyId = CU.CurrencyId
		WHERE PO.PurchaseOrderId = @PurchaseOrderId;

		SELECT 
			 ROW_NUMBER() OVER (
				ORDER BY PO.PurchaseOrderPartRecordId
			 ) row_num, 
			 PO.PartNumber,
			 PO.AltEquiPartNumber,
			 --PO.PartDescription,
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