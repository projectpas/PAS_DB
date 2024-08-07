/*************************************************************           
 ** File:   [GetVendorRFQROFreightList]           
 ** Author: Abhishek Jirawla
 ** Description: This stored procedure is used to Get Vendor RFQ Reapir Order Freight List Details
 ** Purpose:         
 ** Date:   15/07/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/07/2024  Abhishek Jirawla     Created
	2    07/08/2024  Shrey Chandegara Updated for change history order.
     
-- EXEC GetVendorRFQROFreightList 8,0
************************************************************************/
CREATE     PROCEDURE [dbo].[GetVendorRFQROFreightList]
@VendorRFQROId bigint,
@IsDeleted bit,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
	IF(@Opr=1)
	BEGIN
	SELECT [VendorRFQROFreightId]
          ,VendorRFQRepairOrderId
          ,VendorRFQROPartRecordId
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
      FROM [dbo].[VendorRFQROFreight] WITH (NOLOCK) WHERE VendorRFQRepairOrderId=@VendorRFQROId AND IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT [VendorRFQROFreightId]
          ,VendorRFQRepairOrderId
          ,VendorRFQROPartRecordId
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
      FROM [dbo].[VendorRFQROFreightAudit] WITH (NOLOCK) WHERE [VendorRFQROFreightId]=@VendorRFQROId ORDER BY VendorRFQROFreightAuditId DESC;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetVendorRFQROFreightList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@VendorRFQROId, '') AS varchar(100))			   
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