/*************************************************************           
 ** File:   [GetVendorRFQPOFreightList]           
 ** Author: Shrey Chandegara
 ** Description: This stored procedure is used to Get Vendor RFQ Purchase Order Freight List Details
 ** Purpose:         
 ** Date:   04/07/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/07/2024  Shrey Chandegara     Created
     
-- EXEC GetVendorRFQPOFreightList 8,0
************************************************************************/
CREATE     PROCEDURE [dbo].[GetVendorRFQPOFreightList]
@VendorRFQPOId bigint,
@IsDeleted bit,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
	IF(@Opr=1)
	BEGIN
	SELECT [VendorRFQPOFreightId]
          ,VendorRFQPurchaseOrderId
          ,VendorRFQPOPartRecordId
          ,[ItemMasterId]
          ,[PartNumber]
          ,[ShipViaId]
          ,[ShipViaName]
          ,[MarkupPercentageId]
          ,[MarkupFixedPrice]
          ,[HeaderMarkupId]
          ,[BillingMethodId]
          ,[BillingRate]
          ,[BillingAmount]
          ,[HeaderMarkupPercentageId]
          ,[Weight]
          ,[UOMId]
          ,[UOMName]
          ,[Length]
          ,[Width]
          ,[Height]
          ,[DimensionUOMId]
          ,[DimensionUOMName]
          ,[CurrencyId]
          ,[CurrencyName]
          ,[Amount]
          ,[Memo]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[UpdatedBy]
          ,[CreatedDate]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
		  ,[LineNum]
		  ,[ManufacturerId]
		  ,[Manufacturer]
      FROM [dbo].[VendorRFQPOFreight] WITH (NOLOCK) WHERE VendorRFQPurchaseOrderId=@VendorRFQPOId AND IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT [VendorRFQPOFreightId]
          ,VendorRFQPurchaseOrderId
          ,VendorRFQPOPartRecordId
          ,[ItemMasterId]
          ,[PartNumber]
          ,[ShipViaId]
          ,[ShipViaName]
          ,[MarkupPercentageId]
          ,[MarkupFixedPrice]
          ,[HeaderMarkupId]
          ,[BillingMethodId]
          ,[BillingRate]
          ,[BillingAmount]
          ,[HeaderMarkupPercentageId]
          ,[Weight]
          ,[UOMId]
          ,[UOMName]
          ,[Length]
          ,[Width]
          ,[Height]
          ,[DimensionUOMId]
          ,[DimensionUOMName]
          ,[CurrencyId]
          ,[CurrencyName]
          ,[Amount]
          ,[Memo]
          ,[MasterCompanyId]
          ,[CreatedBy]
          ,[UpdatedBy]
          ,[CreatedDate]
          ,[UpdatedDate]
          ,[IsActive]
          ,[IsDeleted]
		  ,[LineNum]
		  ,[ManufacturerId]
		  ,[Manufacturer]
      FROM [dbo].[VendorRFQPOFreightAudit] WITH (NOLOCK) WHERE [VendorRFQPOFreightId]=@VendorRFQPOId ORDER BY VendorRFQPOFreightAuditId DESC;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetVendorRFQPOFreightList' 
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