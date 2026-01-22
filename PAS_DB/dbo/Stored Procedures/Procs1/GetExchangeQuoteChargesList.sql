/*************************************************************           
 ** File:   [GetExchangeQuoteChargesList]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to Get Exchange Sales Order Charges List Details
 ** Purpose:         
 ** Date:   09-04-2024
 ** PARAMETERS: @ExchangeQuoteId bigint
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09-04-2024  Abhishek Jirawla     Created

-- EXEC GetExchangeQuoteChargesList 8,0
************************************************************************/
CREATE   PROCEDURE [dbo].[GetExchangeQuoteChargesList]
@ExchangeQuoteId BIGINT,
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
	   RO.[ExchangeQuoteChargesId]
      ,RO.[ExchangeQuoteId]
      --,RO.[ExchangeQuotePartRecordId]
      ,RO.[ChargesTypeId]
      ,RO.[VendorId]
      ,RO.[Quantity]
      ,RO.[MarkupPercentageId]
      ,RO.[Description]
      ,RO.[UnitCost]
      ,RO.[ExtendedCost]
      ,RO.[MasterCompanyId]
      ,RO.[MarkupFixedPrice]
      ,RO.[BillingMethodId]
      ,RO.[BillingAmount]
      ,RO.[BillingRate]
      ,RO.[HeaderMarkupId]
      ,RO.[RefNum]
      ,RO.[CreatedBy]
      ,RO.[UpdatedBy]
      ,RO.[CreatedDate]
      ,RO.[UpdatedDate]
      ,RO.[IsActive]
      ,RO.[IsDeleted]
      ,RO.[HeaderMarkupPercentageId]
      ,RO.[VendorName]
      ,RO.[ChargeName]
      ,RO.[MarkupName]
   --   ,RO.[ItemMasterId]
   --   ,RO.[ConditionId]
	  --,RO.[PartNumber]
	  --,RO.[LineNum]
	  ,CASE WHEN RO.[BillingMethodId] = 1 THEN 'T&M' ELSE 'Actual' END AS 'BillingMethodName'
	  --,RO.[ManufacturerId]
	  --,RO.[Manufacturer]		
	  ,uom.[ShortName] AS UOM	
	  ,RO.[UOMId] 		
      FROM [dbo].[ExchangeQuoteCharges] RO WITH (NOLOCK) 
		LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) on RO.UOMId = uom.UnitOfMeasureId
	  WHERE RO.ExchangeQuoteId=@ExchangeQuoteId AND RO.IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT 
	   ROA.[ExchangeQuoteChargesId]
      ,ROA.[ExchangeQuoteId]
      --,ROA.[ExchangeQuotePartRecordId]
      ,ROA.[ChargesTypeId]
      ,ROA.[VendorId]
      ,ROA.[Quantity]
      ,ROA.[MarkupPercentageId]
      ,ROA.[Description]
      ,ROA.[UnitCost]
      ,ROA.[ExtendedCost]
      ,ROA.[MasterCompanyId]
      ,ROA.[MarkupFixedPrice]
      ,ROA.[BillingMethodId]
      ,ROA.[BillingAmount]
      ,ROA.[BillingRate]
      ,ROA.[HeaderMarkupId]
      ,ROA.[RefNum]
      ,ROA.[CreatedBy]
      ,ROA.[UpdatedBy]
      ,ROA.[CreatedDate]
      ,ROA.[UpdatedDate]
      ,ROA.[IsActive]
      ,ROA.[IsDeleted]
      ,ROA.[HeaderMarkupPercentageId]
      ,ROA.[VendorName]
      ,ROA.[ChargeName]
      ,ROA.[MarkupName]
   --   ,ROA.[ItemMasterId]
   --   ,ROA.[ConditionId]
	  --,ROA.[PartNumber]
	  --,ROA.[LineNum]
	  ,CASE WHEN ROA.BillingMethodId = 1 THEN 'T&M' ELSE 'Actual' END AS 'BillingMethodName'
	  --,ROA.[ManufacturerId]
	  --,ROA.[Manufacturer]
	  ,ROA.[UOMId]
	  ,UOM.[ShortName] AS UOM
      FROM [dbo].[ExchangeQuoteChargesAudit] ROA WITH (NOLOCK) 
		LEFT JOIN dbo.UnitOfMeasure UOM WITH(NOLOCK) on ROA.UOMId = UOM.UnitOfMeasureId
	  WHERE ExchangeQuoteChargesId=@ExchangeQuoteId and ChargeName is not null;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetExchangeQuoteChargesList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ExchangeQuoteId, '') AS varchar(100))			   
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