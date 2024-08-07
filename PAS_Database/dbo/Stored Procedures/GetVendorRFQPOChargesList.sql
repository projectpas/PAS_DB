/*************************************************************           
 ** File:   [GetVendorRFQPOChargesList]           
 ** Author:  Shrey Chandegara
 ** Description: This stored procedure is used to Get VendorRFQPOCharges List Details
 ** Purpose:         
 ** Date:   16-07-2024      
          
 ** PARAMETERS: @VendorRFQPOId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    16-07-2024  Shrey Chandegara     Created
-- EXEC GetVendorRFQPOChargesList 8,0,2
************************************************************************/

CREATE   PROCEDURE [dbo].[GetVendorRFQPOChargesList]
@VendorRFQPOId BIGINT,
@IsDeleted bit,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
	IF(@Opr=1)
	BEGIN
	SELECT 
	   PO.[VendorRFQPOChargeId]
      ,PO.[VendorRFQPurchaseOrderId]
      ,PO.[VendorRFQPOPartRecordId]
      ,PO.[ChargesTypeId]
      ,PO.[VendorId]
      ,PO.[Quantity]
      ,PO.[MarkupPercentageId]
      ,PO.[Description]
      ,PO.[UnitCost]
      ,PO.[ExtendedCost]
      ,PO.[MasterCompanyId]
      ,PO.[MarkupFixedPrice]
      ,PO.[BillingMethodId]
      ,PO.[BillingAmount]
      ,PO.[BillingRate]
      ,PO.[HeaderMarkupId]
      ,PO.[RefNum]
      ,PO.[CreatedBy]
      ,PO.[UpdatedBy]
      ,PO.[CreatedDate]
      ,PO.[UpdatedDate]
      ,PO.[IsActive]
      ,PO.[IsDeleted]
      ,PO.[HeaderMarkupPercentageId]
      ,PO.[VendorName]
      ,PO.[ChargeName]
      ,PO.[MarkupName]
      ,PO.[ItemMasterId]
      ,PO.[ConditionId]
	  ,PO.[PartNumber]
	  ,PO.[LineNum]
	  ,PO.[ManufacturerId]
	  ,PO.[Manufacturer]
	  ,PO.[UOMId]
	  ,uom.[ShortName] AS UOM
      FROM [dbo].[VendorRFQPOCharges] PO WITH (NOLOCK)
	  LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) on PO.UOMId = uom.UnitOfMeasureId
	  WHERE PO.VendorRFQPurchaseOrderId=@VendorRFQPOId AND PO.IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT 
	   POA.[VendorRFQPOChargeId]
      ,POA.[VendorRFQPurchaseOrderId]
      ,POA.[VendorRFQPOPartRecordId]
      ,POA.[ChargesTypeId]
      ,POA.[VendorId]
      ,POA.[Quantity]
      ,POA.[MarkupPercentageId]
      ,POA.[Description]
      ,POA.[UnitCost]
      ,POA.[ExtendedCost]
      ,POA.[MasterCompanyId]
      ,POA.[MarkupFixedPrice]
      ,POA.[BillingMethodId]
      ,POA.[BillingAmount]
      ,POA.[BillingRate]
      ,POA.[HeaderMarkupId]
      ,POA.[RefNum]
      ,POA.[CreatedBy]
      ,POA.[UpdatedBy]
      ,POA.[CreatedDate]
      ,POA.[UpdatedDate]
      ,POA.[IsActive]
      ,POA.[IsDeleted]
      ,POA.[HeaderMarkupPercentageId]
      ,POA.[VendorName]
      ,POA.[ChargeName]
      ,POA.[MarkupName]
      ,POA.[ItemMasterId]
      ,POA.[ConditionId]
	  ,POA.[PartNumber]
	  ,POA.[LineNum]
	  ,POA.[ManufacturerId]
	  ,POA.[Manufacturer]
	  ,POA.[UOMId]
	  ,uom.[ShortName] AS UOM
      FROM [dbo].[VendorRFQPOChargesAudit] POA WITH (NOLOCK)
	  LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) on POA.UOMId = uom.UnitOfMeasureId
	  WHERE VendorRFQPOChargeId=@VendorRFQPOId ORDER BY VendorRFQPOChargesAuditId DESC;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetVendorRFQPOChargesList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@VendorRFQPOId, '') AS varchar(100))			   
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