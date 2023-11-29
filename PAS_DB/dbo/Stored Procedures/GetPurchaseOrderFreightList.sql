/*************************************************************           
 ** File:   [GetPurchaseOrderFreightList]           
 ** Author: Subhash Saliya
 ** Description: This stored procedure is used to Get Purchase Order Freight List Details
 ** Purpose:         
 ** Date:   04/07/2022      
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/07/2022  subhash saliya     Created
     
-- EXEC GetPurchaseOrderFreightList 8,0
************************************************************************/
CREATE   PROCEDURE [dbo].[GetPurchaseOrderFreightList]
@PurchaseOrderId bigint,
@IsDeleted bit,
@Opr int
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	
	IF(@Opr=1)
	BEGIN
	SELECT [PurchaseOrderFreightId]
          ,PurchaseOrderId
          ,PurchaseOrderPartRecordId
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
      FROM [dbo].PurchaseOrderFreight WITH (NOLOCK) WHERE PurchaseOrderId=@PurchaseOrderId AND IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT [PurchaseOrderFreightId]
          ,PurchaseOrderId
          ,PurchaseOrderPartRecordId
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
      FROM [dbo].[PurchaseOrderFreightAudit] WITH (NOLOCK) WHERE [PurchaseOrderFreightId]=@PurchaseOrderId;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetPurchaseOrderFreightList' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PurchaseOrderId, '') AS varchar(100))			   
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