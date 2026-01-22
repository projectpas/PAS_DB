/*************************************************************           
 ** File:   [GetVendorRFQPOPartById]           
 ** Author:  SHREY CHANDEGARA
 ** Description: This stored procedure is used to Get Purchase Order Part Details
 ** Purpose:         
 ** Date:   05-07-2024     
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05-07-20242  SHREY CHANDEGARA     Created
     
-- EXEC GetVendorRFQPOPartById 104
************************************************************************/
CREATE     PROCEDURE [dbo].[GetVendorRFQPOPartById]
@VendorRFQPOId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	declare @STOCKTYPE INT,@NONSTOCKTYPE INT,@ASSETTYPE INT, @MasterCompanyId bigint;

	--SELECT @STOCKTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Stock';
	--SELECT @NONSTOCKTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Non-Stock';
	--SELECT @ASSETTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Asset';	 

	SELECT @MasterCompanyId = [MasterCompanyId] FROM [dbo].[VendorRFQPurchaseOrder] WITH(NOLOCK) WHERE [VendorRFQPurchaseOrderId] = @VendorRFQPOId;
	 
	SELECT pop.PartNumber,pop.ItemMasterId,pop.VendorRFQPOPartRecordId,pop.ManufacturerId,
	  pop.PartNumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK) 
	  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ imf.[Name] ELSE '' END) AS [Label],
	  imf.[Name] AS Manufacturer
      FROM [dbo].[VendorRFQPurchaseOrderPart] pop WITH (NOLOCK) 	
	  LEFT JOIN [dbo].[ItemMaster] im  WITH (NOLOCK)ON   pop.ItemMasterId = im.ItemMasterId 
	  LEFT JOIN [dbo].[Manufacturer] imf WITH (NOLOCK) ON im.ManufacturerId = imf.ManufacturerId	 
	  WHERE pop.VendorRFQPurchaseOrderId = @VendorRFQPOId  AND pop.IsDeleted = 0

	

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetVendorRFQPOPartById' 
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