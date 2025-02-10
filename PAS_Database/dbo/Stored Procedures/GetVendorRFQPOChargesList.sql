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
	2    10-02-2025  Sahdev Saliya        Added a case to get timeZone

-- EXEC GetVendorRFQPOChargesList 8,0,2
************************************************************************/

CREATE   PROCEDURE [dbo].[GetVendorRFQPOChargesList]
@VendorRFQPOId BIGINT,
@IsDeleted bit,
@Opr int,
@EmployeeId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
	SELECT 
			@CurrntEmpTimeZoneDesc = COALESCE(
				ETZ.[Description],  -- Prefer Employee's TimeZone description if available
				LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
			)
		FROM 
			dbo.Employee E WITH (NOLOCK) 
		LEFT JOIN 
			dbo.TimeZone ETZ WITH (NOLOCK) 
			ON E.TimeZoneId = ETZ.TimeZoneId
		LEFT JOIN 
			dbo.LegalEntity LE WITH (NOLOCK) 
			ON E.LegalEntityId = LE.LegalEntityId
		LEFT JOIN 
			dbo.TimeZone LTZ WITH (NOLOCK) 
			ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE 
			E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee
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
	  ,case when CAST(PO.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(PO.[CreatedDate], @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate
	  ,case when CAST(PO.[UpdatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(PO.[UpdatedDate], @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate
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
	  ,case when CAST(POA.[CreatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(POA.[CreatedDate], @CurrntEmpTimeZoneDesc) as datetime))end CreatedDate
	  ,case when CAST(POA.[UpdatedDate] as date) = CAST('0001-01-01 00:00:00' as date)then null else (Cast(DBO.ConvertUTCtoLocal(POA.[UpdatedDate], @CurrntEmpTimeZoneDesc) as datetime))end UpdatedDate
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