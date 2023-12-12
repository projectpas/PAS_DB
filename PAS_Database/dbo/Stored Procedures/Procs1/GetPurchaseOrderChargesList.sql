/*************************************************************           
 ** File:   [GetPurchaseOrderChargesList]           
 ** Author:  Subhash Saliya
 ** Description: This stored procedure is used to Get Purchase Order Charges List Details
 ** Purpose:         
 ** Date:   17/05/2022      
          
 ** PARAMETERS: @PurchaseOrderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    17/05/2022  Subhash Saliya     Created
     
-- EXEC GetPurchaseOrderChargesList 8,0
************************************************************************/

CREATE   PROCEDURE [dbo].[GetPurchaseOrderChargesList]
@PurchaseOrderId BIGINT,
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
	   [PurchaseOrderChargestId]
      ,[PurchaseOrderId]
      ,[PurchaseOrderPartRecordId]
      ,[ChargesTypeId]
      ,[VendorId]
      ,[Quantity]
      ,[MarkupPercentageId]
      ,[Description]
      ,[UnitCost]
      ,[ExtendedCost]
      ,[MasterCompanyId]
      ,[MarkupFixedPrice]
      ,[BillingMethodId]
      ,[BillingAmount]
      ,[BillingRate]
      ,[HeaderMarkupId]
      ,[RefNum]
      ,[CreatedBy]
      ,[UpdatedBy]
      ,[CreatedDate]
      ,[UpdatedDate]
      ,[IsActive]
      ,[IsDeleted]
      ,[HeaderMarkupPercentageId]
      ,[VendorName]
      ,[ChargeName]
      ,[MarkupName]
      ,[ItemMasterId]
      ,[ConditionId]
	  ,[PartNumber]
	  ,[LineNum]
	  ,[ManufacturerId]
	  ,[Manufacturer]
      FROM [dbo].[PurchaseOrderCharges] WITH (NOLOCK) WHERE PurchaseOrderId=@PurchaseOrderId AND IsDeleted=@IsDeleted;
	END
	BEGIN
	SELECT 
	   [PurchaseOrderChargestId]
      ,[PurchaseOrderId]
      ,[PurchaseOrderPartRecordId]
      ,[ChargesTypeId]
      ,[VendorId]
      ,[Quantity]
      ,[MarkupPercentageId]
      ,[Description]
      ,[UnitCost]
      ,[ExtendedCost]
      ,[MasterCompanyId]
      ,[MarkupFixedPrice]
      ,[BillingMethodId]
      ,[BillingAmount]
      ,[BillingRate]
      ,[HeaderMarkupId]
      ,[RefNum]
      ,[CreatedBy]
      ,[UpdatedBy]
      ,[CreatedDate]
      ,[UpdatedDate]
      ,[IsActive]
      ,[IsDeleted]
      ,[HeaderMarkupPercentageId]
      ,[VendorName]
      ,[ChargeName]
      ,[MarkupName]
      ,[ItemMasterId]
      ,[ConditionId]
	  ,[PartNumber]
	  ,[LineNum]
	  ,[ManufacturerId]
	  ,[Manufacturer]
      FROM [dbo].[PurchaseOrderChargesAudit] WITH (NOLOCK) WHERE PurchaseOrderChargestId=@PurchaseOrderId;
	END
	END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetPurchaseOrderChargesList' 
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