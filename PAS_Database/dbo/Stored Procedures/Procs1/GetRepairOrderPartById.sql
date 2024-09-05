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
	2	 09/05/2024  Abhishek Jirawla Combine queries by removing union and returning 1 result set with proper order as needed.
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

	SELECT 
	pop.PartNumber,
	pop.ItemMasterId,
	pop.RepairOrderPartRecordId,
	pop.ManufacturerId,
	CASE 
		WHEN pop.ItemTypeId IN (@STOCKTYPE, @NONSTOCKTYPE) THEN
			pop.PartNumber + 
			(CASE 
				WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) 
						FROM [dbo].[ItemMaster] SD WITH(NOLOCK) 
						WHERE im.PartNumber = SD.PartNumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 
				THEN ' - ' + imf.[Name] 
				ELSE '' 
				END)
		WHEN pop.ItemTypeId = @ASSETTYPE THEN 
			pop.PartNumber
	END AS [Label],
	-- Choose Manufacturer name based on ItemTypeId
	CASE 
		WHEN pop.ItemTypeId IN (@STOCKTYPE, @NONSTOCKTYPE) THEN imf.[Name]
		WHEN pop.ItemTypeId = @ASSETTYPE THEN Amf.[Name]
	END AS Manufacturer
	FROM [dbo].[RepairOrderPart] pop WITH (NOLOCK) 
	-- Join conditionally based on ItemTypeId
		LEFT JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON pop.ItemMasterId = im.ItemMasterId AND pop.ItemTypeId IN (@STOCKTYPE, @NONSTOCKTYPE)
		LEFT JOIN [dbo].[Manufacturer] imf WITH (NOLOCK) ON im.ManufacturerId = imf.ManufacturerId AND pop.ItemTypeId IN (@STOCKTYPE, @NONSTOCKTYPE)
		LEFT JOIN [dbo].[Asset] AST WITH (NOLOCK) ON pop.ItemMasterId = AST.AssetRecordId AND pop.ItemTypeId = @ASSETTYPE
		LEFT JOIN [dbo].[Manufacturer] Amf WITH (NOLOCK) ON AST.ManufacturerId = Amf.ManufacturerId AND pop.ItemTypeId = @ASSETTYPE
	WHERE pop.RepairOrderId = @RepairOrderId 
		AND pop.isParent = 1 
		AND pop.IsDeleted = 0
		AND (pop.ItemTypeId IN (@STOCKTYPE, @NONSTOCKTYPE, @ASSETTYPE));

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