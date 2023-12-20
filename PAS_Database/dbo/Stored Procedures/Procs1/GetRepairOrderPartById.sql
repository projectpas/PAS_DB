/*************************************************************           
 ** File:   [GetRepairOrderPartById]           
 ** Author:  Deep Patel
 ** Description: This stored procedure is used to Get Repair Order Part Details
 ** Purpose:         
 ** Date:11/10/2022
 ** PARAMETERS: @RepairOrderId bigint
 ** RETURN VALUE:
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    11/10/2022  Deep Patel     Created
-- EXEC GetRepairOrderPartById 303
************************************************************************/
CREATE   PROCEDURE [dbo].[GetRepairOrderPartById]
@RepairOrderId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY	

	DECLARE @STOCKTYPE INT,@NONSTOCKTYPE INT,@ASSETTYPE INT, @MasterCompanyId bigint;

	SELECT @STOCKTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Stock';
	SELECT @NONSTOCKTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Non-Stock';
	SELECT @ASSETTYPE = [ItemTypeId] FROM [dbo].[ItemType] WITH(NOLOCK) WHERE Name = 'Asset';	 

	SELECT @MasterCompanyId = [MasterCompanyId] FROM [dbo].[RepairOrder] WITH(NOLOCK) WHERE [RepairOrderId] = @RepairOrderId;


	SELECT pop.PartNumber,pop.ItemMasterId,pop.RepairOrderPartRecordId,pop.ManufacturerId,
	  pop.PartNumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK) 
	  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ imf.[Name] ELSE '' END) AS [Label],
	  imf.[Name] AS Manufacturer
	  
      FROM [dbo].[RepairOrderPart] pop WITH (NOLOCK) 		
	  LEFT JOIN [dbo].[ItemMaster] im  WITH (NOLOCK) ON pop.ItemMasterId = im.ItemMasterId 
	  LEFT JOIN [dbo].[Manufacturer] imf WITH (NOLOCK) ON im.ManufacturerId = imf.ManufacturerId	 
	  WHERE pop.RepairOrderId = @RepairOrderId and pop.isParent=1 AND pop.IsDeleted = 0 AND (pop.ItemTypeId = @STOCKTYPE OR pop.ItemTypeId = @NONSTOCKTYPE)

	  UNION

	SELECT pop.PartNumber,pop.ItemMasterId,pop.RepairOrderPartRecordId,pop.ManufacturerId,
	  pop.PartNumber AS [Label],Amf.[Name] AS Manufacturer
      FROM [dbo].[RepairOrderPart] pop WITH (NOLOCK) 		  
	  LEFT JOIN [dbo].[Asset] AST WITH (NOLOCK) ON pop.ItemMasterId = AST.AssetRecordId 
	  LEFT JOIN [dbo].[Manufacturer] Amf WITH (NOLOCK) ON AST.ManufacturerId = Amf.ManufacturerId
	  WHERE pop.[RepairOrderId] = @RepairOrderId AND pop.[isParent]=1 AND pop.[IsDeleted] = 0 AND pop.[ItemTypeId] = @ASSETTYPE

  END TRY    
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
        , @AdhocComments     VARCHAR(150)    = 'GetRepairOrderPartById' 
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@RepairOrderId, '') AS varchar(100))			   
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