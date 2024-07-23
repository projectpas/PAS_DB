/*************************************************************           
 ** File:   [GetVendorRFQROPartById]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to Get Repair Order Part Details
 ** Purpose:         
 ** Date:   15-07-2024     
          
 ** PARAMETERS: @CreditMemoHeaderId bigint
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15-07-20242  Abhishek Jirawla     Created
     
-- EXEC GetVendorRFQROPartById 104
************************************************************************/
CREATE   PROCEDURE [dbo].[GetVendorRFQROPartById]
@VendorRFQROId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	declare @STOCKTYPE INT,@NONSTOCKTYPE INT,@ASSETTYPE INT, @MasterCompanyId bigint;

	--SELECT @STOCKTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Stock';
	--SELECT @NONSTOCKTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Non-Stock';
	--SELECT @ASSETTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Asset';	 

	SELECT @MasterCompanyId = [MasterCompanyId] FROM [dbo].[VendorRFQRepairOrder] WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQROId;
	 
	SELECT pop.PartNumber,pop.ItemMasterId,pop.VendorRFQROPartRecordId,pop.ManufacturerId,
	  pop.PartNumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK) 
	  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ imf.[Name] ELSE '' END) AS [Label],
	  imf.[Name] AS Manufacturer
      FROM [dbo].[VendorRFQRepairOrderPart] pop WITH (NOLOCK) 	
	  LEFT JOIN [dbo].[ItemMaster] im  WITH (NOLOCK)ON   pop.ItemMasterId = im.ItemMasterId 
	  LEFT JOIN [dbo].[Manufacturer] imf WITH (NOLOCK) ON im.ManufacturerId = imf.ManufacturerId	 
	  WHERE pop.VendorRFQRepairOrderId = @VendorRFQROId  AND pop.IsDeleted = 0

	

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetVendorRFQROPartById' 
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